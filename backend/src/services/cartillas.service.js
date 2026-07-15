const repository = require('../repositories/cartillas.repository');
const { validarConductor, validarAccesoEspecial } = require('../validators/cartillas.validator');

async function registrarCartilla(data) {
    if (!data.usuarioId) {
        throw new Error('El usuario es obligatorio');
    }

    if (!data.contenido || data.contenido.trim() === '') {
        throw new Error('El contenido de la cartilla es obligatorio');
    }

    const tipo = data.tipo ? data.tipo.toString().trim().toUpperCase() : null;
    const subtipo = data.subtipo ? data.subtipo.toString().trim().toUpperCase() : null;
    const datos = data.datos && typeof data.datos === 'object' && !Array.isArray(data.datos)
        ? data.datos
        : null;

    validarAccesoEspecial(tipo, data.usuarioRol);

    if (tipo === 'CONDUCTOR') {
        validarConductor(datos);
    }

    return await repository.registrarCartilla({
        usuarioId: Number(data.usuarioId),
        causa: data.causa ? data.causa.toString().trim() : null,
        contenido: data.contenido.toString().trim(),
        tipo,
        subtipo,
        datos
    });
}

async function obtenerCatalogosOperativos() {
    return repository.obtenerCatalogosOperativos();
}

module.exports = {
    registrarCartilla,
    obtenerCatalogosOperativos
};
