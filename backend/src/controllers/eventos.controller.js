const { asyncHandler } = require('../middleware/async-handler');
const service = require('../services/eventos.service');
const mediaService = require('../services/eventos-media.service');

const obtenerTodos = asyncHandler(async (req, res) => {
    const permisos = Array.isArray(req.user?.permisos) ? req.user.permisos : [];
    const filtros = { ...req.query };

    if (!permisos.includes('eventos.ver') && permisos.includes('eventos.ver_convocado')) {
        filtros.personalId = req.user.id;
    }
    filtros.marcarVisto = req.query.marcarVisto === '1';

    res.json({ ok: true, datos: await service.obtenerTodos(filtros) });
});

const obtenerPorId = asyncHandler(async (req, res) => {
    const datos = await service.obtenerPorId(req.params.id);

    if (!datos.evento) {
        return res.status(404).json({ ok: false, mensaje: 'Evento no encontrado' });
    }

    res.json({ ok: true, datos });
});

const crearEvento = asyncHandler(async (req, res) => {
    const eventoId = await service.crearEvento(req.body);
    res.status(201).json({ ok: true, mensaje: 'Evento creado correctamente', eventoId });
});

const subirArchivo = asyncHandler(async (req, res) => {
    const ruta = await mediaService.saveUpload(req.body, req.headers['content-type']);
    res.status(201).json({ ok: true, datos: { ruta } });
});

const cambiarEstado = asyncHandler(async (req, res) => {
    await service.cambiarEstado(req.params.id, req.body.estado);
    res.json({ ok: true, mensaje: 'Estado del evento actualizado correctamente' });
});

const actualizarEvento = asyncHandler(async (req, res) => {
    await service.actualizarEvento(req.params.id, req.body);
    res.json({ ok: true, mensaje: 'Evento actualizado correctamente' });
});

const eliminarEvento = asyncHandler(async (req, res) => {
    await service.eliminarEvento(req.params.id);
    res.json({ ok: true, mensaje: 'Evento eliminado exitosamente' });
});

module.exports = {
    obtenerTodos,
    obtenerPorId,
    subirArchivo,
    crearEvento,
    cambiarEstado,
    actualizarEvento,
    eliminarEvento
};
