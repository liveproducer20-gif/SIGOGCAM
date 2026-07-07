const { odbc, connectionString } = require('../config/db');

async function obtenerTodas() {
    const conexion = await odbc.connect(connectionString);

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
    const conexion = await odbc.connect(connectionString);

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
    const conexion = await odbc.connect(connectionString);

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

        const next = proxima[0] || null;
        const metaProxima = next ? Number(next.meta_cartillas) : null;
        const faltantes = metaProxima === null
            ? 0
            : Math.max(metaProxima - total, 0);
        const porcentaje = metaProxima === null
            ? 100
            : Math.min(100, Math.floor((total / metaProxima) * 100));

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

module.exports = {
    obtenerTodas,
    obtenerUsuarioInsignias,
    obtenerProgreso
};
