const service = require('../services/cartillas.service');

async function obtenerCatalogosOperativos(req, res) {
    try {
        const datos = await service.obtenerCatalogosOperativos();
        res.json({ ok: true, datos });
    } catch (error) {
        res.status(500).json({ ok: false, mensaje: error.message });
    }
}

async function registrarCartilla(req, res) {
    try {
        const datos = await service.registrarCartilla({
            ...req.body,
            usuarioId: req.user?.id,
            usuarioRol: req.user?.rol
        });

        res.status(201).json({
            ok: true,
            mensaje: 'Cartilla generada correctamente',
            cartillaId: datos.cartillaId,
            total_cartillas_generadas: datos.total_cartillas_generadas,
            insignia_desbloqueada: datos.insignia_desbloqueada,
            advertencia: datos.advertencia || null
        });
    } catch (error) {
        res.status(400).json({
            ok: false,
            mensaje: error.message,
            detalle: error.odbcErrors || error
        });
    }
}

module.exports = {
    registrarCartilla,
    obtenerCatalogosOperativos
};
