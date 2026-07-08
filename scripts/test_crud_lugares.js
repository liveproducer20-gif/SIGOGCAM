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
  return req('POST', '/api/admin/lugares-servicio', token, {
    rutaId: 1,
    direccion: 'Boyaca y 9 de Octubre',
    distritoId: 1,
    horaEntrada: '07:00',
    horaSalida: '19:00',
    consignas: 'Punto de control principal'
  }).then(r2 => {
    console.log('CREATE:', r2.status, JSON.stringify(r2.data));
    const id = r2.data.lugarId;
    return req('GET', '/api/admin/lugares-servicio', token).then(r3 => {
      console.log('LIST:', r3.status, JSON.stringify(r3.data));
      if (id) return req('DELETE', '/api/admin/lugares-servicio/'+id, token);
    });
  }).then(r4 => {
    if (r4) console.log('DELETE:', r4.status, JSON.stringify(r4.data));
  });
}).catch(e => console.log('ERR:', e.message));
