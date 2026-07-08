const repository = require('../repositories/cartilla-flow.repository');

async function obtenerCp(usuarioId) {
    const data = await repository.obtenerCp(usuarioId);
    return data ? { nombreCp: data.nombre_cp } : { nombreCp: null };
}

async function guardarCp(usuarioId, nombreCp) {
    if (!nombreCp || !nombreCp.trim()) {
        throw new Error('El nombre del conductor CP es requerido');
    }
    await repository.guardarCp(usuarioId, nombreCp.trim());
    return { ok: true };
}

async function obtenerPolicia(usuarioId) {
    const data = await repository.obtenerPolicia(usuarioId);
    if (!data) return { servidorPolicialId: null, servidorNombre: null };
    return {
        servidorPolicialId: data.servidor_policial_id,
        servidorNombre: data.servidor_nombre,
    };
}

async function guardarPolicia(usuarioId, servidorPolicialId) {
    await repository.guardarPolicia(usuarioId, servidorPolicialId);
    return { ok: true };
}

async function listarServidoresPoliciales(easId) {
    if (!easId || isNaN(Number(easId))) {
        throw new Error('El ID del EAS es requerido');
    }
    return repository.listarServidoresPoliciales(Number(easId));
}

async function crearServidorPolicial(easId, nombre) {
    if (!nombre || !nombre.trim()) {
        throw new Error('El nombre del servidor policial es requerido');
    }
    const id = await repository.crearServidorPolicial(Number(easId), nombre.trim());
    return { id, nombre: nombre.trim() };
}

async function listarDireccionesPorEas(easId) {
    if (!easId || isNaN(Number(easId))) {
        throw new Error('El ID del EAS es requerido');
    }
    return repository.listarDireccionesPorEas(Number(easId));
}

async function crearDireccion(easId, direccion) {
    if (!direccion || !direccion.trim()) {
        throw new Error('La direccion es requerida');
    }
    const id = await repository.crearDireccion(Number(easId), direccion.trim());
    return { id, direccion: direccion.trim() };
}

module.exports = {
    obtenerCp,
    guardarCp,
    obtenerPolicia,
    guardarPolicia,
    listarServidoresPoliciales,
    crearServidorPolicial,
    listarDireccionesPorEas,
    crearDireccion
};
