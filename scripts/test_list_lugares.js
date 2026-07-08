const http = require('http');
function req(method, path, token, body) {
  return new Promise((resolve, reject) => {
    const data = body ? JSON.stringify(body) : '';
    const opts = { hostname:'localhost', port:3000, path, method,
      headers: { 'Content-Type':'application/json' } };
    if (token) opts.headers['Authorization'] = 'Bearer '+token;
    if (data) opts.headers['Content-Length'] = data.length;
    const r = http.request(opts, res => {
      let b = '';
      res.on('data', c => b += c);
      res.on('end', () => resolve({status:res.statusCode, data:JSON.parse(b)}));
    });
    r.on('error', reject);
    if (data) r.write(data);
    r.end();
  });
}
req('POST', '/api/auth/login', null, {correo:'admin@bitsac.local', password:'0910000001'}).then(r => {
  const token = r.data.token;
  return req('GET', '/api/admin/lugares-servicio', token).then(r2 => {
    console.log('LIST (before):', r2.status, JSON.stringify(r2.data));
  });
}).catch(e => console.log('ERR:', e.message));
