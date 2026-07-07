const service = require('../services/personal.service');

async function obtenerTodo(req, res) {
    try {
        const datos = await service.obtenerTodo();

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

async function obtenerOperativos(req, res) {
    try {
        const datos = await service.obtenerOperativos();

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

async function obtenerDisponibles(req, res) {
    try {
        const datos = await service.obtenerDisponibles();

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

async function obtenerDisponiblesSinEvento(req, res) {
    try {
        const datos = await service.obtenerDisponiblesSinEvento();

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

async function buscar(req, res) {
    try {
        const { texto } = req.query;
        const datos = await service.buscar(texto);

        res.json({
            ok: true,
            datos
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerMiPerfil(req, res) {
    try {
        const datos = await service.obtenerPerfil(req.user.id);

        res.json({
            ok: true,
            datos
        });
    } catch (error) {
        res.status(404).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function actualizarMiPerfil(req, res) {
    try {
        const datos = await service.actualizarPerfil(req.user.id, req.body);

        res.json({
            ok: true,
            mensaje: 'Perfil actualizado correctamente',
            datos
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function crear(req, res) {
    try {
        const personalId = await service.crear(req.body);

        res.status(201).json({
            ok: true,
            mensaje: 'Personal registrado correctamente',
            personalId
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function actualizar(req, res) {
    try {
        const datos = await service.actualizar(req.params.id, req.body);

        res.json({
            ok: true,
            mensaje: 'Personal actualizado correctamente',
            datos
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function cambiarEstado(req, res) {
    try {
        const datos = await service.cambiarEstado(req.params.id, req.body.activo);

        res.json({
            ok: true,
            mensaje: 'Estado actualizado correctamente',
            datos
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function restablecerPassword(req, res) {
    try {
        await service.restablecerPassword(req.params.id);

        res.json({
            ok: true,
            mensaje: 'Contrasena restablecida correctamente'
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message
        });
    }
}

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
    restablecerPassword
};
