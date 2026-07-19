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
    '/catalogos-operativos',
    requireAnyPermission(['cartillas.ver', 'cartillas.generar']),
    controller.obtenerCatalogosOperativos
);

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

router.get(
    '/asignaciones-eas-moviles',
    requireAnyPermission(['cartillas.ver', 'cartillas.generar']),
    async (req, res) => {
        try {
            const { withConnection } = require('../db');
            const rows = await withConnection((conexion) => conexion.query(`
                SELECT e.codigo AS eas_codigo, e.nombre AS eas,
                       m.numero_movil, a.activo
                FROM dbo.movil_eas_asignaciones a
                INNER JOIN dbo.eas_estaciones e ON e.id = a.eas_id
                INNER JOIN dbo.moviles m ON m.id = a.movil_id
                WHERE a.activo = 1
                ORDER BY e.codigo, m.numero_movil
            `));
            res.json({ ok: true, datos: rows });
        } catch (error) {
            console.error('Error al obtener asignaciones EAS-Moviles:', error.message);
            res.status(500).json({ ok: false, mensaje: error.message });
        }
    }
);

module.exports = router;
