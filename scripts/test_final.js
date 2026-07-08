const http = require('http');
const api = (method, path, token, body) => new Promise((resolve, reject) => {
  const data = body ? JSON.stringify(body) : '';
  const opts = { hostname:'localhost', port:3000, path, method,
    headers:{'Content-Type':'application/json'} };
  if (token) opts.headers['Authorization'] = 'Bearer '+token;
  if (data) opts.headers['Content-Length'] = data.length;
  const r = http.request(opts, res => { let x=''; res.on('data',c=>x+=c); res.on('end',()=>resolve({status:res.statusCode, data:JSON.parse(x)})); });
  r.on('error', reject);
  if (data) r.write(data);
  r.end();
});

(async () => {
  const login = await api('POST', '/api/auth/login', null, {correo:'admin@bitsac.local', password:'0910000001'});
  if (!login.data.ok) { console.log('Login failed'); return; }
  const token = login.data.token;

  const rutas = await api('GET', '/api/admin/catalogos/RUTAS?incluirInactivos=1', token);
  const distritos = await api('GET', '/api/admin/catalogos/DISTRITOS?incluirInactivos=1', token);
  if (!rutas.data.ok || !distritos.data.ok) { console.log('Catalog fetch failed'); return; }
  const rutaId = rutas.data.datos[0].id;
  const distritoId = distritos.data.datos[0].id;
  console.log('rutaId='+rutaId+' distritoId='+distritoId);

  const create = await api('POST', '/api/admin/lugares-servicio', token, {
    rutaId, direccion: 'Boyaca y 9 de Octubre', distritoId,
    horaEntrada: '07:00', horaSalida: '19:00',
    consignas: 'Punto de control principal'
  });
  console.log('CREATE:', create.status, JSON.stringify(create.data));
  const id = create.data.lugarId;

  const list = await api('GET', '/api/admin/lugares-servicio', token);
  console.log('LIST:', list.status, list.data.ok ? 'OK rows='+list.data.datos.length : 'FAIL');
  if (list.data.ok && list.data.datos.length > 0)
    console.log('  First:', JSON.stringify(list.data.datos[0]));

  if (id) {
    const del = await api('DELETE', '/api/admin/lugares-servicio/'+id, token);
    console.log('DELETE:', del.status, del.data.ok ? 'OK' : del.data.mensaje);
  }
})();
