const http = require('http');
const testLogin = () => new Promise((resolve, reject) => {
  const data = JSON.stringify({ correo: 'admin@bitsac.local', password: '0910000001' });
  const req = http.request({ hostname:'localhost', port:3000, path:'/api/auth/login', method:'POST', headers:{'Content-Type':'application/json','Content-Length':data.length} }, res => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => resolve(JSON.parse(body)));
  });
  req.on('error', reject);
  req.write(data);
  req.end();
});
const doGet = (token, path) => new Promise((resolve, reject) => {
  const req = http.request({ hostname:'localhost', port:3000, path, method:'GET', headers:{'Authorization':'Bearer '+token} }, res => {
    let body = '';
    res.on('data', c => body += c);
    res.on('end', () => resolve({status: res.statusCode, data: JSON.parse(body)}));
  });
  req.on('error', reject);
  req.end();
});

testLogin().then(r => {
  if (!r.ok) { console.log('Login failed:', r.mensaje); return; }
  const token = r.token;
  console.log('Login OK');
  return doGet(token, '/api/admin/eas').then(r2 => {
    console.log('GET /api/admin/eas:', r2.status, r2.data.ok ? 'OK ('+r2.data.datos.length+' rows)' : 'FAIL: '+r2.data.mensaje);
    return doGet(token, '/api/admin/lugares-servicio');
  }).then(r3 => {
    console.log('GET /api/admin/lugares-servicio:', r3.status, r3.data.ok ? 'OK ('+r3.data.datos.length+' rows)' : 'FAIL: '+r3.data.mensaje);
    return doGet(token, '/api/admin/movil-eas-asignaciones');
  }).then(r4 => {
    console.log('GET /api/admin/movil-eas-asignaciones:', r4.status, r4.data.ok ? 'OK ('+r4.data.datos.length+' rows)' : 'FAIL: '+r4.data.mensaje);
  });
}).catch(e => console.log('ERR:', e.message));
