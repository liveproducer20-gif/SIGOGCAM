const service = require('../services/admin.service');

const handlers = {
    listarCatalogos: handle(() => service.listarCatalogos()),
    listarDetalles: handle((req) => service.listarDetalles(
        req.params.codigo,
        req.query.incluirInactivos === '1'
    )),
    crearDetalle: handle((req) => service.crearDetalle(req.params.codigo, req.body), 201, 'Detalle creado correctamente', 'detalleId'),
    actualizarDetalle: handle((req) => service.actualizarDetalle(req.params.id, req.body), 200, 'Detalle actualizado correctamente'),
    cambiarEstadoDetalle: handle((req) => service.cambiarEstadoDetalle(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarRoles: handle(() => service.listarRoles()),
    crearRol: handle((req) => service.crearRol(req.body), 201, 'Rol creado correctamente', 'rolId'),
    actualizarRol: handle((req) => service.actualizarRol(req.params.id, req.body), 200, 'Rol actualizado correctamente'),
    cambiarEstadoRol: handle((req) => service.cambiarEstadoRol(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),
    listarPermisos: handle(() => service.listarPermisos()),

    listarLugares: handle(() => service.listarLugares()),
    crearLugar: handle((req) => service.crearLugar(req.body), 201, 'Lugar de servicio creado correctamente', 'lugarId'),
    actualizarLugar: handle((req) => service.actualizarLugar(req.params.id, req.body), 200, 'Lugar de servicio actualizado correctamente'),
    cambiarEstadoLugar: handle((req) => service.cambiarEstadoLugar(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarEas: handle(() => service.listarEas()),
    crearEas: handle((req) => service.crearEas(req.body), 201, 'EAS creado correctamente', 'easId'),
    actualizarEas: handle((req) => service.actualizarEas(req.params.id, req.body), 200, 'EAS actualizado correctamente'),
    cambiarEstadoEas: handle((req) => service.cambiarEstadoEas(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarMoviles: handle(() => service.listarMoviles()),
    crearMovil: handle((req) => service.crearMovil(req.body), 201, 'Movil creado correctamente', 'movilId'),
    actualizarMovil: handle((req) => service.actualizarMovil(req.params.id, req.body), 200, 'Movil actualizado correctamente'),
    cambiarEstadoMovil: handle((req) => service.cambiarEstadoMovil(req.params.id, req.body.activo), 200, 'Estado actualizado correctamente'),

    listarAsignaciones: handle(() => service.listarAsignaciones()),
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
            const datos = await action(req);
            const body = { ok: true };

            if (mensaje) body.mensaje = mensaje;
            if (idKey) {
                body[idKey] = datos;
            } else {
                body.datos = datos;
            }

            res.status(status).json(body);
        } catch (error) {
            res.status(400).json({
                ok: false,
                mensaje: error.message
            });
        }
    };
}

module.exports = handlers;
