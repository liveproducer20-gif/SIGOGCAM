const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  console.log('Testing listarLugares query...');
  c.query("SELECT l.id, l.ruta_id, ruta.nombre AS ruta, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.hora_entrada, l.hora_salida, l.consignas, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id ORDER BY ruta.nombre, l.direccion").then(r => {
    console.log('OK, rows='+r.length);
    console.log('First row:', JSON.stringify(r[0]));
    return c.close();
  }).catch(e => { console.log('QUERY ERROR:', e.message); try { c.close(); } catch(_){} });
}).catch(e => { console.log('CONN ERROR:', e.message); });
