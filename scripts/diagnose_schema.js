const path = require('path');
const backendNodeModules = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(backendNodeModules, 'odbc'));
require(path.join(backendNodeModules, 'dotenv')).config({ path: path.join(__dirname, '..', 'backend', '.env') });

const { DB_DRIVER, DB_SERVER, DB_DATABASE, DB_USER, DB_PASSWORD, DB_TRUSTED_CONNECTION, DB_TRUST_SERVER_CERTIFICATE, DB_ENCRYPT, DB_CONNECTION_TIMEOUT } = process.env;

const connectionString =
  'Driver={' + DB_DRIVER + '};Server=' + DB_SERVER + ';Database=' + DB_DATABASE + ';' +
  'Encrypt=' + DB_ENCRYPT + ';TrustServerCertificate=' + DB_TRUST_SERVER_CERTIFICATE + ';' +
  'Connection Timeout=' + DB_CONNECTION_TIMEOUT + ';' +
  (DB_USER ? 'UID=' + DB_USER + ';PWD=' + (DB_PASSWORD || '') + ';' : 'Trusted_Connection=' + DB_TRUSTED_CONNECTION + ';');

async function query(conn, sql) {
  try { return await conn.query(sql); }
  catch (e) { return 'ERROR: ' + e.message; }
}

async function main() {
  const conn = await odbc.connect(connectionString);

  console.log('=== EAS_ESTACIONES SCHEMA ===');
  let cols = await conn.query("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'eas_estaciones' AND TABLE_SCHEMA = 'dbo' ORDER BY ORDINAL_POSITION");
  cols.forEach(function(c) { console.log('  ' + c.COLUMN_NAME + '  ' + c.DATA_TYPE + '  NULL?' + c.IS_NULLABLE + '  default=' + (c.COLUMN_DEFAULT || '(none)')); });

  console.log('');
  console.log('=== LUGARES_SERVICIO SCHEMA ===');
  cols = await conn.query("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'lugares_servicio' AND TABLE_SCHEMA = 'dbo' ORDER BY ORDINAL_POSITION");
  cols.forEach(function(c) { console.log('  ' + c.COLUMN_NAME + '  ' + c.DATA_TYPE + '  NULL?' + c.IS_NULLABLE + '  default=' + (c.COLUMN_DEFAULT || '(none)')); });

  console.log('');
  console.log('=== MOVIL_EAS_ASIGNACIONES SCHEMA ===');
  cols = await conn.query("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'movil_eas_asignaciones' AND TABLE_SCHEMA = 'dbo' ORDER BY ORDINAL_POSITION");
  cols.forEach(function(c) { console.log('  ' + c.COLUMN_NAME + '  ' + c.DATA_TYPE + '  NULL?' + c.IS_NULLABLE + '  default=' + (c.COLUMN_DEFAULT || '(none)')); });

  console.log('');
  console.log('=== MOVILES SCHEMA ===');
  cols = await conn.query("SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'moviles' AND TABLE_SCHEMA = 'dbo' ORDER BY ORDINAL_POSITION");
  cols.forEach(function(c) { console.log('  ' + c.COLUMN_NAME + '  ' + c.DATA_TYPE + '  NULL?' + c.IS_NULLABLE + '  default=' + (c.COLUMN_DEFAULT || '(none)')); });

  console.log('');
  console.log('=== TEST: INSERT EAS (simulando crearEas) ===');
  var r = await conn.query("INSERT INTO dbo.eas_estaciones (codigo, nombre, direccion, distrito_id) OUTPUT INSERTED.id VALUES ('TEST99', 'EAS Test', 'Dir Test', NULL)");
  console.log('  Insert OK, id=' + r[0].id);
  await conn.query("DELETE FROM dbo.eas_estaciones WHERE codigo = 'TEST99'");
  console.log('  (cleanup done)');

  console.log('');
  console.log('=== TEST: INSERT LUGAR (simulando crearLugar) ===');
  r = await conn.query("INSERT INTO dbo.lugares_servicio (nombre, direccion, distrito_id, tipo_servicio_id) OUTPUT INSERTED.id VALUES ('Lugar Test', 'Dir Test', 1, 1)");
  console.log('  Insert OK, id=' + r[0].id);
  await conn.query("DELETE FROM dbo.lugares_servicio WHERE nombre = 'Lugar Test'");
  console.log('  (cleanup done)');

  console.log('');
  console.log('=== TEST: INSERT ASIGNACION (simulando crearAsignacion) ===');
  r = await conn.query("INSERT INTO dbo.movil_eas_asignaciones (eas_id, movil_id, fecha_asignacion, estado_asignacion_id, activo) OUTPUT INSERTED.id VALUES (1, 1, '2026-07-08', 1, 1)");
  console.log('  Insert OK, id=' + r[0].id);
  await conn.query('DELETE FROM dbo.movil_eas_asignaciones WHERE id = ' + r[0].id);
  console.log('  (cleanup done)');

  console.log('');
  console.log('=== TEST: LISTAR EAS ===');
  r = await conn.query("SELECT e.id, e.codigo, e.nombre, e.direccion, e.distrito_id, d.nombre AS distrito, e.activo FROM dbo.eas_estaciones e LEFT JOIN dbo.catalogo_detalles d ON d.id = e.distrito_id ORDER BY e.codigo, e.nombre");
  console.log('  OK, rows=' + r.length);

  console.log('');
  console.log('=== TEST: LISTAR LUGARES ===');
  r = await conn.query("SELECT l.id, l.nombre, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.subunidad_operativa_id, subunidad.nombre AS subunidad_operativa, l.tipo_servicio_id, tipo.nombre AS tipo_servicio, l.observacion, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id LEFT JOIN dbo.catalogo_detalles subunidad ON subunidad.id = l.subunidad_operativa_id INNER JOIN dbo.catalogo_detalles tipo ON tipo.id = l.tipo_servicio_id ORDER BY distrito.nombre, l.nombre");
  console.log('  OK, rows=' + r.length);

  console.log('');
  console.log('=== TEST: LISTAR ASIGNACIONES ===');
  r = await conn.query("SELECT a.id, a.eas_id, e.codigo AS eas_codigo, e.nombre AS eas, a.movil_id, m.numero_movil, m.placa, a.fecha_asignacion, a.estado_asignacion_id, estado.nombre AS estado, a.observacion, a.activo FROM dbo.movil_eas_asignaciones a INNER JOIN dbo.eas_estaciones e ON e.id = a.eas_id INNER JOIN dbo.moviles m ON m.id = a.movil_id INNER JOIN dbo.catalogo_detalles estado ON estado.id = a.estado_asignacion_id ORDER BY a.fecha_asignacion DESC, a.id DESC");
  console.log('  OK, rows=' + r.length);

  console.log('');
  console.log('=== TEST: LISTAR MOVILES ===');
  r = await conn.query("SELECT m.id, m.numero_movil, m.placa, m.tipo_movil_id, tipo.nombre AS tipo, m.kilometraje_actual, m.kilometraje_ultimo_mantenimiento, m.proximo_mantenimiento, (m.proximo_mantenimiento - m.kilometraje_actual) AS kilometros_restantes, m.estado_movil_id, estado.nombre AS estado FROM dbo.moviles m INNER JOIN dbo.catalogo_detalles tipo ON tipo.id = m.tipo_movil_id INNER JOIN dbo.catalogo_detalles estado ON estado.id = m.estado_movil_id ORDER BY m.numero_movil");
  console.log('  OK, rows=' + r.length);

  await conn.close();
}

main().catch(function(e) { console.error(e.message); process.exit(1); });
