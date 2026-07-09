const express = require('express');
const router = express.Router();

const controller = require('../controllers/anuncios.controller');
const {
    requireAuth,
    requireAnyPermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.get(
    '/',
    requireAuth,
    requireAnyPermission(['anuncios.ver', 'eventos.ver', 'eventos.ver_convocado']),
    controller.obtenerTodos
);

router.post(
    '/',
    requireAuth,
    requireAnyPermission(['anuncios.crear', 'eventos.crear']),
    auditAction({ accion: 'crear', modulo: 'anuncios', tabla: 'anuncios' }),
    controller.crear
);

router.put(
    '/:id',
    requireAuth,
    requireAnyPermission(['anuncios.editar', 'eventos.editar']),
    auditAction({ accion: 'editar', modulo: 'anuncios', tabla: 'anuncios' }),
    controller.actualizar
);

router.put(
    '/:id/publicado',
    requireAuth,
    requireAnyPermission(['anuncios.editar', 'eventos.editar']),
    auditAction({ accion: 'publicar', modulo: 'anuncios', tabla: 'anuncios' }),
    controller.cambiarPublicado
);

router.delete(
    '/:id',
    requireAuth,
    requireAnyPermission(['anuncios.eliminar', 'eventos.eliminar']),
    auditAction({ accion: 'eliminar', modulo: 'anuncios', tabla: 'anuncios' }),
    controller.eliminar
);

module.exports = router;
