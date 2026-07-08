const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  // Get correct IDs
  const rutaId = 0, distritoId = 0;
  c.query("SELECT TOP 1 id FROM dbo.catalogo_detalles WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo='RUTAS') ORDER BY id").then(rid => {
    return c.query("SELECT TOP 1 id FROM dbo.catalogo_detalles WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo='DISTRITOS') ORDER BY id").then(did => {
      return [rid[0].id, did[0].id];
    });
  }).then(ids => {
    const [rutaId, distritoId] = ids;
    console.log('Using rutaId='+rutaId+' distritoId='+distritoId);
    return c.query("INSERT INTO dbo.lugares_servicio (ruta_id, direccion, distrito_id, hora_entrada, hora_salida, consignas) OUTPUT INSERTED.id VALUES ("+rutaId+", 'Test Dir', "+distritoId+", '07:00', '19:00', 'Test')");
  }).then(r2 => {
    const id = r2[0].id;
    console.log('Inserted id='+id);
    return c.query("SELECT l.id, l.ruta_id, ruta.nombre AS ruta, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.hora_entrada, l.hora_salida, l.consignas, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id);
  }).then(r => {
    console.log('FULL QUERY OK, rows='+r.length);
    console.log('Row:', JSON.stringify(r[0]));
    return c.query("DELETE FROM dbo.lugares_servicio WHERE id="+r[0].id);
  }).then(() => {
    console.log('CLEANUP OK');
    return c.close();
  }).catch(e => { console.log('ERROR:', e.message); try { c.close(); } catch(_){} });
}).catch(e => { console.log('CONN ERROR:', e.message); });
