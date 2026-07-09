const service = require('../services/auth.service');

async function login(req, res) {
    try {
        const { correo, password } = req.body;
        const result = await service.login(correo, password);
        res.json({
            ok: true,
            mensaje: 'Inicio de sesión correcto',
            usuario: result.usuario,
            token: result.token
        });
    } catch (error) {
        const statusCode = error.statusCode || 500;
        const body = { ok: false, mensaje: error.message };
        if (error.requiereReset) body.requiereReset = true;
        if (error.odbcErrors) body.detalle = error.odbcErrors;
        res.status(statusCode).json(body);
    }
}

async function refresh(req, res) {
    try {
        const token = service.refreshToken(req.user);
        res.json({ ok: true, mensaje: 'Token renovado correctamente', token });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: 'Error al renovar el token' });
    }
}

async function changePassword(req, res) {
    try {
        await service.changePassword(
            req.user.id,
            req.body.oldPassword,
            req.body.newPassword,
            req.body.confirmPassword
        );
        res.json({ ok: true, mensaje: 'Contraseña actualizada correctamente' });
    } catch (error) {
        const statusCode = error.statusCode || 500;
        const body = { ok: false, mensaje: error.message };
        if (error.odbcErrors) body.detalle = error.odbcErrors;
        res.status(statusCode).json(body);
    }
}

module.exports = { login, refresh, changePassword };
