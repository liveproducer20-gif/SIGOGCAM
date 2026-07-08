const express = require('express');
const router = express.Router();

const controller = require('../controllers/personal.controller');
const {
    requireAuth,
    requirePermission,
    requireAnyPermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.get(
    '/perfil/me',
    controller.obtenerMiPerfil
);
router.put(
    '/perfil/me',
    auditAction({ accion: 'actualizar_perfil', modulo: 'personal', tabla: 'personal' }),
    controller.actualizarMiPerfil
);
router.get(
    '/operativos',
    requireAnyPermission(['personal.ver', 'eventos.convocar', 'eventos.crear']),
    controller.obtenerOperativos
);
router.get(
    '/disponibles',
    requireAnyPermission(['personal.ver', 'eventos.convocar', 'eventos.crear']),
    controller.obtenerDisponibles
);
router.get(
    '/disponibles-sin-evento',
    requireAnyPermission(['personal.ver', 'eventos.convocar', 'eventos.crear']),
    controller.obtenerDisponiblesSinEvento
);
router.get(
    '/buscar',
    requirePermission('personal.ver'),
    controller.buscar
);
router.get(
    '/',
    requirePermission('personal.ver'),
    controller.obtenerTodo
);
router.post(
    '/',
    requirePermission('personal.crear'),
    auditAction({ accion: 'crear', modulo: 'personal', tabla: 'personal' }),
    controller.crear
);
router.put(
    '/:id',
    requirePermission('personal.editar'),
    auditAction({ accion: 'editar', modulo: 'personal', tabla: 'personal' }),
    controller.actualizar
);
router.put(
    '/:id/estado',
    requireAnyPermission(['personal.editar', 'personal.editar_estado']),
    auditAction({ accion: 'estado', modulo: 'personal', tabla: 'personal' }),
    controller.cambiarEstado
);
router.delete(
    '/:id',
    requirePermission('personal.editar'),
    auditAction({ accion: 'eliminar', modulo: 'personal', tabla: 'personal' }),
    controller.eliminar
);
router.post(
    '/:id/reset-password',
    requirePermission('personal.reset_password'),
    auditAction({ accion: 'reset_password', modulo: 'personal', tabla: 'personal' }),
    controller.restablecerPassword
);

module.exports = router;
