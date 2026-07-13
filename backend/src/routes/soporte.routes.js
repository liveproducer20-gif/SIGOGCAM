const express = require('express');
const router = express.Router();
const controller = require('../controllers/soporte.controller');
const realtime = require('../support-realtime');
const { requireAuth } = require('../middleware/auth.middleware');

router.use(requireAuth);
router.get('/stream', realtime.subscribe);
router.post('/imagenes', express.raw({ type: ['image/png', 'image/jpeg', 'image/webp'], limit: '5mb' }), controller.subirImagen);
router.get('/estadisticas', controller.estadisticas);
router.get('/', controller.listar);
router.post('/', controller.crear);
router.get('/:id', controller.detalle);
router.put('/:id', controller.actualizar);
router.post('/:id/comentarios', controller.comentar);

module.exports = router;

