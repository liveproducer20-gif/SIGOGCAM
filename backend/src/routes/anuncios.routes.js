const express = require('express');
const controller = require('../controllers/anuncios.controller');
const {
    requireAuth,
    requirePermission,
    requireAnyPermission
} = require('../middleware/auth.middleware');

const router = express.Router();

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
    controller.crear
);

router.put(
    '/:id',
    requireAuth,
    requireAnyPermission(['anuncios.editar', 'eventos.editar']),
    controller.actualizar
);

router.put(
    '/:id/publicado',
    requireAuth,
    requireAnyPermission(['anuncios.editar', 'eventos.editar']),
    controller.cambiarPublicado
);

router.delete(
    '/:id',
    requireAuth,
    requireAnyPermission(['anuncios.eliminar', 'eventos.eliminar']),
    controller.eliminar
);

module.exports = router;
