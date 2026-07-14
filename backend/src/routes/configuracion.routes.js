const express = require('express');
const router = express.Router();

const ctrl = require('../controllers/configuracion.controller');
const { requireAuth, requirePermission } = require('../middleware/auth.middleware');
const { scopeMiddleware } = require('../middleware/scope.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);
router.use(scopeMiddleware);

// Menú dinámico (accesible con cualquier rol autenticado)
router.get('/mi-estructura', ctrl.miEstructura);

// Módulos del sistema
router.get('/modulos', requirePermission('configuracion.roles.gestionar'), ctrl.listarModulos);
router.get('/modulos/:id', requirePermission('configuracion.roles.gestionar'), ctrl.obtenerModulo);
router.post(
    '/modulos',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'crear_modulo', modulo: 'configuracion', tabla: 'modulos_sistema' }),
    ctrl.crearModulo
);
router.put(
    '/modulos/:id',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'actualizar_modulo', modulo: 'configuracion', tabla: 'modulos_sistema' }),
    ctrl.actualizarModulo
);
router.delete(
    '/modulos/:id',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'eliminar_modulo', modulo: 'configuracion', tabla: 'modulos_sistema' }),
    ctrl.eliminarModulo
);

// Permisos por módulo
router.get('/modulos/:id/permisos', requirePermission('configuracion.roles.gestionar'), ctrl.listarPermisosModulo);

// Menú por rol
router.get('/roles/:rolId/menu', requirePermission('configuracion.roles.gestionar'), ctrl.obtenerMenuRol);
router.put(
    '/roles/:rolId/menu',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'guardar_menu_rol', modulo: 'configuracion', tabla: 'rol_menu_configuracion' }),
    ctrl.guardarMenuRol
);

// Alcance de datos por rol
router.get('/roles/:rolId/alcance', requirePermission('configuracion.roles.gestionar'), ctrl.obtenerAlcanceRol);
router.put(
    '/roles/:rolId/alcance',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'guardar_alcance_rol', modulo: 'configuracion', tabla: 'rol_alcance_datos' }),
    ctrl.guardarAlcanceRol
);

// Campos por rol
router.get('/roles/:rolId/campos', requirePermission('configuracion.roles.gestionar'), ctrl.obtenerCamposRol);
router.put(
    '/roles/:rolId/campos',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'guardar_campos_rol', modulo: 'configuracion', tabla: 'rol_campos_permisos' }),
    ctrl.guardarCamposRol
);

// Versiones
router.get('/roles/:rolId/versiones', requirePermission('configuracion.roles.gestionar'), ctrl.listarVersiones);
router.post(
    '/roles/:rolId/versiones',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'crear_version', modulo: 'configuracion', tabla: 'versiones_configuracion_roles' }),
    ctrl.crearVersion
);
router.post(
    '/roles/:rolId/versiones/:versionId/restaurar',
    requirePermission('configuracion.roles.gestionar'),
    auditAction({ accion: 'restaurar_version', modulo: 'configuracion', tabla: 'versiones_configuracion_roles' }),
    ctrl.restaurarVersion
);

// Auditoría
router.get('/auditoria', requirePermission('configuracion.roles.gestionar'), ctrl.listarAuditoria);

// Campos del sistema
router.get('/campos-sistema', requirePermission('configuracion.roles.gestionar'), ctrl.listarCamposSistema);

// Estructura completa (todo en uno)
router.get('/estructura', requirePermission('configuracion.roles.gestionar'), async (req, res, next) => {
    try {
        const repo = require('../repositories/configuracion.repository');
        const [modulos, roles] = await Promise.all([
            repo.listarModulos(),
            (async () => {
                const { getPool } = require('../config/db');
                const pool = await getPool();
                const conn = await pool.connect();
                try {
                    return await conn.query('SELECT id, nombre, codigo, activo FROM dbo.roles ORDER BY nombre');
                } finally { await conn.close(); }
            })()
        ]);
        res.json({ ok: true, data: { modulos, roles } });
    } catch (err) { next(err); }
});

module.exports = router;
