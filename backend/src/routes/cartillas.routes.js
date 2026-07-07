const express = require('express');
const router = express.Router();

const controller = require('../controllers/cartillas.controller');
const {
    requireAuth,
    requirePermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.post(
    '/',
    requirePermission('cartillas.generar'),
    auditAction({ accion: 'generar', modulo: 'cartillas', tabla: 'cartillas_generadas' }),
    controller.registrarCartilla
);

module.exports = router;
