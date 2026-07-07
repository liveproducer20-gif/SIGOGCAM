const service = require('../services/anuncios.service');

async function obtenerTodos(req, res) {
    try {
        const permisos = Array.isArray(req.user?.permisos) ? req.user.permisos : [];
        const filtros = { ...req.query };

        if (!permisos.includes('anuncios.ver') && req.user?.id) {
            filtros.personalId = req.user.id;
        }

        const datos = await service.obtenerTodos(filtros);
        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message,
            detalle: error.odbcErrors || error
        });
    }
}

async function crear(req, res) {
    try {
        const id = await service.crear({
            ...req.body,
            creadoPor: req.user?.id
        });
        res.status(201).json({
            ok: true,
            mensaje: 'Anuncio creado correctamente',
            anuncioId: id
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message,
            detalle: error.odbcErrors || error
        });
    }
}

async function actualizar(req, res) {
    try {
        await service.actualizar(req.params.id, req.body);
        res.json({
            ok: true,
            mensaje: 'Anuncio actualizado correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message,
            detalle: error.odbcErrors || error
        });
    }
}

async function cambiarPublicado(req, res) {
    try {
        await service.cambiarPublicado(req.params.id, req.body.publicado);
        res.json({
            ok: true,
            mensaje: 'Estado del anuncio actualizado correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function eliminar(req, res) {
    try {
        await service.eliminar(req.params.id);
        res.json({
            ok: true,
            mensaje: 'Anuncio eliminado correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

module.exports = {
    obtenerTodos,
    crear,
    actualizar,
    cambiarPublicado,
    eliminar
};
