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
  const token = r.token;
  return doGet(token, '/api/admin/lugares-servicio').then(r2 => {
    console.log('Status:', r2.status);
    console.log('Response:', JSON.stringify(r2.data, null, 2));
  });
}).catch(e => console.log('ERR:', e.message));
