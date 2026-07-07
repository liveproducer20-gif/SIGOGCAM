const { odbc, connectionString } = require('../config/db');

async function obtenerTodos(filtros = {}) {
    const conexion = await odbc.connect(connectionString);

    try {
        const mediaCols = await obtenerColumnasMedia(conexion);
        const params = [];
        let where = '';

        if (filtros.personalId) {
            where = `
                WHERE EXISTS (
                    SELECT 1
                    FROM evento_personal ep
                    WHERE ep.evento_id = e.id
                      AND ep.personal_id = ?
                )
            `;
            params.push(filtros.personalId);

            if (filtros.marcarVisto) {
                await conexion.query(`
                    UPDATE ep
                    SET fecha_actualizacion = COALESCE(ep.fecha_actualizacion, GETDATE())
                    FROM evento_personal ep
                    WHERE ep.personal_id = ?
                `, [filtros.personalId]);
            }
        }

        const sql = `
            SELECT 
                e.id,
                e.titulo,
                e.fecha_inicio,
                e.fecha_fin,
                e.lugar,
                e.descripcion,
                CASE
                    WHEN e.estado = 'CANCELADO' THEN 'CANCELADO'
                    WHEN GETDATE() BETWEEN e.fecha_inicio AND e.fecha_fin THEN 'EN_CURSO'
                    WHEN GETDATE() > e.fecha_fin THEN 'FINALIZADO'
                    ELSE 'PLANIFICADO'
                END AS estado,
                e.creado_por,
                p.nombre_completo AS creado_por_nombre,
                te.id AS tipo_evento_id,
                te.nombre AS tipo_evento,
                ee.id AS estado_evento_id,
                ee.nombre AS estado_evento,
                ${mediaCols.selectScalars}
                CASE WHEN ${mediaCols.hasColumn('imagen_url') ? "NULLIF(e.imagen_url, '') IS NULL" : '1 = 1'} THEN 0 ELSE 1 END AS tiene_imagen,
                CASE WHEN ${mediaCols.hasColumn('pdf_url') ? "NULLIF(e.pdf_url, '') IS NULL" : '1 = 1'} THEN 0 ELSE 1 END AS tiene_pdf,
                (
                    SELECT COUNT(1)
                    FROM evento_personal ep
                    WHERE ep.evento_id = e.id
                ) AS convocados,
                (
                    SELECT COUNT(1)
                    FROM evento_personal ep
                    LEFT JOIN catalogo_detalles ec ON ec.id = ep.estado_convocatoria_id
                    WHERE ep.evento_id = e.id
                      AND (
                        ep.fecha_actualizacion IS NOT NULL
                        OR UPPER(ISNULL(ec.codigo, '')) IN ('VISTO', 'CONFIRMADO', 'ASISTIO')
                      )
                ) AS confirmados,
                e.fecha_creacion,
                e.fecha_actualizacion
                ${mediaCols.selectLobs}
            FROM eventos e
            INNER JOIN catalogo_detalles te ON te.id = e.tipo_evento_id
            INNER JOIN catalogo_detalles ee ON ee.id = e.estado_evento_id
            INNER JOIN vw_personal_detalle p ON p.id = e.creado_por
            ${where}
            ORDER BY e.fecha_inicio DESC
        `;

        return await conexion.query(sql, params);
    } finally {
        await conexion.close();
    }
}

