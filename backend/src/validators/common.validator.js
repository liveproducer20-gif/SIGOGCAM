function validarId(value, label) {
    const id = Number(value);
    if (!Number.isInteger(id) || id <= 0) {
        throw new Error(`El id de ${label} no es válido`);
    }
    return id;
}

function texto(value, label) {
    const clean = (value || '').toString().trim();
    if (!clean) {
        throw new Error(`El campo ${label} es obligatorio`);
    }
    return clean;
}

function textoOpcional(value) {
    const clean = (value || '').toString().trim();
    return clean || null;
}

function entero(value, defaultValue) {
    if (value === undefined || value === null || value === '') return defaultValue;
    const parsed = Number(value);
    if (!Number.isInteger(parsed)) {
        throw new Error('Ingrese un número entero válido');
    }
    return parsed;
}

function normalizarCodigo(value) {
    return value
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '')
        .replace(/[^a-zA-Z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '')
        .toUpperCase();
}

module.exports = { validarId, texto, textoOpcional, entero, normalizarCodigo };
