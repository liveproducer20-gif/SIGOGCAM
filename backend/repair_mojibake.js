/*
 * Script de reparacion de mojibake (doble codificacion UTF-8 en Latin1)
 * en la base de datos BITSAC.
 *
 * Problema: los seeds se ejecutaron con sqlcmd sin codificacion UTF-16,
 * por lo que los acentos se grabaron como la secuencia de bytes UTF-8
 * interpretada como caracteres Latin1 (ej. 'ó' -> 'Ã³').
 *
 * Solucion: leer cada columna NVARCHAR, tomar los code points (que son los
 * bytes 0-255 originales) y re-decodificarlos como UTF-8.
 *
 * Ejecutar: node reparar_mojibake.js   (desde la carpeta backend)
 */
const sql = require('msnodesqlv8');
require('dotenv').config();

const cs =
  `Driver={${process.env.DB_DRIVER || 'ODBC Driver 18 for SQL Server'}};` +
  `Server=${process.env.DB_SERVER};Database=${process.env.DB_DATABASE};` +
  `Trusted_Connection=Yes;Encrypt=no;TrustServerCertificate=Yes;`;

// Decodifica mojibake: UTF-8 guardado como Latin1 (cada byte como un char 0-255).
// Solo actua si TODOS los code points estan en 0-255 (caso tipico de mojibake).
function fixMojibake(str) {
  if (typeof str !== 'string' || str.length === 0) return str;
  let allByteRange = true;
  for (const ch of str) {
    if (ch.codePointAt(0) > 255) { allByteRange = false; break; }
  }
  if (!allByteRange) return str;
  const bytes = Buffer.alloc(str.length);
  for (let i = 0; i < str.length; i++) bytes[i] = str.charCodeAt(i) & 0xff;
  const decoded = bytes.toString('utf8');
  // No aplicar si no cambia o si la decodificacion introduce reemplazo.
  if (decoded === str) return str;
  if (decoded.includes('�')) return str;
  return decoded;
}

function getColumns(conn, cb) {
  const q = `
    SELECT TABLE_NAME, COLUMN_NAME
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE DATA_TYPE IN ('nvarchar','nchar','ntext') AND TABLE_SCHEMA='dbo'
    ORDER BY TABLE_NAME, ORDINAL_POSITION`;
  conn.query(q, (e, rows) => cb(e, rows || []));
}

sql.open(cs, (err, conn) => {
  if (err) { console.error('OPEN ERR', err.message); process.exit(1); }
  getColumns(conn, (e, columns) => {
    if (e) { console.error('COLS ERR', e.message); process.exit(1); }
    console.log(`Columnas a revisar: ${columns.length}`);
    let ci = 0, totalCambios = 0;

    const nextCol = () => {
      if (ci >= columns.length) {
        console.log(`\nReparacion completada. Total de valores corregidos: ${totalCambios}`);
        conn.close(() => process.exit(0));
        return;
      }
      const { TABLE_NAME, COLUMN_NAME } = columns[ci++];
      const tbl = `[${TABLE_NAME}]`;
      const col = `[${COLUMN_NAME}]`;
      const pk = primaryKeyOf(TABLE_NAME);
      if (!pk) { nextCol(); return; }
      const pkCol = `[${pk}]`;
      conn.query(`SELECT ${pkCol}, ${col} FROM ${tbl}`, (e2, rows) => {
        if (e2) {
          console.error(`ERR leyendo ${TABLE_NAME}.${COLUMN_NAME}:`, e2.message);
          nextCol(); return;
        }
        const pend = [];
        for (const r of rows) {
          const orig = r[COLUMN_NAME];
          const fixed = fixMojibake(orig);
          if (fixed !== orig) pend.push({ id: r[pk], val: fixed });
        }
        let pi = 0;
        const nextUpd = () => {
          if (pi >= pend.length) { nextCol(); return; }
          const p = pend[pi++];
          conn.query(
            `UPDATE ${tbl} SET ${col} = ? WHERE ${pkCol} = ?`,
            [p.val, p.id],
            (e3) => {
              if (e3) { console.error(`ERR update ${TABLE_NAME}:`, e3.message); nextCol(); return; }
              totalCambios++; nextUpd();
            }
          );
        };
        if (pend.length) {
          console.log(`  ${TABLE_NAME}.${COLUMN_NAME}: ${pend.length} corregido(s)`);
        }
        nextUpd();
      });
    };

    // Mapeo simple de PK por tabla (asume id o nombre segun corresponda).
    // Para tablas sin 'id', se usa la columna unica conocida.
    nextCol();
  });
});

// Determina la columna PK/clave a usar para el UPDATE.
function primaryKeyOf(table) {
  const map = {
    catalogos: 'id', 'catalogo_detalles': 'id', roles: 'id', permisos: 'id',
    personal: 'id', eventos: 'id', anuncios: 'id', auditoria: 'id',
    insignias: 'id', 'cartillas_generadas': 'id', 'usuario_insignias': 'id',
    'lugares_servicio': 'id', 'eas_estaciones': 'id', moviles: 'id',
    'movil_eas_asignaciones': 'id', 'movil_mantenimiento': 'id',
    'eas_direcciones': 'id', 'servidores_policiales': 'id',
    'cartilla_temp_cp': 'id', 'cartilla_temp_policia': 'id',
    grados: 'id', rutas: 'id', 'eas_roles_central': 'id',
    'configuracion_institucional': 'clave', 'configuracion_motor': 'clave',
    'plantillas_rotacion': 'id', 'plantilla_rotacion_detalle': 'id',
    'puestos_servicio': 'id', 'anuncio_personal': 'id', 'evento_personal': 'id',
  };
  return map[table] || 'id';
}
