const repository = require('../repositories/cartillas.repository');

async function registrarCartilla(data) {
    if (!data.usuarioId) {
        throw new Error('El usuario es obligatorio');
    }

    if (!data.contenido || data.contenido.trim() === '') {
        throw new Error('El contenido de la cartilla es obligatorio');
    }

    return await repository.registrarCartilla({
        usuarioId: Number(data.usuarioId),
        causa: data.causa ? data.causa.toString().trim() : null,
        contenido: data.contenido.toString().trim()
    });
}

module.exports = {
    registrarCartilla
};
