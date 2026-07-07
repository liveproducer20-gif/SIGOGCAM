const repository = require('../repositories/catalogos.repository');

async function obtenerCatalogos() {
    return await repository.obtenerCatalogos();
}

async function obtenerDetallesPorCodigo(codigo) {
    if (!codigo || codigo.trim() === '') {
        throw new Error('El código del catálogo es obligatorio');
    }

    return await repository.obtenerDetallesPorCodigo(codigo.trim().toUpperCase());
}

module.exports = {
    obtenerCatalogos,
    obtenerDetallesPorCodigo
};