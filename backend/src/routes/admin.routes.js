const express = require('express');
const router = express.Router();

const controller = require('../controllers/admin.controller');
const {
    requireAuth,
    requirePermission,
    requireAnyPermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.get(
    '/dashboard/mantenimiento',
    requireAnyPermission(['dashboard.mantenimiento', 'moviles.ver']),
    controller.obtenerAlertasMantenimiento
);

router.get('/catalogos', requirePermission('catalogos.ver'), controller.listarCatalogos);
router.get('/catalogos/:codigo', requirePermission('catalogos.ver'), controller.listarDetalles);
router.post(
    '/catalogos/:codigo',
    requirePermission('catalogos.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'catalogo_detalles' }),
    controller.crearDetalle
);
router.put(
    '/catalogos/detalles/:id',
    requirePermission('catalogos.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'catalogo_detalles' }),
    controller.actualizarDetalle
);
router.put(
    '/catalogos/detalles/:id/estado',
    requirePermission('catalogos.estado'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'catalogo_detalles' }),
    controller.cambiarEstadoDetalle
);
router.delete(
    '/catalogos/detalles/:id',
    requirePermission('catalogos.estado'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'catalogo_detalles' }),
    controller.eliminarDetalle
);

router.get('/roles', requirePermission('roles.ver'), controller.listarRoles);
router.post(
    '/roles',
    requirePermission('roles.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'roles' }),
    controller.crearRol
);
router.put(
    '/roles/:id',
    requirePermission('roles.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'roles' }),
    controller.actualizarRol
);
router.put(
    '/roles/:id/estado',
    requirePermission('roles.editar'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'roles' }),
    controller.cambiarEstadoRol
);
router.delete(
    '/roles/:id',
    requirePermission('roles.editar'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'roles' }),
    controller.eliminarRol
);
router.get('/permisos', requirePermission('permisos.ver'), controller.listarPermisos);

router.get('/lugares-servicio', requirePermission('lugares_servicio.ver'), controller.listarLugares);
router.post(
    '/lugares-servicio',
    requirePermission('lugares_servicio.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'lugares_servicio' }),
    controller.crearLugar
);
router.put(
    '/lugares-servicio/:id',
    requirePermission('lugares_servicio.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'lugares_servicio' }),
    controller.actualizarLugar
);
router.put(
    '/lugares-servicio/:id/estado',
    requirePermission('lugares_servicio.estado'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'lugares_servicio' }),
    controller.cambiarEstadoLugar
);
router.delete(
    '/lugares-servicio/:id',
    requirePermission('lugares_servicio.estado'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'lugares_servicio' }),
    controller.eliminarLugar
);

router.get('/eas', requirePermission('eas.ver'), controller.listarEas);
router.post(
    '/eas',
    requirePermission('eas.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'eas_estaciones' }),
    controller.crearEas
);
router.put(
    '/eas/:id',
    requirePermission('eas.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'eas_estaciones' }),
    controller.actualizarEas
);
router.put(
    '/eas/:id/estado',
    requirePermission('eas.estado'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'eas_estaciones' }),
    controller.cambiarEstadoEas
);
router.delete(
    '/eas/:id',
    requirePermission('eas.estado'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'eas_estaciones' }),
    controller.eliminarEas
);

router.get('/rutas', requirePermission('eas.ver'), controller.listarRutas);
router.post(
    '/rutas',
    requirePermission('eas.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'rutas' }),
    controller.crearRuta
);
router.put(
    '/rutas/:id',
    requirePermission('eas.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'rutas' }),
    controller.actualizarRuta
);
router.put(
    '/rutas/:id/estado',
    requirePermission('eas.estado'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'rutas' }),
    controller.cambiarEstadoRuta
);
router.delete(
    '/rutas/:id',
    requirePermission('eas.estado'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'rutas' }),
    controller.eliminarRuta
);

router.get('/moviles', requirePermission('moviles.ver'), controller.listarMoviles);
router.post(
    '/moviles',
    requirePermission('moviles.crear'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'moviles' }),
    controller.crearMovil
);
router.put(
    '/moviles/:id',
    requirePermission('moviles.editar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'moviles' }),
    controller.actualizarMovil
);
router.put(
    '/moviles/:id/estado',
    requirePermission('moviles.estado'),
    auditAction({ accion: 'estado', modulo: 'administracion', tabla: 'moviles' }),
    controller.cambiarEstadoMovil
);
router.delete(
    '/moviles/:id',
    requirePermission('moviles.estado'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'moviles' }),
    controller.eliminarMovil
);
router.get(
    '/moviles/:id/mantenimientos',
    requirePermission('moviles.ver'),
    controller.listarMantenimientos
);
router.post(
    '/moviles/:id/mantenimientos',
    requirePermission('moviles.editar'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'movil_mantenimiento' }),
    controller.crearMantenimiento
);

router.get('/movil-eas-asignaciones', requirePermission('moviles.asignar'), controller.listarAsignaciones);
router.post(
    '/movil-eas-asignaciones',
    requirePermission('moviles.asignar'),
    auditAction({ accion: 'crear', modulo: 'administracion', tabla: 'movil_eas_asignaciones' }),
    controller.crearAsignacion
);
router.put(
    '/movil-eas-asignaciones/:id',
    requirePermission('moviles.asignar'),
    auditAction({ accion: 'editar', modulo: 'administracion', tabla: 'movil_eas_asignaciones' }),
    controller.actualizarAsignacion
);
router.delete(
    '/movil-eas-asignaciones/:id',
    requirePermission('moviles.asignar'),
    auditAction({ accion: 'eliminar', modulo: 'administracion', tabla: 'movil_eas_asignaciones' }),
    controller.eliminarAsignacion
);

module.exports = router;
