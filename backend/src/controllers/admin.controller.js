const service = require('../services/admin.service');

const handlers = {
    listarCatalogos: handle(() => service.listarCatalogos()),
    listarDetalles: handle((req) => service.listarDetalles(
        req.params.codigo,
        req.query.incluirInactivos === '1',
        req.query
    )),
    crearDetalle: handle((req) => service.crearDetalle(req.params.codigo, req.body), 201, 'Detalle creado correctamente', 'detalleId'),
    actualizarDetalle: handle((req) => service.actualizarDetalle(req.params.id, req.body), 200, 'Detalle actualizado correctamente'),
    cambiarEstadoDetalle: handle((req) => service.cambiarEstadoDetalle(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarRoles: handle((req) => service.listarRoles(req.query)),
    crearRol: handle((req) => service.crearRol(req.body), 201, 'Rol creado correctamente', 'rolId'),
    actualizarRol: handle((req) => service.actualizarRol(req.params.id, req.body), 200, 'Rol actualizado correctamente'),
    cambiarEstadoRol: handle((req) => service.cambiarEstadoRol(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),
    listarPermisos: handle(() => service.listarPermisos()),

    listarLugares: handle((req) => service.listarLugares(req.query)),
    crearLugar: handle((req) => service.crearLugar(req.body), 201, 'Lugar de servicio creado correctamente', 'lugarId'),
    actualizarLugar: handle((req) => service.actualizarLugar(req.params.id, req.body), 200, 'Lugar de servicio actualizado correctamente'),
    cambiarEstadoLugar: handle((req) => service.cambiarEstadoLugar(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarEas: handle((req) => service.listarEas(req.query)),
    crearEas: handle((req) => service.crearEas(req.body), 201, 'EAS creado correctamente', 'easId'),
    actualizarEas: handle((req) => service.actualizarEas(req.params.id, req.body), 200, 'EAS actualizado correctamente'),
    cambiarEstadoEas: handle((req) => service.cambiarEstadoEas(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarMoviles: handle((req) => service.listarMoviles(req.query)),
    crearMovil: handle((req) => service.crearMovil(req.body), 201, 'Movil creado correctamente', 'movilId'),
    actualizarMovil: handle((req) => service.actualizarMovil(req.params.id, req.body), 200, 'Movil actualizado correctamente'),
    cambiarEstadoMovil: handle((req) => service.cambiarEstadoMovil(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarAsignaciones: handle((req) => service.listarAsignaciones(req.query)),
    crearAsignacion: handle((req) => service.crearAsignacion(req.body), 201, 'Asignacion creada correctamente', 'asignacionId'),
    actualizarAsignacion: handle((req) => service.actualizarAsignacion(req.params.id, req.body), 200, 'Asignacion actualizada correctamente'),

    obtenerAlertasMantenimiento: handle(() => service.obtenerAlertasMantenimiento()),

    listarMantenimientos: handle((req) => service.listarMantenimientos(req.params.id)),
    crearMantenimiento: handle((req) => service.crearMantenimiento({ ...req.body, movilId: req.params.id }), 201, 'Mantenimiento registrado correctamente', 'mantenimientoId'),

    eliminarDetalle: handle((req) => service.eliminarDetalle(req.params.id), 200, 'Detalle eliminado correctamente'),
    eliminarRol: handle((req) => service.eliminarRol(req.params.id), 200, 'Rol eliminado correctamente'),
    eliminarLugar: handle((req) => service.eliminarLugar(req.params.id), 200, 'Lugar eliminado correctamente'),
    eliminarEas: handle((req) => service.eliminarEas(req.params.id), 200, 'EAS eliminado correctamente'),
    listarRutas: handle(() => service.listarRutas()),
    listarGrados: handle(() => service.listarGrados()),
    crearGrado: handle((req) => service.crearGrado(req.body), 201, 'Grado creado correctamente', 'gradoId'),
    actualizarGrado: handle((req) => service.actualizarGrado(req.params.id, req.body), 200, 'Grado actualizado correctamente'),
    cambiarEstadoGrado: handle((req) => service.cambiarEstadoGrado(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),
    eliminarGrado: handle((req) => service.eliminarGrado(req.params.id), 200, 'Grado eliminado correctamente'),
    crearRuta: handle((req) => service.crearRuta(req.body), 201, 'Ruta creada correctamente', 'rutaId'),
    actualizarRuta: handle((req) => service.actualizarRuta(req.params.id, req.body), 200, 'Ruta actualizada correctamente'),
    cambiarEstadoRuta: handle((req) => service.cambiarEstadoRuta(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),
    eliminarRuta: handle((req) => service.eliminarRuta(req.params.id), 200, 'Ruta eliminada correctamente'),
    eliminarMovil: handle((req) => service.eliminarMovil(req.params.id), 200, 'Movil eliminado correctamente'),
    eliminarAsignacion: handle((req) => service.eliminarAsignacion(req.params.id), 200, 'Asignacion eliminada correctamente')
};

function handle(action, status = 200, mensaje = null, idKey = null) {
    return async (req, res) => {
        try {
            const result = await action(req);
            const body = { ok: true };

            if (mensaje) body.mensaje = mensaje;
            if (idKey) {
                body[idKey] = result;
            } else if (result && typeof result === 'object' && !Array.isArray(result) && result.datos !== undefined) {
                body.datos = result.datos;
                if (result.total !== null && result.total !== undefined) body.total = result.total;
                if (result.page !== null && result.page !== undefined) body.page = result.page;
            } else {
                body.datos = result;
            }

            res.status(status).json(body);
        } catch (error) {
            const statusCode = _statusFromError(error);
            res.status(statusCode).json({
                ok: false,
                mensaje: error.message
            });
        }
    };
}

function _statusFromError(error) {
    const msg = (error.message || '').toLowerCase();
    if (msg.includes('no encontrado') || msg.includes('not found')) return 404;
    if (msg.includes('obligatorio') || msg.includes('requerido') || msg.includes('invalido') || msg.includes('inválido')) return 400;
    if (msg.includes('permiso') || msg.includes('autorizado') || msg.includes('prohibido')) return 403;
    if (msg.includes('conflicto') || msg.includes('ya existe') || msg.includes('duplicado')) return 409;
    return 400;
}

module.exports = handlers;
