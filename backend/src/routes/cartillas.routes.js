const express = require('express');
const router = express.Router();

const controller = require('../controllers/cartillas.controller');
const adminRepo = require('../repositories/admin.repository');
const {
    requireAuth,
    requirePermission,
    requireAnyPermission
} = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.get(
    '/jefe-control-municipal',
    requireAnyPermission(['personal.ver', 'cartillas.generar']),
    async (req, res) => {
        try {
            const jefe = await adminRepo.obtenerJefeControlMunicipal();
            res.json({ ok: true, datos: jefe });
        } catch (error) {
            console.error('Error al obtener Jefe de Control Municipal:', error.message);
            res.status(500).json({ ok: false, mensaje: error.message });
        }
    }
);

router.post(
    '/',
    requirePermission('cartillas.generar'),
    auditAction({ accion: 'generar', modulo: 'cartillas', tabla: 'cartillas_generadas' }),
    controller.registrarCartilla
);

module.exports = router;
