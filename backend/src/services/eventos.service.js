const repository = require('../repositories/eventos.repository');

async function obtenerTodos(filtros = {}) {
    return await repository.obtenerTodos({
        personalId: filtros.personalId ? Number(filtros.personalId) : null,
        marcarVisto: filtros.marcarVisto === true
    });
}

async function obtenerPorId(id) {
    if (!id) {
        throw new Error('El ID del evento es obligatorio');
    }

    return await repository.obtenerPorId(id);
}

async function crearEvento(data) {
    if (!data.titulo || data.titulo.trim() === '') {
        throw new Error('El título del evento es obligatorio');
    }

    if (!data.tipoEventoId) {
        throw new Error('El tipo de evento es obligatorio');
    }

    if (!data.fechaInicio) {
        throw new Error('La fecha de inicio es obligatoria');
    }

    if (!data.fechaFin) {
        throw new Error('La fecha de fin es obligatoria');
    }

    if (!data.creadoPor) {
        throw new Error('El usuario creador es obligatorio');
    }

    return await repository.crearEvento({
        titulo: data.titulo.toString().trim(),
        tipoEventoId: Number(data.tipoEventoId),
        fechaInicio: normalizarFechaSql(data.fechaInicio),
        fechaFin: normalizarFechaSql(data.fechaFin),
        lugar: data.lugar ? data.lugar.toString().trim() : null,
        descripcion: data.descripcion ? data.descripcion.toString().trim() : null,
        creadoPor: Number(data.creadoPor),
        prioridad: data.prioridad ? data.prioridad.toString().trim() : 'Normal',
        notificar: data.notificar !== false,
        imagenUrl: data.imagenUrl || null,
        pdfNombre: data.pdfNombre || null,
        pdfUrl: data.pdfUrl || null,
        personalIds: Array.isArray(data.personalIds) ? data.personalIds : []
    });
}

async function cambiarEstado(id, estado) {
    if (!id) {
        throw new Error('El ID del evento es obligatorio');
    }

    if (!estado || estado.trim() === '') {
        throw new Error('El estado es obligatorio');
    }

    return await repository.cambiarEstado(id, estado.trim().toUpperCase());
}

async function actualizarEvento(id, data) {
    if (!id) {
        throw new Error('El ID del evento es obligatorio');
    }

    if (!data.titulo || data.titulo.trim() === '') {
        throw new Error('El titulo del evento es obligatorio');
    }

    if (!data.tipoEventoId) {
        throw new Error('El tipo de evento es obligatorio');
    }

    if (!data.fechaInicio) {
        throw new Error('La fecha de inicio es obligatoria');
    }

    if (!data.fechaFin) {
        throw new Error('La fecha de fin es obligatoria');
    }

    return await repository.actualizarEvento(id, {
        titulo: data.titulo.toString().trim(),
        tipoEventoId: Number(data.tipoEventoId),
        fechaInicio: data.fechaInicio,
        fechaFin: data.fechaFin,
        lugar: data.lugar ? data.lugar.toString().trim() : null,
        descripcion: data.descripcion ? data.descripcion.toString().trim() : null,
        prioridad: data.prioridad ? data.prioridad.toString().trim() : 'Normal',
        personalIds: Array.isArray(data.personalIds) ? data.personalIds : null
    });
}

async function eliminarEvento(id) {
    if (!id) {
        throw new Error('El ID del evento es obligatorio');
    }

    return await repository.eliminarEvento(id);
}

module.exports = {
    obtenerTodos,
    obtenerPorId,
    crearEvento,
    cambiarEstado,
    actualizarEvento,
    eliminarEvento
};

function normalizarFechaSql(value) {
    return value
        .toString()
        .trim()
        .replace('T', ' ')
        .replace(/\.\d{3}Z$/, '')
        .replace(/Z$/, '');
}