async function obtenerPorId(id) {
    const conexion = await odbc.connect(connectionString);

    try {
        const mediaCols = await obtenerColumnasMedia(conexion);
        const eventoSql = `
            SELECT 
                e.id,
                e.titulo,
                e.fecha_inicio,
                e.fecha_fin,
                e.lugar,
                e.descripcion,
                CASE
                    WHEN e.estado = 'CANCELADO' THEN 'CANCELADO'
                    WHEN GETDATE() BETWEEN e.fecha_inicio AND e.fecha_fin THEN 'EN_CURSO'
                    WHEN GETDATE() > e.fecha_fin THEN 'FINALIZADO'
                    ELSE 'PLANIFICADO'
                END AS estado,
                e.creado_por,
                p.nombre_completo AS creado_por_nombre,
                te.id AS tipo_evento_id,
                te.nombre AS tipo_evento,
                ee.id AS estado_evento_id,
                ee.nombre AS estado_evento,
                ${mediaCols.selectScalars}
                CASE WHEN ${mediaCols.hasColumn('imagen_url') ? "NULLIF(e.imagen_url, '') IS NULL" : '1 = 1'} THEN 0 ELSE 1 END AS tiene_imagen,
                CASE WHEN ${mediaCols.hasColumn('pdf_url') ? "NULLIF(e.pdf_url, '') IS NULL" : '1 = 1'} THEN 0 ELSE 1 END AS tiene_pdf,
                (
                    SELECT COUNT(1)
                    FROM evento_personal ep
                    WHERE ep.evento_id = e.id
                ) AS convocados,
                (
                    SELECT COUNT(1)
                    FROM evento_personal ep
                    LEFT JOIN catalogo_detalles ec ON ec.id = ep.estado_convocatoria_id
                    WHERE ep.evento_id = e.id
                      AND (
                        ep.fecha_actualizacion IS NOT NULL
                        OR UPPER(ISNULL(ec.codigo, '')) IN ('VISTO', 'CONFIRMADO', 'ASISTIO')
                      )
                ) AS confirmados,
                e.fecha_creacion,
                e.fecha_actualizacion
                ${mediaCols.selectLobs}
            FROM eventos e
            INNER JOIN catalogo_detalles te ON te.id = e.tipo_evento_id
            INNER JOIN catalogo_detalles ee ON ee.id = e.estado_evento_id
            INNER JOIN vw_personal_detalle p ON p.id = e.creado_por
            WHERE e.id = ?
        `;

        const personalSql = `
            SELECT 
                ep.id,
                ep.evento_id,
                ep.personal_id,
                p.cedula,
                p.nombre_completo,
                p.cargo,
                p.area,
                p.grupo,
                ep.observacion,
                ep.fecha_convocatoria,
                ep.fecha_actualizacion,
                ec.id AS estado_convocatoria_id,
                ec.nombre AS estado_convocatoria
            FROM evento_personal ep
            INNER JOIN vw_personal_detalle p ON p.id = ep.personal_id
            LEFT JOIN catalogo_detalles ec ON ec.id = ep.estado_convocatoria_id
            WHERE ep.evento_id = ?
            ORDER BY p.apellidos, p.nombres
        `;

        const evento = await conexion.query(eventoSql, [id]);
        const personal = await conexion.query(personalSql, [id]);

        return {
            evento: evento[0] || null,
            personal
        };
    } finally {
        await conexion.close();
    }
}

async function obtenerDetalleCatalogo(catalogoCodigo, detalleCodigo, conexion) {
    const sql = `
        SELECT d.id
        FROM catalogo_detalles d
        INNER JOIN catalogos c ON c.id = d.catalogo_id
        WHERE c.codigo = ?
          AND d.codigo = ?
          AND c.estado = 1
          AND d.estado = 1
    `;

    const result = await conexion.query(sql, [catalogoCodigo, detalleCodigo]);
    return result.length > 0 ? result[0].id : null;
}

async function crearEvento(data) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.beginTransaction();

        const estadoEventoId = await obtenerDetalleCatalogo(
            'ESTADOS_EVENTO',
            'PLANIFICADO',
            conexion
        );

        const estadoConvocatoriaId = await obtenerDetalleCatalogo(
            'ESTADOS_CONVOCATORIA',
            'CONVOCADO',
            conexion
        );

        if (!estadoEventoId || !estadoConvocatoriaId) {
            throw new Error('No existen catálogos requeridos para crear el evento');
        }

        const mediaCols = await obtenerColumnasMedia(conexion);
        const insertarEventoSql = `
            INSERT INTO eventos (
                titulo,
                fecha_inicio,
                fecha_fin,
                lugar,
                descripcion,
                creado_por,
                estado,
                fecha_creacion,
                tipo_evento_id,
                estado_evento_id
                ${mediaCols.insertColumns}
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, GETDATE(), ?, ?${mediaCols.insertPlaceholders})
        `;

        const eventoInsertado = await conexion.query(insertarEventoSql, [
            data.titulo,
            data.fechaInicio,
            data.fechaFin,
            data.lugar || null,
            data.descripcion || null,
            data.creadoPor,
            'PLANIFICADO',
            data.tipoEventoId,
            estadoEventoId,
            ...mediaCols.insertValues(data)
        ]);

        const eventoId = eventoInsertado[0].id;

        const personalIds = Array.isArray(data.personalIds)
            ? [...new Set(data.personalIds.map(Number).filter(Boolean))]
            : [];

        if (personalIds.length > 0) {
            const insertarPersonalSql = `
                INSERT INTO evento_personal (
                    evento_id,
                    personal_id,
                    observacion,
                    fecha_convocatoria,
                    estado_convocatoria_id
                )
                VALUES (?, ?, NULL, GETDATE(), ?)
            `;

            for (const personalId of personalIds) {
                await conexion.query(insertarPersonalSql, [
                    eventoId,
                    personalId,
                    estadoConvocatoriaId
                ]);
            }
        }

        await conexion.commit();

        return eventoId;
    } catch (error) {
        try {
            await conexion.rollback();
        } catch (_) {}

        throw error;
    } finally {
        await conexion.close();
    }
}

