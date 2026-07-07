const { getPool } = require('../config/db');

async function registrarCartilla(data) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        await conexion.beginTransaction();

        const insertadas = await conexion.query(`
            INSERT INTO cartillas_generadas (
                usuario_id,
                causa,
                contenido,
                fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, GETDATE())
        `, [
            data.usuarioId,
            data.causa || null,
            data.contenido
        ]);

        const actualizados = await conexion.query(`
            UPDATE personal
            SET total_cartillas_generadas = ISNULL(total_cartillas_generadas, 0) + 1
            OUTPUT INSERTED.total_cartillas_generadas
            WHERE id = ?
        `, [data.usuarioId]);

        if (actualizados.length === 0) {
            throw new Error('Usuario no encontrado');
        }

        const total = Number(actualizados[0].total_cartillas_generadas || 0);
        const insignias = await conexion.query(`
            SELECT TOP 1 id, titulo, descripcion, icono
            FROM insignias
            WHERE activo = 1
              AND meta_cartillas = ?
            ORDER BY id
        `, [total]);

        let insigniaDesbloqueada = null;

        if (insignias.length > 0) {
            const insignia = insignias[0];
            const existentes = await conexion.query(`
                SELECT TOP 1 id
                FROM usuario_insignias
                WHERE usuario_id = ?
                  AND insignia_id = ?
            `, [data.usuarioId, insignia.id]);

            if (existentes.length === 0) {
                await conexion.query(`
                    INSERT INTO usuario_insignias (
                        usuario_id,
                        insignia_id,
                        total_cartillas_al_desbloquear,
                        fecha_desbloqueo
                    )
                    VALUES (?, ?, ?, GETDATE())
                `, [data.usuarioId, insignia.id, total]);

                insigniaDesbloqueada = {
                    titulo: insignia.titulo,
                    mensaje: insignia.descripcion,
                    icono: insignia.icono
                };
            }
        }

        await conexion.commit();

        return {
            cartillaId: insertadas[0].id,
            total_cartillas_generadas: total,
            insignia_desbloqueada: insigniaDesbloqueada
        };
    } catch (error) {
        try {
            await conexion.rollback();
        } catch (_) {}

        throw error;
    } finally {
        await conexion.close();
    }
}

module.exports = {
    registrarCartilla
};
