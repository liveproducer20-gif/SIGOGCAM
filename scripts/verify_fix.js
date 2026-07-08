const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  // Schema check
  c.query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='eas_estaciones' AND TABLE_SCHEMA='dbo' ORDER BY ORDINAL_POSITION").then(r => {
    console.log('EAS columns:', r.map(x=>x.COLUMN_NAME).join(', '));
    return c.query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='lugares_servicio' AND TABLE_SCHEMA='dbo' ORDER BY ORDINAL_POSITION");
  }).then(r => {
    console.log('LUG columns:', r.map(x=>x.COLUMN_NAME).join(', '));
    // Test listarEas
    return c.query("SELECT e.id, e.codigo, e.nombre, e.direccion, e.distrito_id, d.nombre AS distrito, e.activo FROM dbo.eas_estaciones e LEFT JOIN dbo.catalogo_detalles d ON d.id = e.distrito_id ORDER BY e.codigo");
  }).then(r => {
    console.log('listarEas: OK, '+r.length+' rows');
    // Test listarLugares
    return c.query("SELECT l.id, l.nombre, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.subunidad_operativa_id, subunidad.nombre AS subunidad_operativa, l.tipo_servicio_id, tipo.nombre AS tipo_servicio, l.observacion, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id LEFT JOIN dbo.catalogo_detalles subunidad ON subunidad.id = l.subunidad_operativa_id INNER JOIN dbo.catalogo_detalles tipo ON tipo.id = l.tipo_servicio_id ORDER BY distrito.nombre, l.nombre");
  }).then(r => {
    console.log('listarLugares: OK, '+r.length+' rows');
    // Test listarAsignaciones
    return c.query("SELECT a.id, a.eas_id, e.codigo AS eas_codigo, e.nombre AS eas, a.movil_id, m.numero_movil, m.placa, a.fecha_asignacion, a.estado_asignacion_id, estado.nombre AS estado, a.observacion, a.activo FROM dbo.movil_eas_asignaciones a INNER JOIN dbo.eas_estaciones e ON e.id = a.eas_id INNER JOIN dbo.moviles m ON m.id = a.movil_id INNER JOIN dbo.catalogo_detalles estado ON estado.id = a.estado_asignacion_id ORDER BY a.fecha_asignacion DESC, a.id DESC");
  }).then(r => {
    console.log('listarAsignaciones: OK, '+r.length+' rows');
    // Test crearEas
    return c.query("INSERT INTO dbo.eas_estaciones (codigo, nombre, direccion, distrito_id) OUTPUT INSERTED.id VALUES ('T99','EAS Test','Dir Test',NULL)");
  }).then(r => {
    console.log('crearEas: OK id='+r[0].id);
    return c.query("DELETE FROM dbo.eas_estaciones WHERE codigo='T99'");
  }).then(() => {
    console.log('crearEas cleanup OK');
    // Test crearLugar
    return c.query("INSERT INTO dbo.lugares_servicio (nombre, direccion, distrito_id, tipo_servicio_id) OUTPUT INSERTED.id VALUES ('Lugar Test','Dir Test',1,1)");
  }).then(r => {
    console.log('crearLugar: OK id='+r[0].id);
    return c.query("DELETE FROM dbo.lugares_servicio WHERE id="+r[0].id);
  }).then(() => {
    console.log('crearLugar cleanup OK');
    return c.close();
  }).catch(e => { console.log('ERROR: '+e.message); c.close(); });
}).catch(e => { console.log('CONN ERROR: '+e.message); });
