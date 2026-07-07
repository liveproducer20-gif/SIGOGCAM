const service = require('../services/eventos.service');

async function obtenerTodos(req, res) {
    try {
        const permisos = Array.isArray(req.user?.permisos)
            ? req.user.permisos
            : [];
        const filtros = { ...req.query };

        if (!permisos.includes('eventos.ver') &&
            permisos.includes('eventos.ver_convocado')) {
            filtros.personalId = req.user.id;
        }
        filtros.marcarVisto = req.query.marcarVisto === '1';

        const datos = await service.obtenerTodos(filtros);

        res.json({
            ok: true,
            datos
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerPorId(req, res) {
    try {
        const { id } = req.params;
        const datos = await service.obtenerPorId(id);

        if (!datos.evento) {
            return res.status(404).json({
                ok: false,
                mensaje: 'Evento no encontrado'
            });
        }

        res.json({
            ok: true,
            datos
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function crearEvento(req, res) {
    try {
        const eventoId = await service.crearEvento(req.body);

        res.status(201).json({
            ok: true,
            mensaje: 'Evento creado correctamente',
            eventoId
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message,
            detalle: error.odbcErrors || error
        });
    }
}

async function cambiarEstado(req, res) {
    try {
        const { id } = req.params;
        const { estado } = req.body;

        await service.cambiarEstado(id, estado);

        res.json({
            ok: true,
            mensaje: 'Estado del evento actualizado correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function actualizarEvento(req, res) {
    try {
        const { id } = req.params;

        await service.actualizarEvento(id, req.body);

        res.json({
            ok: true,
            mensaje: 'Evento actualizado correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function eliminarEvento(req, res) {
    try {
        const { id } = req.params;

        await service.eliminarEvento(id);

        res.json({
            ok: true,
            mensaje: 'Evento eliminado exitosamente'
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
    obtenerPorId,
    crearEvento,
    cambiarEstado,
    actualizarEvento,
    eliminarEvento
};
