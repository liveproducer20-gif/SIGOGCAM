const express = require('express');
const router = express.Router();

const controller = require('../controllers/insignias.controller');
const { requireAuth } = require('../middleware/auth.middleware');

router.use(requireAuth);

router.get('/', controller.obtenerTodas);

module.exports = router;
