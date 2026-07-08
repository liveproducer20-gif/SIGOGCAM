const express = require('express');
const router = express.Router();

const controller = require('../controllers/cartilla-flow.controller');
const { requireAuth, requirePermission } = require('../middleware/auth.middleware');
const { auditAction } = require('../middleware/audit.middleware');

router.use(requireAuth);

router.get('/temp/cp', controller.obtenerCp);
router.put('/temp/cp',
    auditAction({ accion: 'guardar_cp_temp', modulo: 'cartillas', tabla: 'cartilla_temp_cp' }),
    controller.guardarCp
);

router.get('/temp/policia', controller.obtenerPolicia);
router.put('/temp/policia',
    auditAction({ accion: 'guardar_policia_temp', modulo: 'cartillas', tabla: 'cartilla_temp_policia' }),
    controller.guardarPolicia
);

router.get('/servidores-policiales', controller.listarServidoresPoliciales);

router.get('/eas-direcciones', controller.listarDirecciones);
router.post('/eas-direcciones',
    auditAction({ accion: 'crear_direccion', modulo: 'cartillas', tabla: 'eas_direcciones' }),
    controller.crearDireccion
);

module.exports = router;
