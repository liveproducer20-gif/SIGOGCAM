const service = require('../services/cartillas.service');

async function registrarCartilla(req, res) {
    try {
        const datos = await service.registrarCartilla({
            ...req.body,
            usuarioId: req.user?.id
        });

        res.status(201).json({
            ok: true,
            mensaje: 'Cartilla generada correctamente',
            cartillaId: datos.cartillaId,
            total_cartillas_generadas: datos.total_cartillas_generadas,
            insignia_desbloqueada: datos.insignia_desbloqueada
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
    registrarCartilla
};
