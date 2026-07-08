const { getPool } = require('../config/db');

async function withConnection(callback) {
    const pool = await getPool();
    const conexion = await pool.connect();
    try {
        return await callback(conexion);
    } finally {
        await conexion.close();
    }
}

async function obtenerCp(usuarioId) {
    return withConnection(async (conexion) => {
        const result = await conexion.query(`
            SELECT TOP 1 id, nombre_cp, fecha_creacion
            FROM dbo.cartilla_temp_cp
            WHERE usuario_id = ?
              AND fecha_creacion >= DATEADD(HOUR, -8, SYSDATETIME())
            ORDER BY fecha_creacion DESC
        `, [usuarioId]);
        if (result.length === 0) return null;
        return result[0];
    });
}

async function guardarCp(usuarioId, nombreCp) {
    return withConnection(async (conexion) => {
        try {
            await conexion.query('DELETE FROM dbo.cartilla_temp_cp WHERE usuario_id = ?', [usuarioId]);
        } catch (e) {
            console.error('[guardarCp] DELETE error:', e.message);
            throw e;
        }
        try {
            const result = await conexion.query(`
                INSERT INTO dbo.cartilla_temp_cp (usuario_id, nombre_cp)
                OUTPUT INSERTED.id
                VALUES (?, ?)
            `, [usuarioId, nombreCp]);
            return result[0].id;
        } catch (e) {
            console.error('[guardarCp] INSERT error:', e.message);
            throw e;
        }
    });
}

async function obtenerPolicia(usuarioId) {
    return withConnection(async (conexion) => {
        const result = await conexion.query(`
            SELECT TOP 1 cp.id, cp.servidor_policial_id, sp.nombre AS servidor_nombre
            FROM dbo.cartilla_temp_policia cp
            LEFT JOIN dbo.servidores_policiales sp ON sp.id = cp.servidor_policial_id
            WHERE cp.usuario_id = ?
              AND cp.fecha_creacion >= DATEADD(HOUR, -8, SYSDATETIME())
            ORDER BY cp.fecha_creacion DESC
        `, [usuarioId]);
        if (result.length === 0) return null;
        return result[0];
    });
}

async function guardarPolicia(usuarioId, servidorPolicialId) {
    return withConnection(async (conexion) => {
        await conexion.query('DELETE FROM dbo.cartilla_temp_policia WHERE usuario_id = ?', [usuarioId]);
        const policialId = servidorPolicialId && Number(servidorPolicialId) > 0 ? Number(servidorPolicialId) : null;
        const result = await conexion.query(`
            INSERT INTO dbo.cartilla_temp_policia (usuario_id, servidor_policial_id)
            OUTPUT INSERTED.id
            VALUES (?, ?)
        `, [usuarioId, policialId]);
        return result[0].id;
    });
}

async function listarServidoresPoliciales(easId) {
    return withConnection((conexion) => conexion.query(`
        SELECT id, nombre
        FROM dbo.servidores_policiales
        WHERE eas_id = ? AND activo = 1
        ORDER BY id
    `, [easId]));
}

async function crearServidorPolicial(easId, nombre) {
    return withConnection(async (conexion) => {
        const existing = await conexion.query(`
            SELECT id FROM dbo.servidores_policiales
            WHERE eas_id = ? AND nombre = ? AND activo = 1
        `, [easId, nombre]);
        if (existing.length > 0) {
            return existing[0].id;
        }
        const result = await conexion.query(`
            INSERT INTO dbo.servidores_policiales (eas_id, nombre)
            OUTPUT INSERTED.id
            VALUES (?, ?)
        `, [easId, nombre]);
        return result[0].id;
    });
}

async function listarDireccionesPorEas(easId) {
    return withConnection((conexion) => conexion.query(`
        SELECT id, eas_id, direccion
        FROM dbo.eas_direcciones
        WHERE eas_id = ? AND activo = 1
        ORDER BY id
    `, [easId]));
}

async function crearDireccion(easId, direccion) {
    return withConnection(async (conexion) => {
        const existing = await conexion.query(`
            SELECT id FROM dbo.eas_direcciones
            WHERE eas_id = ? AND direccion = ? AND activo = 1
        `, [easId, direccion]);
        if (existing.length > 0) {
            return existing[0].id;
        }
        const result = await conexion.query(`
            INSERT INTO dbo.eas_direcciones (eas_id, direccion)
            OUTPUT INSERTED.id
            VALUES (?, ?)
        `, [easId, direccion]);
        return result[0].id;
    });
}

module.exports = {
    obtenerCp,
    guardarCp,
    obtenerPolicia,
    guardarPolicia,
    listarServidoresPoliciales,
    crearServidorPolicial,
    listarDireccionesPorEas,
    crearDireccion
};
