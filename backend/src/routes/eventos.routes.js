const express = require('express');
const router = express.Router();

const controller = require('../controllers/eventos.controller');
const {
    requireAuth,
    requirePermission,
    requireAnyPermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.post(
    '/archivos',
    requirePermission('eventos.crear'),
    express.raw({ type: ['image/png', 'image/jpeg', 'image/webp', 'application/pdf'], limit: '10mb' }),
    controller.subirArchivo
);

router.get(
    '/',
    requireAnyPermission(['eventos.ver', 'eventos.ver_convocado']),
    controller.obtenerTodos
);
router.get(
    '/:id',
    requireAnyPermission(['eventos.ver', 'eventos.ver_convocado']),
    controller.obtenerPorId
);
router.post(
    '/',
    requirePermission('eventos.crear'),
    auditAction({ accion: 'crear', modulo: 'eventos', tabla: 'eventos' }),
    controller.crearEvento
);
router.put(
    '/:id',
    requirePermission('eventos.editar'),
    auditAction({ accion: 'editar', modulo: 'eventos', tabla: 'eventos' }),
    controller.actualizarEvento
);
router.put(
    '/:id/estado',
    requirePermission('eventos.editar'),
    auditAction({ accion: 'cambiar_estado', modulo: 'eventos', tabla: 'eventos' }),
    controller.cambiarEstado
);
router.delete(
    '/:id',
    requirePermission('eventos.eliminar'),
    auditAction({ accion: 'eliminar', modulo: 'eventos', tabla: 'eventos' }),
    controller.eliminarEvento
);

module.exports = router;
