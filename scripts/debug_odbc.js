const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  // Get the ID of the test record
  c.query("SELECT TOP 1 id FROM dbo.lugares_servicio WHERE direccion='Test Dir'").then(r => {
    if (r.length === 0) { console.log('No test record found'); return c.close(); }
    const id = r[0].id;
    console.log('Found test record id='+id);
    // Test 1: select without consignas and time
    return c.query("SELECT id, ruta_id, direccion, distrito_id, activo FROM dbo.lugares_servicio WHERE id="+id).then(r2 => {
      console.log('Test1 (basic):', r2.length, 'rows');
      // Test 2: add consignas
      return c.query("SELECT id, consignas FROM dbo.lugares_servicio WHERE id="+id);
    }).then(r3 => {
      console.log('Test2 (consignas):', r3.length, 'rows', JSON.stringify(r3[0]));
      // Test 3: add hora_entrada
      return c.query("SELECT id, hora_entrada FROM dbo.lugares_servicio WHERE id="+id);
    }).then(r4 => {
      console.log('Test3 (hora_entrada):', r4.length, 'rows', JSON.stringify(r4[0]));
      // Test 4: add hora_salida
      return c.query("SELECT id, hora_salida FROM dbo.lugares_servicio WHERE id="+id);
    }).then(r5 => {
      console.log('Test4 (hora_salida):', r5.length, 'rows', JSON.stringify(r5[0]));
      // Test 5: JOIN with catalogo_detalles
      return c.query("SELECT l.id, ruta.nombre AS ruta, distrito.nombre AS distrito FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id);
    }).then(r6 => {
      console.log('Test5 (JOIN):', r6.length, 'rows', JSON.stringify(r6[0]));
      // Test 6: full query
      return c.query("SELECT l.id, l.ruta_id, ruta.nombre AS ruta, l.direccion, l.distrito_id, distrito.nombre AS distrito, l.hora_entrada, l.hora_salida, l.consignas, l.activo FROM dbo.lugares_servicio l INNER JOIN dbo.catalogo_detalles ruta ON ruta.id = l.ruta_id INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id WHERE l.id="+id);
    }).then(r7 => {
      console.log('Test6 (full):', r7.length, 'rows', JSON.stringify(r7[0]));
      // Cleanup
      return c.query("DELETE FROM dbo.lugares_servicio WHERE id="+id);
    }).then(() => {
      console.log('CLEANUP OK');
      return c.close();
    }).catch(e => { console.log('ERROR:', e.message); });
  }).catch(e => { console.log('QUERY ERR:', e.message); c.close(); });
}).catch(e => { console.log('CONN ERROR:', e.message); });
