const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';

async function test() {
  const c = await odbc.connect(cs);
  const rid = (await c.query("SELECT TOP 1 id FROM dbo.catalogo_detalles WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo='RUTAS') ORDER BY id"))[0].id;
  const did = (await c.query("SELECT TOP 1 id FROM dbo.catalogo_detalles WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo='DISTRITOS') ORDER BY id"))[0].id;
  const ins = await c.query("INSERT INTO dbo.lugares_servicio (ruta_id, direccion, distrito_id, hora_entrada, hora_salida, consignas) OUTPUT INSERTED.id VALUES ("+rid+", 'Test Dir', "+did+", '07:00', '19:00', 'Test')");
  const id = ins[0].id;

  // Test13 variations - find which column causes the JOIN issue
  const tests = [
    "SELECT l.id, l.ruta_id, ruta.nombre AS ruta, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.hora_entrada, l.hora_salida, l.consignas, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id,
    "SELECT l.id, l.ruta_id, l.direccion, l.distrito_id, l.hora_entrada, l.hora_salida, l.consignas, l.activo FROM dbo.lugares_servicio l WHERE l.id="+id,
    "SELECT l.id, ruta.nombre AS ruta, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id WHERE l.id="+id,
    "SELECT l.id, distrito.nombre AS distrito, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id,
    "SELECT l.id, ruta.nombre AS ruta, distrito.nombre AS distrito, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id,
    "SELECT l.id, l.ruta_id, l.distrito_id, l.activo FROM dbo.lugares_servicio l WHERE l.id="+id,
    "SELECT l.id, ruta.nombre AS ruta, l.ruta_id, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id WHERE l.id="+id,
    "SELECT l.id, ruta.nombre AS ruta, l.direccion, distrito.nombre AS distrito, l.hora_entrada, l.hora_salida, l.consignas FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id,
  ];
  for (let i = 0; i < tests.length; i++) {
    try {
      const r = await c.query(tests[i]);
      console.log('Test'+(i+1)+' OK: '+JSON.stringify(r[0]));
    } catch(e) {
      console.log('Test'+(i+1)+' ERR: '+e.message);
    }
  }

  await c.query("DELETE FROM dbo.lugares_servicio WHERE id="+id);
  await c.close();
}
test().catch(e => { console.log('FATAL:', e.message); });
