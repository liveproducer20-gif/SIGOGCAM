const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { getPool } = require('./src/config/db');
const authRoutes = require('./src/routes/auth.routes');
const personalRoutes = require('./src/routes/personal.routes');
const eventosRoutes = require('./src/routes/eventos.routes');
const anunciosRoutes = require('./src/routes/anuncios.routes');
const catalogosRoutes = require('./src/routes/catalogos.routes');
const adminRoutes = require('./src/routes/admin.routes');
const cartillasRoutes = require('./src/routes/cartillas.routes');
const insigniasRoutes = require('./src/routes/insignias.routes');
const usuariosInsigniasRoutes = require('./src/routes/usuarios-insignias.routes');

const app = express();

app.use(cors());
app.use(express.json({ limit: process.env.JSON_LIMIT || '25mb' }));
app.use(express.urlencoded({ extended: true, limit: process.env.JSON_LIMIT || '25mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/catalogos', catalogosRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/personal', personalRoutes);
app.use('/api/eventos', eventosRoutes);
app.use('/api/anuncios', anunciosRoutes);
app.use('/api/cartillas', cartillasRoutes);
app.use('/api/insignias', insigniasRoutes);
app.use('/api/usuarios', usuariosInsigniasRoutes);

app.get('/api', (req, res) => {
  res.json({
    ok: true,
    mensaje: 'API BITSAC funcionando correctamente',
    rutas: [
      '/api/auth',
      '/api/catalogos',
      '/api/admin',
      '/api/personal',
      '/api/eventos',
      '/api/anuncios',
      '/api/cartillas',
      '/api/insignias',
      '/api/probar-db'
    ]
  });
});

app.get('/', (req, res) => {
  res.send('API BITSAC funcionando correctamente');
});

async function probarDb(req, res) {
  try {
    const pool = await getPool();
    const connection = await pool.connect();
    const result = await connection.query('SELECT DB_NAME() AS baseDatos');
    await connection.close();

    res.json({
      ok: true,
      mensaje: 'Conexión correcta con SQL Server',
      baseDatos: result[0].baseDatos
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      mensaje: 'Error al conectar con SQL Server',
      error: error.message,
      detalle: error.odbcErrors || error
    });
  }
}

app.get('/api/probar-db', probarDb);

app.use((req, res) => {
  res.status(404).json({
    ok: false,
    mensaje: `Ruta no encontrada: ${req.method} ${req.originalUrl}`
  });
});

app.use((error, req, res, next) => {
  if (error?.type === 'entity.too.large') {
    return res.status(413).json({
      ok: false,
      mensaje: 'El archivo o imagen supera el tamaño permitido por la API.'
    });
  }

  if (error instanceof SyntaxError && 'body' in error) {
    return res.status(400).json({
      ok: false,
      mensaje: 'El cuerpo enviado no es un JSON válido.'
    });
  }

  return res.status(500).json({
    ok: false,
    mensaje: error?.message || 'Error interno del servidor'
  });
});

const PORT = process.env.PORT || 3000;

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 16) {
  console.error('ERROR: JWT_SECRET no configurado o muy corto. Defina una clave segura en .env');
  process.exit(1);
}

app.listen(PORT, () => {
  console.log(`Servidor BITSAC corriendo en puerto ${PORT}`);
});
