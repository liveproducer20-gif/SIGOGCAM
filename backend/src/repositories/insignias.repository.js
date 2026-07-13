const { getPool } = require('../config/db');

async function obtenerTodas() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        return await conexion.query(`
            SELECT
                id,
                codigo,
                titulo,
                descripcion,
                meta_cartillas,
                categoria,
                icono,
                activo,
                fecha_creacion
            FROM insignias
            WHERE activo = 1
            ORDER BY meta_cartillas
        `);
    } finally {
        await conexion.close();
    }
}

async function obtenerUsuarioInsignias(usuarioId) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        return await conexion.query(`
            SELECT
                i.id,
                i.codigo,
                i.titulo,
                i.descripcion,
                i.meta_cartillas,
                i.categoria,
                i.icono,
                ui.total_cartillas_al_desbloquear,
                ui.fecha_desbloqueo
            FROM usuario_insignias ui
            INNER JOIN insignias i ON i.id = ui.insignia_id
            WHERE ui.usuario_id = ?
            ORDER BY i.meta_cartillas
        `, [usuarioId]);
    } finally {
        await conexion.close();
    }
}

async function obtenerProgreso(usuarioId) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const usuarios = await conexion.query(`
            SELECT ISNULL(total_cartillas_generadas, 0) AS total_cartillas_generadas
            FROM personal
            WHERE id = ?
        `, [usuarioId]);

        if (usuarios.length === 0) {
            return null;
        }

        const total = Number(usuarios[0].total_cartillas_generadas || 0);
        const ultima = await conexion.query(`
            SELECT TOP 1 i.titulo, i.meta_cartillas
            FROM usuario_insignias ui
            INNER JOIN insignias i ON i.id = ui.insignia_id
            WHERE ui.usuario_id = ?
            ORDER BY ui.fecha_desbloqueo DESC, i.meta_cartillas DESC
        `, [usuarioId]);
        const proxima = await conexion.query(`
            SELECT TOP 1 titulo, meta_cartillas
            FROM insignias
            WHERE activo = 1
              AND meta_cartillas > ?
            ORDER BY meta_cartillas
        `, [total]);
        const anterior = await conexion.query(`
            SELECT TOP 1 titulo, meta_cartillas
            FROM insignias
            WHERE activo = 1
              AND meta_cartillas <= ?
            ORDER BY meta_cartillas DESC
        `, [total]);

        const next = proxima[0] || null;
        const metaProxima = next ? Number(next.meta_cartillas) : null;
        const metaAnterior = Number(anterior[0]?.meta_cartillas || 0);
        const faltantes = metaProxima === null
            ? 0
            : Math.max(metaProxima - total, 0);
        const porcentaje = metaProxima === null
            ? 100
            : Math.max(0, Math.min(100, Math.floor(
                ((total - metaAnterior) / Math.max(metaProxima - metaAnterior, 1)) * 100
            )));

        return {
            total_cartillas_generadas: total,
            ultima_insignia: ultima[0]?.titulo || null,
            proxima_insignia: next?.titulo || null,
            meta_proxima: metaProxima,
            cartillas_faltantes: faltantes,
            porcentaje_progreso: porcentaje
        };
    } finally {
        await conexion.close();
    }
}

async function obtenerRanking() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        return await conexion.query(`
            SELECT TOP 10
                p.id,
                p.nombres,
                p.apellidos,
                ISNULL(p.total_cartillas_generadas, 0) AS total_cartillas_generadas,
                actual.titulo AS insignia_titulo,
                actual.meta_cartillas AS insignia_meta,
                actual.categoria AS insignia_categoria,
                siguiente.meta_cartillas AS proxima_meta
            FROM personal p
            OUTER APPLY (
                SELECT TOP 1 i.titulo, i.meta_cartillas, i.categoria
                FROM insignias i
                WHERE i.activo = 1
                  AND i.meta_cartillas <= ISNULL(p.total_cartillas_generadas, 0)
                ORDER BY i.meta_cartillas DESC
            ) actual
            OUTER APPLY (
                SELECT TOP 1 i.meta_cartillas
                FROM insignias i
                WHERE i.activo = 1
                  AND i.meta_cartillas > ISNULL(p.total_cartillas_generadas, 0)
                ORDER BY i.meta_cartillas
            ) siguiente
            WHERE p.activo = 1
            ORDER BY ISNULL(p.total_cartillas_generadas, 0) DESC,
                     p.apellidos,
                     p.nombres
        `);
    } finally {
        await conexion.close();
    }
}

module.exports = {
    obtenerTodas,
    obtenerUsuarioInsignias,
    obtenerProgreso,
    obtenerRanking
};
