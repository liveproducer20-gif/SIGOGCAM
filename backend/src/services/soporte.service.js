const repository = require('../repositories/soporte.repository');

const ESTADOS = ['Nuevo', 'En proceso', 'Pendiente', 'Resuelto', 'Cancelado'];
const PRIORIDADES = ['Crítica', 'Alta', 'Media', 'Baja'];

function httpError(message, statusCode = 400) {
    return Object.assign(new Error(message), { statusCode });
}

function isAdmin(user) { return user?.rol === 'ADMINISTRADOR'; }

async function listar(filters, user) { return repository.listar(filters || {}, user); }
async function estadisticas(user) { return repository.estadisticas(user); }

async function detalle(id, user) {
    const value = await repository.detalle(Number(id), user);
    if (!value) throw httpError('Alerta no encontrada o sin acceso', 404);
    return value;
}

async function crear(body, user) {
    const titulo = (body.titulo || '').toString().trim();
    const modulo = (body.modulo || '').toString().trim();
    const descripcion = (body.descripcion || '').toString().trim();
    if (titulo.length < 5 || titulo.length > 200) throw httpError('El título debe tener entre 5 y 200 caracteres');
    if (!modulo || modulo.length > 100) throw httpError('Seleccione un módulo válido');
    if (descripcion.length < 20 || descripcion.length > 3000) throw httpError('El detalle debe tener entre 20 y 3000 caracteres');
    const prioridad = PRIORIDADES.includes(body.prioridad) ? body.prioridad : 'Media';
    return repository.crear({ titulo, modulo, descripcion, prioridad, imagen: body.imagen || null }, user);
}

async function actualizar(id, body, user) {
    if (!isAdmin(user)) throw httpError('Solo un administrador puede gestionar alertas', 403);
    const changes = {};
    if (body.estado !== undefined) {
        if (!ESTADOS.includes(body.estado)) throw httpError('Estado no válido');
        changes.estado = body.estado;
    }
    if (body.prioridad !== undefined) {
        if (!PRIORIDADES.includes(body.prioridad)) throw httpError('Prioridad no válida');
        changes.prioridad = body.prioridad;
    }
    if (body.asignadoA !== undefined) {
        changes.asignadoA = Number(body.asignadoA) || null;
        changes.asignadoNombre = (body.asignadoNombre || '').toString().trim() || null;
    }
    const value = await repository.actualizar(Number(id), changes, user);
    if (!value) throw httpError('Alerta no encontrada', 404);
    return value;
}

async function comentar(id, body, user) {
    const detalleTicket = await repository.detalle(Number(id), user);
    if (!detalleTicket) throw httpError('Alerta no encontrada o sin acceso', 404);
    const comentario = (body.comentario || '').toString().trim();
    if (comentario.length < 2 || comentario.length > 3000) throw httpError('El comentario debe tener entre 2 y 3000 caracteres');
    const interno = isAdmin(user) && body.esInterno === true;
    return repository.comentar(Number(id), comentario, interno, user);
}

module.exports = { listar, estadisticas, detalle, crear, actualizar, comentar, isAdmin };

