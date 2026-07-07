const service = require('../services/catalogos.service');

async function obtenerCatalogos(req, res) {
    try {
        const datos = await service.obtenerCatalogos();

        res.json({
            ok: true,
            datos
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

async function obtenerDetallesPorCodigo(req, res) {
    try {
        const { codigo } = req.params;

        const datos = await service.obtenerDetallesPorCodigo(codigo);

        res.json({
            ok: true,
            catalogo: codigo.toUpperCase(),
            datos
        });
    } catch (error) {
        res.status(500).json({
            ok: false,
            mensaje: error.message
        });
    }
}

module.exports = {
    obtenerCatalogos,
    obtenerDetallesPorCodigo
};