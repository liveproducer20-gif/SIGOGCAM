const { asyncHandler } = require('../middleware/async-handler');
const service = require('../services/personal.service');

const responder = (res, datos, status = 200) => {
    res.status(status).json({ ok: true, datos });
};

const obtenerTodo = asyncHandler(async (req, res) => {
    responder(res, await service.obtenerTodo());
});

const obtenerOperativos = asyncHandler(async (req, res) => {
    responder(res, await service.obtenerOperativos());
});

const obtenerDisponibles = asyncHandler(async (req, res) => {
    responder(res, await service.obtenerDisponibles());
});

const obtenerDisponiblesSinEvento = asyncHandler(async (req, res) => {
    responder(res, await service.obtenerDisponiblesSinEvento());
});

const buscar = asyncHandler(async (req, res) => {
    responder(res, await service.buscar(req.query.texto));
});

const obtenerMiPerfil = asyncHandler(async (req, res) => {
    responder(res, await service.obtenerPerfil(req.user.id));
});

const actualizarMiPerfil = asyncHandler(async (req, res) => {
    const datos = await service.actualizarPerfil(req.user.id, req.body);
    res.json({ ok: true, mensaje: 'Perfil actualizado correctamente', datos });
});

const crear = asyncHandler(async (req, res) => {
    const personalId = await service.crear(req.body);
    res.status(201).json({ ok: true, mensaje: 'Personal registrado correctamente', personalId });
});

const actualizar = asyncHandler(async (req, res) => {
    const datos = await service.actualizar(req.params.id, req.body);
    res.json({ ok: true, mensaje: 'Personal actualizado correctamente', datos });
});

const cambiarEstado = asyncHandler(async (req, res) => {
    const datos = await service.cambiarEstado(req.params.id, req.body.activo);
    res.json({ ok: true, mensaje: 'Estado actualizado correctamente', datos });
});

const restablecerPassword = asyncHandler(async (req, res) => {
    await service.restablecerPassword(req.params.id);
    res.json({ ok: true, mensaje: 'Contraseña restablecida correctamente' });
});

const eliminar = asyncHandler(async (req, res) => {
    await service.eliminar(req.params.id);
    res.json({ ok: true, mensaje: 'Personal eliminado correctamente' });
});

module.exports = {
    obtenerTodo,
    obtenerOperativos,
    obtenerDisponibles,
    obtenerDisponiblesSinEvento,
    buscar,
    obtenerMiPerfil,
    actualizarMiPerfil,
    crear,
    actualizar,
    cambiarEstado,
    restablecerPassword,
    eliminar
};
