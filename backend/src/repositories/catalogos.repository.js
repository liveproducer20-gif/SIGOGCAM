const { getPool } = require('../config/db');

async function obtenerCatalogos() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT id, codigo, nombre
            FROM catalogos
            WHERE estado = 1
            ORDER BY nombre
        `;

        return await conexion.query(sql);
    } finally {
        await conexion.close();
    }
}

async function obtenerDetallesPorCodigo(codigo) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT 
                d.id,
                d.codigo,
                d.nombre,
                d.descripcion,
                d.orden
            FROM catalogo_detalles d
            INNER JOIN catalogos c ON c.id = d.catalogo_id
            WHERE c.codigo = ?
              AND c.estado = 1
              AND d.estado = 1
            ORDER BY d.orden, d.nombre
        `;

        return await conexion.query(sql, [codigo]);
    } finally {
        await conexion.close();
    }
}

module.exports = {
    obtenerCatalogos,
    obtenerDetallesPorCodigo
};