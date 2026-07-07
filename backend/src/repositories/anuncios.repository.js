const { odbc, connectionString } = require('../config/db');

async function obtenerTodos(filtros = {}) {
    const conexion = await odbc.connect(connectionString);

    try {
        const params = [];
        let where = '';

        if (filtros.personalId) {
            where = `
                WHERE EXISTS (
                    SELECT 1
                    FROM anuncio_personal ap
                    WHERE ap.anuncio_id = a.id
                      AND ap.personal_id = ?
                )
            `;
            params.push(filtros.personalId);
        }

        const sql = `
            SELECT
                a.id,
                a.titulo,
                a.prioridad,
                a.imagen_nombre,
                CASE WHEN NULLIF(a.imagen_url, '') IS NULL THEN 0 ELSE 1 END AS tiene_imagen,
                a.fecha_publicacion,
                a.fecha_expiracion,
                a.publicado,
                a.notificar,
                a.creado_por,
                STUFF((
                    SELECT ',' + CONVERT(NVARCHAR(20), ap.personal_id)
                    FROM anuncio_personal ap
                    WHERE ap.anuncio_id = a.id
                    FOR XML PATH(''), TYPE
                ).value('.', 'NVARCHAR(4000)'), 1, 1, '') AS personal_ids
                ,
                CONVERT(NVARCHAR(MAX), a.descripcion) AS descripcion,
                CONVERT(NVARCHAR(MAX), a.imagen_url) AS imagen_url
            FROM anuncios a
            ${where}
            ORDER BY a.fecha_publicacion DESC, a.id DESC
        `;

        return await conexion.query(sql, params);
    } finally {
        await conexion.close();
    }
}

async function crear(data) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.beginTransaction();

        const result = await conexion.query(`
            INSERT INTO anuncios (
                titulo,
                descripcion,
                prioridad,
                imagen_nombre,
                imagen_url,
                fecha_publicacion,
                fecha_expiracion,
                publicado,
                notificar,
                creado_por
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, GETDATE(), ?, ?, ?, ?)
        `, [
            data.titulo,
            data.descripcion,
            data.prioridad || 'Normal',
            data.imagenNombre || null,
            data.imagenUrl || null,
            data.fechaExpiracion || null,
            data.publicado === false ? 0 : 1,
            data.notificar === false ? 0 : 1,
            data.creadoPor || null
        ]);

        const id = result[0].id;
        await guardarPersonal(conexion, id, data.personalIds);
        await conexion.commit();
        return id;
    } catch (error) {
        try {
            await conexion.rollback();
        } catch (_) {}
        throw error;
    } finally {
        await conexion.close();
    }
}

async function actualizar(id, data) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.beginTransaction();

        await conexion.query(`
            UPDATE anuncios
            SET titulo = ?,
                descripcion = ?,
                prioridad = ?,
                imagen_nombre = ?,
                imagen_url = ?,
                fecha_expiracion = ?,
                publicado = ?,
                notificar = ?,
                fecha_actualizacion = GETDATE()
            WHERE id = ?
        `, [
            data.titulo,
            data.descripcion,
            data.prioridad || 'Normal',
            data.imagenNombre || null,
            data.imagenUrl || null,
            data.fechaExpiracion || null,
            data.publicado === false ? 0 : 1,
            data.notificar === false ? 0 : 1,
            id
        ]);

        await guardarPersonal(conexion, id, data.personalIds);
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

async function cambiarPublicado(id, publicado) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.query(`
            UPDATE anuncios
            SET publicado = ?,
                fecha_actualizacion = GETDATE()
            WHERE id = ?
        `, [publicado ? 1 : 0, id]);
        return true;
    } finally {
        await conexion.close();
    }
}

async function eliminar(id) {
    const conexion = await odbc.connect(connectionString);

    try {
        await conexion.query('DELETE FROM anuncios WHERE id = ?', [id]);
        return true;
    } finally {
        await conexion.close();
    }
}

async function guardarPersonal(conexion, anuncioId, personalIds) {
    await conexion.query('DELETE FROM anuncio_personal WHERE anuncio_id = ?', [anuncioId]);

    const ids = Array.isArray(personalIds)
        ? [...new Set(personalIds.map(Number).filter(Boolean))]
        : [];

    for (const personalId of ids) {
        await conexion.query(`
            INSERT INTO anuncio_personal (anuncio_id, personal_id)
            VALUES (?, ?)
        `, [anuncioId, personalId]);
    }
}

module.exports = {
    obtenerTodos,
    crear,
    actualizar,
    cambiarPublicado,
    eliminar
};
