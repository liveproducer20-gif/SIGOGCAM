const repository = require('../repositories/admin.repository');
const { validarId, texto, textoOpcional, entero, normalizarCodigo } = require('../validators/common.validator');

const catalogosPermitidos = new Set([
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

async function listarDetalles(codigo, incluirInactivos, query = {}) {
    return repository.listarDetalles(validarCatalogo(codigo), incluirInactivos, query);
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

async function listarRoles(query = {}) {
    const result = await repository.listarRoles(query);
    if (result.datos) {
        result.datos = result.datos.map((rol) => ({
            ...rol,
            permisos: rol.permisos ? rol.permisos.split(',') : []
        }));
    }
    return result;
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

async function listarLugares(query = {}) {
    return repository.listarLugares(query);
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

async function listarEas(query = {}) {
    return repository.listarEas(query);
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

async function listarRutas() {
    return repository.listarRutas();
}

async function listarGrados() {
    return repository.listarGrados();
}

async function crearRuta(data) {
    return repository.crearRuta(validarRuta(data));
}

async function actualizarRuta(id, data) {
    return repository.actualizarRuta(validarId(id, 'ruta'), validarRuta(data));
}

async function cambiarEstadoRuta(id, activo) {
    return repository.cambiarEstadoRuta(validarId(id, 'ruta'), Boolean(activo));
}

async function eliminarRuta(id) {
    return repository.eliminarRuta(validarId(id, 'ruta'));
}

async function listarMoviles(query = {}) {
    return repository.listarMoviles(query);
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

async function eliminarDetalle(id) {
    return repository.eliminarDetalle(validarId(id, 'detalle'));
}

async function eliminarRol(id) {
    return repository.eliminarRol(validarId(id, 'rol'));
}

async function eliminarLugar(id) {
    return repository.eliminarLugar(validarId(id, 'lugar'));
}

async function eliminarEas(id) {
    return repository.eliminarEas(validarId(id, 'EAS'));
}

async function eliminarMovil(id) {
    return repository.eliminarMovil(validarId(id, 'movil'));
}

async function eliminarAsignacion(id) {
    return repository.eliminarAsignacion(validarId(id, 'asignacion'));
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
        throw new Error('Catálogo de administración no permitido');
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
        rutaId: validarId(data.rutaId, 'ruta'),
        direccion: texto(data.direccion, 'ubicacion'),
        distritoId: validarId(data.distritoId, 'distrito'),
        horaEntrada: data.horaEntrada || null,
        horaSalida: data.horaSalida || null,
        consignas: textoOpcional(data.consignas)
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

function validarRuta(data) {
    return {
        nombre: texto(data.nombre, 'nombre')
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
    eliminarEas,
    listarRutas,
    crearRuta,
    actualizarRuta,
    cambiarEstadoRuta,
    eliminarRuta,
    listarGrados,
    listarMoviles,
    crearMovil,
    actualizarMovil,
    cambiarEstadoMovil,
    listarAsignaciones,
    crearAsignacion,
    actualizarAsignacion,
    obtenerAlertasMantenimiento,
    listarMantenimientos,
    crearMantenimiento,
    eliminarDetalle,
    eliminarRol,
    eliminarLugar,
    eliminarEas,
    eliminarMovil,
    eliminarAsignacion
};
