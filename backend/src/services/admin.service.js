const repository = require('../repositories/admin.repository');

const catalogosPermitidos = new Set([
    'GRADOS',
    'AREAS',
    'FUNCIONES_OPERATIVAS',
    'GRUPOS',
    'JORNADAS',
    'TIPOS_ROTACION',
    'ESTADOS_PERSONAL',
    'DISTRITOS',
    'SUBUNIDADES_OPERATIVAS',
    'TIPOS_SERVICIO_LUGAR',
    'TIPOS_MOVIL',
    'ESTADOS_MOVIL',
    'ESTADOS_ASIGNACION_MOVIL',
    'TIPOS_MANTENIMIENTO'
]);

async function listarCatalogos() {
    return repository.listarCatalogos();
}

async function listarDetalles(codigo, incluirInactivos) {
    return repository.listarDetalles(validarCatalogo(codigo), incluirInactivos);
}

async function crearDetalle(codigo, data) {
    const catalogo = validarCatalogo(codigo);
    const payload = validarDetalle(data);
    return repository.crearDetalle(catalogo, payload);
}

async function actualizarDetalle(id, data) {
    const detalleId = validarId(id, 'detalle');
    const payload = validarDetalle(data);
    return repository.actualizarDetalle(detalleId, payload);
}

async function cambiarEstadoDetalle(id, activo) {
    return repository.cambiarEstadoDetalle(validarId(id, 'detalle'), Boolean(activo));
}

async function listarRoles() {
    const roles = await repository.listarRoles();
    return roles.map((rol) => ({
        ...rol,
        permisos: rol.permisos ? rol.permisos.split(',') : []
    }));
}

async function crearRol(data) {
    const payload = validarRol(data);
    return repository.crearRol(payload);
}

async function actualizarRol(id, data) {
    const payload = validarRol(data);
    return repository.actualizarRol(validarId(id, 'rol'), payload);
}

async function cambiarEstadoRol(id, activo) {
    return repository.cambiarEstadoRol(validarId(id, 'rol'), Boolean(activo));
}

async function listarPermisos() {
    return repository.listarPermisos();
}

async function listarLugares() {
    return repository.listarLugares();
}

async function crearLugar(data) {
    return repository.crearLugar(validarLugar(data));
}

async function actualizarLugar(id, data) {
    return repository.actualizarLugar(validarId(id, 'lugar'), validarLugar(data));
}

async function cambiarEstadoLugar(id, activo) {
    return repository.cambiarEstadoLugar(validarId(id, 'lugar'), Boolean(activo));
}

async function listarEas() {
    return repository.listarEas();
}

async function crearEas(data) {
    return repository.crearEas(validarEas(data));
}

async function actualizarEas(id, data) {
    return repository.actualizarEas(validarId(id, 'EAS'), validarEas(data));
}

async function cambiarEstadoEas(id, activo) {
    return repository.cambiarEstadoEas(validarId(id, 'EAS'), Boolean(activo));
}

async function listarMoviles() {
    return repository.listarMoviles();
}

async function crearMovil(data) {
    return repository.crearMovil(validarMovil(data));
}

async function actualizarMovil(id, data) {
    return repository.actualizarMovil(validarId(id, 'movil'), validarMovil(data));
}

async function cambiarEstadoMovil(id, activo) {
    return repository.cambiarEstadoMovil(validarId(id, 'movil'), Boolean(activo));
}

async function listarAsignaciones() {
    return repository.listarAsignaciones();
}

async function crearAsignacion(data) {
    return repository.crearAsignacion(validarAsignacion(data));
}

async function actualizarAsignacion(id, data) {
    return repository.actualizarAsignacion(
        validarId(id, 'asignacion'),
        validarAsignacion(data)
    );
}

async function obtenerAlertasMantenimiento() {
    return repository.obtenerAlertasMantenimiento();
}

async function listarMantenimientos(movilId) {
    return repository.listarMantenimientos(validarId(movilId, 'movil'));
}

async function crearMantenimiento(data) {
    return repository.crearMantenimiento(validarMantenimiento(data));
}

