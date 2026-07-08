const service = require('../services/cartilla-flow.service');

const { asyncHandler } = require('../middleware/error.middleware');

const obtenerCp = asyncHandler(async (req, res) => {
    const data = await service.obtenerCp(req.user.id);
    res.json({ ok: true, ...data });
});

const guardarCp = asyncHandler(async (req, res) => {
    await service.guardarCp(req.user.id, req.body.nombreCp);
    res.json({ ok: true, mensaje: 'Conductor CP guardado correctamente' });
});

const obtenerPolicia = asyncHandler(async (req, res) => {
    const data = await service.obtenerPolicia(req.user.id);
    res.json({ ok: true, ...data });
});

const guardarPolicia = asyncHandler(async (req, res) => {
    await service.guardarPolicia(req.user.id, req.body.servidorPolicialId);
    res.json({ ok: true, mensaje: 'Servidor policial guardado correctamente' });
});

const listarServidoresPoliciales = asyncHandler(async (req, res) => {
    const list = await service.listarServidoresPoliciales();
    res.json({ ok: true, datos: list });
});

const listarDirecciones = asyncHandler(async (req, res) => {
    const list = await service.listarDireccionesPorEas(req.query.easId);
    res.json({ ok: true, datos: list });
});

const crearDireccion = asyncHandler(async (req, res) => {
    const result = await service.crearDireccion(req.body.easId, req.body.direccion);
    res.status(201).json({ ok: true, mensaje: 'Direccion guardada', ...result });
});

module.exports = {
    obtenerCp,
    guardarCp,
    obtenerPolicia,
    guardarPolicia,
    listarServidoresPoliciales,
    listarDirecciones,
    crearDireccion
};
