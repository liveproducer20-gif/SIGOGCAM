const express = require('express');
const router = express.Router();

const controller = require('../controllers/catalogos.controller');

router.get('/', controller.obtenerCatalogos);
router.get('/:codigo', controller.obtenerDetallesPorCodigo);

module.exports = router;