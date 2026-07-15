const { getPool } = require('../config/db');

const CACHE_TTL_MS = 30000;
let cache = { data: null, timestamp: 0 };

async function cargarAlcances() {
    const ahora = Date.now();
    if (cache.data && (ahora - cache.timestamp) < CACHE_TTL_MS) return cache.data;

    const pool = await getPool();
    const conn = await pool.connect();
    try {
        const rows = await conn.query(`
            SELECT rad.rol_id,
                   ms.codigo AS modulo,
                   ms.codigo AS entidad,
                   rad.tipo_alcance AS alcance,
                   CONVERT(NVARCHAR(MAX), rad.configuracion_json) AS condicion_adicional
            FROM dbo.rol_alcance_datos rad
            INNER JOIN dbo.roles r ON r.id = rad.rol_id
            INNER JOIN dbo.modulos_sistema ms ON ms.id = rad.modulo_id
            WHERE r.activo = 1
            ORDER BY rad.rol_id, ms.orden_global, ms.codigo
        `);
        const map = {};
        for (const row of rows) {
            if (!map[row.rol_id]) map[row.rol_id] = {};
            map[row.rol_id][row.entidad] = {
                modulo: row.modulo,
                alcance: row.alcance,
                condicion_adicional: parseJson(row.condicion_adicional)
            };
        }
        cache = { data: map, timestamp: ahora };
        return map;
    } finally {
        await conn.close();
    }
}

async function scopeMiddleware(req, res, next) {
    try {
        const usuarioId = Number(req.user?.id);
        if (!Number.isInteger(usuarioId) || usuarioId <= 0) return next();

        const pool = await getPool();
        const conn = await pool.connect();
        try {
            const rolRow = await conn.query(
                `SELECT r.id
                 FROM dbo.personal p
                 INNER JOIN dbo.roles r ON r.id = p.rol_id
                 WHERE p.id = ? AND r.activo = 1`,
                [usuarioId]
            );
            if (!rolRow[0]) return next();

            const alcances = await cargarAlcances();
            req.dataScope = alcances[rolRow[0].id] || {};
        } finally {
            await conn.close();
        }

        next();
    } catch (err) {
        next(err);
    }
}

function getScopeFilter(entity, req) {
    const scope = req.dataScope?.[entity];
    if (!scope || scope.alcance === 'global' || scope.alcance === 'todos') return null;

    const userId = Number(req.user.id);

    switch (scope.alcance) {
        case 'propio':
            return { sql: 'id = ?', params: [userId] };
        case 'area':
        case 'unidad':
            return {
                sql: 'unidad_id IN (SELECT unidad_id FROM dbo.personal WHERE id = ?)',
                params: [userId]
            };
        case 'departamento':
            return {
                sql: 'departamento_id IN (SELECT departamento_id FROM dbo.personal WHERE id = ?)',
                params: [userId]
            };
        case 'personalizado':
            if (scope.condicion_adicional?.sql) {
                return {
                    sql: scope.condicion_adicional.sql,
                    params: scope.condicion_adicional.params || []
                };
            }
            return null;
        default:
            return null;
    }
}

function parseJson(value) {
    if (!value) return null;
    try {
        return JSON.parse(value);
    } catch (_) {
        return null;
    }
}

module.exports = { scopeMiddleware, getScopeFilter, cargarAlcances };
