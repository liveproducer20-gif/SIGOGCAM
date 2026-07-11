const repository = require('../repositories/insignias.repository');

async function obtenerTodas() {
    return await repository.obtenerTodas();
}

async function obtenerUsuarioInsignias(usuarioId) {
    if (!usuarioId) {
        throw new Error('El ID del usuario es obligatorio');
    }

    return await repository.obtenerUsuarioInsignias(Number(usuarioId));
}

async function obtenerProgreso(usuarioId) {
    if (!usuarioId) {
        throw new Error('El ID del usuario es obligatorio');
    }

    return await repository.obtenerProgreso(Number(usuarioId));
}

async function obtenerRanking() {
    return await repository.obtenerRanking();
}

module.exports = {
    obtenerTodas,
    obtenerUsuarioInsignias,
    obtenerProgreso,
    obtenerRanking
};
