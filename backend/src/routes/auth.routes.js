const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();

const controller = require('../controllers/auth.controller');
const { requireAuth } = require('../middleware/auth.middleware');

const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 10,
    message: { ok: false, mensaje: 'Demasiados intentos de inicio de sesión. Intente nuevamente en 15 minutos.' },
    standardHeaders: true,
    legacyHeaders: false,
});

const refreshLimiter = rateLimit({
    windowMs: 60 * 60 * 1000,
    max: 30,
    message: { ok: false, mensaje: 'Demasiadas solicitudes de renovación. Intente nuevamente en 1 hora.' },
    standardHeaders: true,
    legacyHeaders: false,
});

router.get('/registro', (req, res) => {
    res.json({ ok: true, mensaje: 'Ruta de registro activa. Use POST para crear usuario.' });
});

router.post('/login', loginLimiter, controller.login);
router.post('/refresh', refreshLimiter, requireAuth, controller.refresh);
module.exports = router;
