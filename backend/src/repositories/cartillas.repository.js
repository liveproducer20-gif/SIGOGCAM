const { getPool } = require('../config/db');

async function registrarCartilla(data) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        await conexion.beginTransaction();

        const columnas = await columnasCartillas(conexion);
        let advertencia = null;
        let entradaRelacionadaId = null;
        if (columnas.has('datos_json') && data.tipo === 'CONDUCTOR' && data.datos) {
            if (data.subtipo === 'ENTRADA_PERSONAL') {
                data.datos.estado_registro = 'ABIERTO';
            } else if (data.subtipo === 'SALIDA_PERSONAL') {
                const entradas = await conexion.query(`
                    SELECT TOP 1 id, datos_json
                    FROM dbo.cartillas_generadas WITH (UPDLOCK, HOLDLOCK)
                    WHERE tipo = 'CONDUCTOR'
                      AND subtipo = 'ENTRADA_PERSONAL'
                      AND JSON_VALUE(datos_json, '$.numero_disco') = ?
                      AND ISNULL(JSON_VALUE(datos_json, '$.estado_registro'), 'ABIERTO') = 'ABIERTO'
                    ORDER BY fecha_creacion DESC
                `, [data.datos.numero_disco]);
                if (entradas.length === 0) {
                    advertencia = 'No existe una entrada abierta previa para este móvil; la salida se registró manualmente.';
                    data.datos.salida_manual = true;
                } else {
                    const entrada = JSON.parse(entradas[0].datos_json || '{}');
                    const inicial = Number(entrada.kilometraje);
                    const final = Number(data.datos.kilometraje);
                    if (Number.isFinite(inicial) && final < inicial) {
                        throw new Error(`El kilometraje final no puede ser menor al inicial (${inicial} Km)`);
                    }
                    entradaRelacionadaId = Number(entradas[0].id);
                    data.datos.entrada_id = entradaRelacionadaId;
                    data.datos.kilometraje_recorrido = Number.isFinite(inicial) ? final - inicial : null;
                }
            }
        }
        const nombres = ['usuario_id', 'causa', 'contenido', 'fecha_creacion'];
        const valores = [data.usuarioId, data.causa || null, data.contenido];
        const marcas = ['?', '?', '?', 'GETDATE()'];
        if (columnas.has('tipo')) {
            nombres.splice(3, 0, 'tipo', 'subtipo', 'datos_json');
            valores.push(data.tipo || null, data.subtipo || null,
                data.datos ? JSON.stringify(data.datos) : null);
            marcas.splice(3, 0, '?', '?', '?');
        }

        const insertadas = await conexion.query(`
            INSERT INTO cartillas_generadas (
                ${nombres.join(', ')}
            )
            OUTPUT INSERTED.id
            VALUES (${marcas.join(', ')})
        `, valores);

        if (entradaRelacionadaId) {
            await conexion.query(`
                UPDATE dbo.cartillas_generadas
                SET datos_json = JSON_MODIFY(
                    JSON_MODIFY(datos_json, '$.estado_registro', 'CERRADO'),
                    '$.salida_id', ?
                ),
                fecha_actualizacion = SYSDATETIME()
                WHERE id = ?
            `, [insertadas[0].id, entradaRelacionadaId]);
        }

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
            insignia_desbloqueada: insigniaDesbloqueada,
            advertencia
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

async function columnasCartillas(conexion) {
    const rows = await conexion.query(`
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'cartillas_generadas'
    `);
    return new Set(rows.map((row) => row.COLUMN_NAME || row.column_name));
}

async function obtenerCatalogosOperativos() {
    const pool = await getPool();
    const conexion = await pool.connect();
    try {
        const [personal, moviles] = await Promise.all([
            conexion.query(`
                SELECT p.id, p.nombres, p.apellidos,
                       LTRIM(RTRIM(CONCAT(ISNULL(g.nombre + ' ', ''), p.nombres, ' ', p.apellidos))) AS nombre_completo
                FROM dbo.personal p
                LEFT JOIN dbo.grados g ON g.id = p.grado_id
                WHERE ISNULL(p.activo, 1) = 1
                ORDER BY p.apellidos, p.nombres
            `),
            conexion.query(`
                SELECT id, numero_movil, placa, kilometraje_actual
                FROM dbo.moviles
                WHERE ISNULL(activo, 1) = 1
                ORDER BY numero_movil
            `)
        ]);
        return { personal, moviles };
    } finally {
        await conexion.close();
    }
}

module.exports = {
    registrarCartilla,
    obtenerCatalogosOperativos
};
