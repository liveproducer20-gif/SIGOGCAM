const path = require('path');
const backendNodeModules = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(backendNodeModules, 'odbc'));
require(path.join(backendNodeModules, 'dotenv')).config({ path: path.join(__dirname, '..', 'backend', '.env') });

const {
  DB_DRIVER = 'ODBC Driver 18 for SQL Server',
  DB_SERVER,
  DB_DATABASE,
  DB_USER,
  DB_PASSWORD,
  DB_TRUSTED_CONNECTION = 'Yes',
  DB_TRUST_SERVER_CERTIFICATE = 'Yes',
  DB_ENCRYPT = 'no',
  DB_CONNECTION_TIMEOUT = '15',
} = process.env;

const connectionString =
  `Driver={${DB_DRIVER}};` +
  `Server=${DB_SERVER};` +
  `Database=${DB_DATABASE};` +
  `Encrypt=${DB_ENCRYPT};` +
  `TrustServerCertificate=${DB_TRUST_SERVER_CERTIFICATE};` +
  `Connection Timeout=${DB_CONNECTION_TIMEOUT};` +
  (DB_USER
    ? `UID=${DB_USER};PWD=${DB_PASSWORD || ''};`
    : `Trusted_Connection=${DB_TRUSTED_CONNECTION};`);

const queries = [
  { name: 'Catalogos', sql: `SELECT COUNT(*) AS total FROM dbo.catalogos` },
  { name: 'Catalogo Detalles', sql: `SELECT COUNT(*) AS total FROM dbo.catalogo_detalles` },
  { name: 'Roles', sql: `SELECT COUNT(*) AS total FROM dbo.roles` },
  { name: 'Permisos', sql: `SELECT COUNT(*) AS total FROM dbo.permisos` },
  { name: 'Lugares Servicio', sql: `SELECT COUNT(*) AS total FROM dbo.lugares_servicio` },
  { name: 'EAS Estaciones', sql: `SELECT COUNT(*) AS total FROM dbo.eas_estaciones` },
  { name: 'Moviles', sql: `SELECT COUNT(*) AS total FROM dbo.moviles` },
  { name: 'Asignaciones', sql: `SELECT COUNT(*) AS total FROM dbo.movil_eas_asignaciones` },
  { name: 'vw_personal_detalle', sql: `SELECT COUNT(*) AS total FROM dbo.vw_personal_detalle` },
  { name: 'vw_moviles_mantenimiento', sql: `SELECT COUNT(*) AS total FROM dbo.vw_moviles_mantenimiento` },
  { name: 'Personal (query completa)', sql: `
    SELECT vd.id, vd.cedula, vd.nombres, vd.apellidos,
           vd.nombre_completo, vd.correo_institucional, vd.telefono,
           vd.fecha_nacimiento, vd.fecha_ingreso,
           vd.rol, vd.estado_personal, vd.activo,
           p.cargo_id, p.grado_id, p.area_id,
           p.funcion_operativa_id, p.jornada_id, p.grupo_id,
           p.tipo_rotacion_id, p.rol_id, p.estado_personal_id
    FROM vw_personal_detalle vd
    INNER JOIN dbo.personal p ON p.id = vd.id
    ORDER BY vd.apellidos, vd.nombres
  ` },
  { name: 'Roles (con FOR XML)', sql: `
    SELECT r.id, r.nombre, r.descripcion, r.activo,
           STUFF((
               SELECT ',' + p.codigo
               FROM dbo.rol_permiso rp
               INNER JOIN dbo.permisos p ON p.id = rp.permiso_id
               WHERE rp.rol_id = r.id
               ORDER BY p.codigo
               FOR XML PATH(''), TYPE
           ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS permisos
    FROM dbo.roles r
    ORDER BY r.nombre
  ` },
];

async function main() {
  let connection;
  try {
    connection = await odbc.connect(connectionString);
    console.log('Conectado a', DB_SERVER, DB_DATABASE);
    console.log();

    for (const q of queries) {
      process.stdout.write(`  ${q.name.padEnd(35)} `);
      try {
        const result = await connection.query(q.sql);
        const total = Array.isArray(result) ? result.length : 0;
        const count = result[0]?.total ?? total;
        console.log(`OK (${count} filas)`);
      } catch (error) {
        console.log(`FALLO: ${error.message}`);
      }
    }
  } catch (error) {
    console.error(`\nERROR DE CONEXION: ${error.message}`);
    process.exitCode = 1;
  } finally {
    if (connection) await connection.close();
  }
}

main();
