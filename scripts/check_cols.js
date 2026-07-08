const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  c.query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='eas_estaciones' AND TABLE_SCHEMA='dbo' ORDER BY ORDINAL_POSITION").then(r => {
    console.log('EAS:', r.map(x=>x.COLUMN_NAME).join(', '));
    return c.query("SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='lugares_servicio' AND TABLE_SCHEMA='dbo' ORDER BY ORDINAL_POSITION");
  }).then(r => {
    console.log('LUG:', r.map(x=>x.COLUMN_NAME).join(', '));
    return c.query("INSERT INTO dbo.eas_estaciones (codigo, nombre, ubicacion, direccion) OUTPUT INSERTED.id VALUES ('T99','T99','T99','T99')");
  }).then(r => {
    console.log('INSERT EAS OK id='+r[0].id);
    return c.query("DELETE FROM dbo.eas_estaciones WHERE codigo='T99'");
  }).then(() => {
    console.log('CLEANUP OK');
    return c.close();
  }).catch(e => { console.log('ERROR: '+e.message); c.close(); });
}).catch(e => { console.log('CONN ERROR: '+e.message); });
