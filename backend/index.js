const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { getPool } = require('./src/config/db');
const { errorHandler, notFoundHandler } = require('./src/middleware/error.middleware');

const authRoutes = require('./src/routes/auth.routes');
const personalRoutes = require('./src/routes/personal.routes');
const eventosRoutes = require('./src/routes/eventos.routes');
const anunciosRoutes = require('./src/routes/anuncios.routes');
const catalogosRoutes = require('./src/routes/catalogos.routes');
const adminRoutes = require('./src/routes/admin.routes');
const cartillasRoutes = require('./src/routes/cartillas.routes');
const cartillaFlowRoutes = require('./src/routes/cartilla-flow.routes');
const insigniasRoutes = require('./src/routes/insignias.routes');
const usuariosInsigniasRoutes = require('./src/routes/usuarios-insignias.routes');
const soporteRoutes = require('./src/routes/soporte.routes');
const configuracionRoutes = require('./src/routes/configuracion.routes');
const soporteRepository = require('./src/repositories/soporte.repository');
const anunciosImages = require('./src/services/anuncios-images.service');
const eventosMedia = require('./src/services/eventos-media.service');

const app = express();

app.use(cors({
    origin: true,
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['Authorization'],
}));
app.use('/uploads', express.static(require('path').resolve(__dirname, 'uploads'), {
    fallthrough: false,
    maxAge: '30d',
    immutable: true
}));

app.use((req, res, next) => {
    res.set('Content-Type', 'application/json; charset=utf-8');
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    next();
});

app.use(express.json({ limit: process.env.JSON_LIMIT || '25mb' }));
app.use(express.urlencoded({ extended: true, limit: process.env.JSON_LIMIT || '25mb' }));

app.use('/api/auth', authRoutes);
app.use('/api/catalogos', catalogosRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/personal', personalRoutes);
app.use('/api/eventos', eventosRoutes);
app.use('/api/anuncios', anunciosRoutes);
app.use('/api/cartillas', cartillasRoutes);
app.use('/api/cartillas', cartillaFlowRoutes);
app.use('/api/insignias', insigniasRoutes);
app.use('/api/usuarios', usuariosInsigniasRoutes);
app.use('/api/soporte', soporteRoutes);
app.use('/api/configuracion', configuracionRoutes);

app.get('/api', (req, res) => {
    res.json({
        ok: true,
        mensaje: 'API BITSAC funcionando correctamente',
        rutas: [
            '/api/auth', '/api/catalogos', '/api/admin',
            '/api/personal', '/api/eventos', '/api/anuncios',
            '/api/cartillas', '/api/insignias', '/api/soporte', '/api/probar-db'
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
        res.json({ ok: true, mensaje: 'Conexión correcta con SQL Server', baseDatos: result[0].baseDatos });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al conectar con SQL Server', error: error.message });
    }
}

app.get('/api/probar-db', probarDb);

app.use(notFoundHandler);
app.use(errorHandler);

const PORT = process.env.PORT || 3000;

if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 16) {
    console.error('ERROR: JWT_SECRET no configurado o muy corto. Defina una clave segura en .env');
    process.exit(1);
}

app.listen(PORT, () => {
    console.log(`Servidor BITSAC corriendo en puerto ${PORT}`);
    soporteRepository.ensureSchema()
        .then(() => console.log('Esquema de Alertas / Soporte verificado'))
        .catch((error) => console.error('No se pudo preparar el esquema de soporte:', error.message));
    eventosMedia.migrateInlineMedia()
        .then(({ migrated, failures }) => {
            if (migrated > 0) console.log(`Archivos de eventos migrados: ${migrated}`);
            if (failures.length > 0) console.error('Archivos de eventos no migrados:', failures);
        })
        .catch((error) => console.error('No se pudieron migrar los archivos de eventos:', error.message));
    anunciosImages.migrateInlineImages()
        .then(({ migrated, failures }) => {
            if (migrated > 0) console.log(`Imágenes de anuncios migradas a archivos: ${migrated}`);
            if (failures.length > 0) console.error('Imágenes de anuncios no migradas:', failures);
        })
        .catch((error) => console.error('No se pudieron migrar las imágenes de anuncios:', error.message));
});