function validarMantenimiento(data) {
    return {
        movilId: validarId(data.movilId, 'movil'),
        fechaMantenimiento: data.fechaMantenimiento || new Date().toISOString(),
        kilometraje: entero(data.kilometraje, 0),
        descripcion: textoOpcional(data.descripcion),
        tipoMantenimientoId: data.tipoMantenimientoId ? validarId(data.tipoMantenimientoId, 'tipo mantenimiento') : null
    };
}

function validarCatalogo(codigo) {
    const value = (codigo || '').toString().trim().toUpperCase();
    if (!catalogosPermitidos.has(value)) {
        throw new Error('Catalogo de administracion no permitido');
    }
    return value;
}

function validarDetalle(data) {
    const nombre = texto(data.nombre, 'nombre');
    const codigo = (data.codigo || normalizarCodigo(nombre)).toString().trim().toUpperCase();
    return {
        codigo,
        nombre,
        descripcion: textoOpcional(data.descripcion),
        orden: entero(data.orden, 0)
    };
}

function validarRol(data) {
    return {
        nombre: texto(data.nombre, 'nombre'),
        descripcion: textoOpcional(data.descripcion),
        permisos: Array.isArray(data.permisos) ? data.permisos : []
    };
}

function validarLugar(data) {
    return {
        nombre: texto(data.nombre, 'nombre'),
        direccion: texto(data.direccion, 'direccion'),
        distritoId: validarId(data.distritoId, 'distrito'),
        subunidadOperativaId: data.subunidadOperativaId ? validarId(data.subunidadOperativaId, 'subunidad') : null,
        tipoServicioId: validarId(data.tipoServicioId, 'tipo de servicio'),
        observacion: textoOpcional(data.observacion)
    };
}

function validarEas(data) {
    return {
        nombre: texto(data.nombre, 'nombre'),
        codigo: texto(data.codigo, 'codigo'),
        direccion: texto(data.direccion, 'direccion'),
        distritoId: validarId(data.distritoId, 'distrito')
    };
}

function validarMovil(data) {
    const kilometrajeActual = entero(data.kilometrajeActual, 0);
    const kilometrajeUltimoMantenimiento = entero(data.kilometrajeUltimoMantenimiento, 0);
    if (kilometrajeActual < 0 || kilometrajeUltimoMantenimiento < 0) {
        throw new Error('Los kilometrajes no pueden ser negativos');
    }

    return {
        numeroMovil: texto(data.numeroMovil, 'numero de movil'),
        placa: textoOpcional(data.placa),
        tipoMovilId: validarId(data.tipoMovilId, 'tipo de movil'),
        kilometrajeActual,
        kilometrajeUltimoMantenimiento,
        estadoMovilId: validarId(data.estadoMovilId, 'estado de movil'),
        observacion: textoOpcional(data.observacion),
        observacionEstado: textoOpcional(data.observacionEstado)
    };
}

function validarAsignacion(data) {
    return {
        easId: validarId(data.easId, 'EAS'),
        movilId: validarId(data.movilId, 'movil'),
        fechaAsignacion: data.fechaAsignacion || new Date().toISOString(),
        estadoAsignacionId: validarId(data.estadoAsignacionId, 'estado'),
        observacion: textoOpcional(data.observacion)
    };
}

function validarId(value, label) {
    const id = Number(value);
    if (!Number.isInteger(id) || id <= 0) {
        throw new Error(`El id de ${label} no es valido`);
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
        throw new Error('Ingrese un numero entero valido');
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

module.exports = {
    listarCatalogos,
    listarDetalles,
    crearDetalle,
    actualizarDetalle,
    cambiarEstadoDetalle,
    listarRoles,
    crearRol,
    actualizarRol,
    cambiarEstadoRol,
    listarPermisos,
    listarLugares,
    crearLugar,
    actualizarLugar,
    cambiarEstadoLugar,
    listarEas,
    crearEas,
    actualizarEas,
    cambiarEstadoEas,
    listarMoviles,
    crearMovil,
    actualizarMovil,
    cambiarEstadoMovil,
    listarAsignaciones,
    crearAsignacion,
    actualizarAsignacion,
    obtenerAlertasMantenimiento,
    listarMantenimientos,
    crearMantenimiento
};
