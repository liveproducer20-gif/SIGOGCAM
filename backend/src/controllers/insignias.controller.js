const service = require('../services/insignias.service');

function puedeConsultarUsuario(req, usuarioId) {
    const permisos = Array.isArray(req.user?.permisos) ? req.user.permisos : [];
    return Number(req.user?.id) === Number(usuarioId) || permisos.includes('personal.ver');
}

async function obtenerTodas(req, res) {
    try {
        const datos = await service.obtenerTodas();
        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerUsuarioInsignias(req, res) {
    try {
        const { id } = req.params;

        if (!puedeConsultarUsuario(req, id)) {
            return res.status(403).json({
                ok: false,
                mensaje: 'No puede consultar insignias de otro usuario'
            });
        }

        const datos = await service.obtenerUsuarioInsignias(id);
        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerProgreso(req, res) {
    try {
        const { id } = req.params;

        if (!puedeConsultarUsuario(req, id)) {
            return res.status(403).json({
                ok: false,
                mensaje: 'No puede consultar progreso de otro usuario'
            });
        }

        const datos = await service.obtenerProgreso(id);

        if (!datos) {
            return res.status(404).json({
                ok: false,
                mensaje: 'Usuario no encontrado'
            });
        }

        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerRanking(req, res) {
    try {
        const datos = await service.obtenerRanking();
        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

module.exports = {
    obtenerTodas,
    obtenerUsuarioInsignias,
    obtenerProgreso,
    obtenerRanking
};
