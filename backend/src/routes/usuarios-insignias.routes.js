const express = require('express');
const router = express.Router();

const controller = require('../controllers/insignias.controller');
const { requireAuth } = require('../middleware/auth.middleware');

router.use(requireAuth);

router.get('/:id/insignias', controller.obtenerUsuarioInsignias);
router.get('/:id/progreso-insignias', controller.obtenerProgreso);

module.exports = router;
