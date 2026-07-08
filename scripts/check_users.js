const path = require('path');
const nm = path.join(__dirname, '..', 'backend', 'node_modules');
const odbc = require(path.join(nm, 'odbc'));
require(path.join(nm, 'dotenv')).config({path: path.join(__dirname, '..', 'backend', '.env')});
const cs = 'Driver={'+process.env.DB_DRIVER+'};Server='+process.env.DB_SERVER+';Database='+process.env.DB_DATABASE+';Encrypt=no;TrustServerCertificate=Yes;Connection Timeout=10;Trusted_Connection=Yes;';
odbc.connect(cs).then(c => {
  c.query("SELECT TOP 5 id, cedula, correo_institucional, nombres, apellidos FROM dbo.personal WHERE activo=1").then(r => {
    console.log('Users:');
    r.forEach(u => console.log('  '+u.cedula+' | '+u.correo_institucional+' | '+u.nombres+' '+u.apellidos));
    return c.close();
  }).catch(e => { console.log('ERR: '+e.message); c.close(); });
}).catch(e => { console.log('CONN ERR: '+e.message); });
