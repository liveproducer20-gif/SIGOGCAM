const repository = require('../repositories/anuncios.repository');

async function obtenerTodos(filtros = {}) {
    return await repository.obtenerTodos({
        personalId: filtros.personalId ? Number(filtros.personalId) : null
    });
}

async function crear(data) {
    validar(data);
    return await repository.crear(normalizar(data));
}

async function actualizar(id, data) {
    if (!id) throw new Error('El ID del anuncio es obligatorio');
    validar(data);
    return await repository.actualizar(id, normalizar(data));
}

async function cambiarPublicado(id, publicado) {
    if (!id) throw new Error('El ID del anuncio es obligatorio');
    return await repository.cambiarPublicado(id, publicado === true);
}

async function eliminar(id) {
    if (!id) throw new Error('El ID del anuncio es obligatorio');
    return await repository.eliminar(id);
}

function validar(data) {
    if (!data.titulo || data.titulo.toString().trim() === '') {
        throw new Error('El título del anuncio es obligatorio');
    }

    if (!data.descripcion || data.descripcion.toString().trim() === '') {
        throw new Error('La descripción del anuncio es obligatoria');
    }
}

function normalizar(data) {
    return {
        titulo: data.titulo.toString().trim(),
        descripcion: data.descripcion.toString().trim(),
        prioridad: data.prioridad ? data.prioridad.toString().trim() : 'Normal',
        imagenNombre: data.imagenNombre ? data.imagenNombre.toString().trim() : null,
        imagenUrl: normalizarImagenUrl(data.imagenUrl),
        fechaExpiracion: data.fechaExpiracion || null,
        publicado: data.publicado !== false,
        notificar: data.notificar !== false,
        creadoPor: data.creadoPor ? Number(data.creadoPor) : null,
        personalIds: Array.isArray(data.personalIds) ? data.personalIds : []
    };
}

function normalizarImagenUrl(value) {
    const text = value?.toString().trim();
    if (!text) return null;
    if (text.startsWith('/uploads/anuncios/')) return text;

    try {
        const url = new URL(text);
        if (url.pathname.startsWith('/uploads/anuncios/')) return url.pathname;
        if (url.protocol === 'https:') return url.toString();
    } catch (_) {}

    throw new Error('La imagen debe cargarse en el servidor o usar una URL HTTPS válida');
}

module.exports = {
    obtenerTodos,
    crear,
    actualizar,
    cambiarPublicado,
    eliminar
};