async function obtenerColumnasMedia(conexion) {
    const result = await conexion.query(`
        SELECT
            COL_LENGTH('eventos', 'prioridad') AS prioridad,
            COL_LENGTH('eventos', 'imagen_url') AS imagen_url,
            COL_LENGTH('eventos', 'pdf_nombre') AS pdf_nombre,
            COL_LENGTH('eventos', 'pdf_url') AS pdf_url,
            COL_LENGTH('eventos', 'notificar') AS notificar
    `);
    const row = result[0] || {};
    const columnas = [
        ['prioridad', row.prioridad],
        ['imagen_url', row.imagen_url],
        ['pdf_nombre', row.pdf_nombre],
        ['pdf_url', row.pdf_url],
        ['notificar', row.notificar]
    ].filter(([, existe]) => Boolean(existe));

    return {
        selectScalars: columnas.length > 0
            ? columnas
                .filter(([nombre]) => nombre !== 'imagen_url' && nombre !== 'pdf_url')
                .map(([nombre]) => `e.${nombre},`)
                .join('\n                ')
            : '',
        selectLobs: columnas.length > 0
            ? columnas
                .filter(([nombre]) => nombre === 'imagen_url' || nombre === 'pdf_url')
                .map(([nombre]) => `,\n                CONVERT(NVARCHAR(MAX), e.${nombre}) AS ${nombre}`)
                .join('')
            : '',
        insertColumns: columnas.length > 0
            ? `,\n                ${columnas.map(([nombre]) => nombre).join(',\n                ')}`
            : '',
        insertPlaceholders: columnas.length > 0
            ? `, ${columnas.map(() => '?').join(', ')}`
            : '',
        insertValues(data) {
            const values = {
                prioridad: data.prioridad || 'Normal',
                imagen_url: data.imagenUrl || null,
                pdf_nombre: data.pdfNombre || null,
                pdf_url: data.pdfUrl || null,
                notificar: data.notificar === false ? 0 : 1
            };

            return columnas.map(([nombre]) => values[nombre]);
        },
        hasColumn(nombre) {
            return columnas.some(([columna]) => columna === nombre);
        }
    };
}

async function cambiarEstado(id, estadoCodigo) {
    const conexion = await odbc.connect(connectionString);

    try {
        const estadoEventoId = await obtenerDetalleCatalogo(
            'ESTADOS_EVENTO',
            estadoCodigo,
            conexion
        );

        if (!estadoEventoId) {
            throw new Error('Estado de evento no válido');
        }

        const sql = `
            UPDATE eventos
            SET 
                estado = ?,
                estado_evento_id = ?,
                fecha_actualizacion = GETDATE()
            WHERE id = ?
        `;

        await conexion.query(sql, [estadoCodigo, estadoEventoId, id]);

        return true;
    } finally {
        await conexion.close();
    }
}

async function actualizarEvento(id, data) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.beginTransaction();

        const mediaCols = await obtenerColumnasMedia(conexion);
        const prioridadSet = mediaCols.hasColumn('prioridad')
            ? ', prioridad = ?'
            : '';
        const sql = `
            UPDATE eventos
            SET titulo = ?,
                tipo_evento_id = ?,
                fecha_inicio = ?,
                fecha_fin = ?,
                lugar = ?,
                descripcion = ?,
                fecha_actualizacion = GETDATE()
                ${prioridadSet}
            WHERE id = ?
        `;
        const params = [
            data.titulo,
            data.tipoEventoId,
            data.fechaInicio,
            data.fechaFin,
            data.lugar || null,
            data.descripcion || null
        ];

        if (mediaCols.hasColumn('prioridad')) {
            params.push(data.prioridad || 'Normal');
        }

        params.push(id);
        await conexion.query(sql, params);

        if (Array.isArray(data.personalIds)) {
            const estadoConvocatoriaId = await obtenerDetalleCatalogo(
                'ESTADOS_CONVOCATORIA',
                'CONVOCADO',
                conexion
            );
            const personalIds = [...new Set(data.personalIds.map(Number).filter(Boolean))];

            await conexion.query('DELETE FROM evento_personal WHERE evento_id = ?', [id]);

            if (estadoConvocatoriaId && personalIds.length > 0) {
                const insertarPersonalSql = `
                    INSERT INTO evento_personal (
                        evento_id,
                        personal_id,
                        observacion,
                        fecha_convocatoria,
                        estado_convocatoria_id
                    )
                    VALUES (?, ?, NULL, GETDATE(), ?)
                `;

                for (const personalId of personalIds) {
                    await conexion.query(insertarPersonalSql, [
                        id,
                        personalId,
                        estadoConvocatoriaId
                    ]);
                }
            }
        }

        await conexion.commit();
        return true;
    } catch (error) {
        try {
            await conexion.rollback();
        } catch (_) {}

        throw error;
    } finally {
        await conexion.close();
    }
}

async function eliminarEvento(id) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.beginTransaction();

        await conexion.query(
            'DELETE FROM evento_personal WHERE evento_id = ?',
            [id]
        );
        await conexion.query(
            'DELETE FROM eventos WHERE id = ?',
            [id]
        );

        await conexion.commit();
        return true;
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
    obtenerTodos,
    obtenerPorId,
    crearEvento,
    cambiarEstado,
    actualizarEvento,
    eliminarEvento
};
