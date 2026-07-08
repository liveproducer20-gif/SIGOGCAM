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

async function listarCatalogos() {
    return withConnection((conexion) => conexion.query(`
        SELECT c.id, c.codigo, c.nombre, c.descripcion, c.estado,
               COUNT(d.id) AS total_detalles
        FROM dbo.catalogos c
        LEFT JOIN dbo.catalogo_detalles d ON d.catalogo_id = c.id
        GROUP BY c.id, c.codigo, c.nombre, c.descripcion, c.estado
        ORDER BY c.nombre
    `));
}

async function listarDetalles(codigo, incluirInactivos = false) {
    return withConnection((conexion) => listarDetallesConConexion(
        conexion,
        codigo,
        incluirInactivos
    ));
}

async function listarDetallesConConexion(conexion, codigo, incluirInactivos = false) {
    const sql = `
        SELECT d.id, d.codigo, d.nombre, d.descripcion, d.orden, d.estado
        FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
        WHERE c.codigo = ?
          ${incluirInactivos ? '' : 'AND d.estado = 1'}
        ORDER BY d.orden, d.nombre
    `;
    return conexion.query(sql, [codigo]);
}

async function crearDetalle(codigoCatalogo, data) {
    return withConnection(async (conexion) => {
        const catalogo = await obtenerCatalogo(conexion, codigoCatalogo);
        const result = await conexion.query(`
            INSERT INTO dbo.catalogo_detalles (
                catalogo_id, codigo, nombre, descripcion, orden, estado
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, 1)
        `, [
            catalogo.id,
            data.codigo,
            data.nombre,
            data.descripcion,
            data.orden
        ]);

        return result[0].id;
    });
}

async function actualizarDetalle(id, data) {
    return withConnection(async (conexion) => {
        await conexion.query(`
            UPDATE dbo.catalogo_detalles
            SET codigo = ?,
                nombre = ?,
                descripcion = ?,
                orden = ?,
                fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
        `, [data.codigo, data.nombre, data.descripcion, data.orden, id]);

        return obtenerDetallePorId(conexion, id);
    });
}

async function cambiarEstadoDetalle(id, estado) {
    return withConnection(async (conexion) => {
        await conexion.query(`
            UPDATE dbo.catalogo_detalles
            SET estado = ?,
                fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
        `, [estado ? 1 : 0, id]);
        return obtenerDetallePorId(conexion, id);
    });
}

async function listarRoles() {
    return withConnection((conexion) => conexion.query(`
        SELECT r.id, r.nombre, r.descripcion, r.activo,
               STUFF((
                   SELECT ',' + p.codigo
                   FROM dbo.rol_permiso rp
                   INNER JOIN dbo.permisos p ON p.id = rp.permiso_id
                   WHERE rp.rol_id = r.id
                   ORDER BY p.codigo
                   FOR XML PATH(''), TYPE
               ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS permisos
        FROM dbo.roles r
        ORDER BY r.nombre
    `));
}

async function crearRol(data) {
    return withConnection(async (conexion) => {
        const result = await conexion.query(`
            INSERT INTO dbo.roles (nombre, descripcion, activo)
            OUTPUT INSERTED.id
            VALUES (?, ?, 1)
        `, [data.nombre, data.descripcion]);
        const id = result[0].id;
        await guardarPermisosRol(conexion, id, data.permisos);
        return id;
    });
}

async function actualizarRol(id, data) {
    return withConnection(async (conexion) => {
        await conexion.query(`
            UPDATE dbo.roles
            SET nombre = ?,
                descripcion = ?,
                fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
        `, [data.nombre, data.descripcion, id]);
        if (Array.isArray(data.permisos)) {
            await guardarPermisosRol(conexion, id, data.permisos);
        }
        return id;
    });
}

async function cambiarEstadoRol(id, activo) {
    return withConnection((conexion) => conexion.query(`
        UPDATE dbo.roles
        SET activo = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [activo ? 1 : 0, id]));
}

async function listarPermisos() {
    return withConnection((conexion) => conexion.query(`
        SELECT id, codigo, descripcion, modulo, activo
        FROM dbo.permisos
        WHERE activo = 1
        ORDER BY modulo, codigo
    `));
}

async function listarLugares() {
    return withConnection((conexion) => conexion.query(`
        SELECT l.id, l.ruta_id, ruta.nombre AS ruta, l.direccion,
               l.distrito_id, distrito.nombre AS distrito,
               l.hora_entrada, l.hora_salida, l.consignas,
               l.activo
        FROM dbo.lugares_servicio l
        INNER JOIN dbo.rutas ruta ON ruta.id = l.ruta_id
        INNER JOIN dbo.catalogo_detalles distrito ON distrito.id = l.distrito_id
        ORDER BY ruta.nombre, l.direccion
    `));
}

async function crearLugar(data) {
    return insertarBasico('dbo.lugares_servicio', [
        ['ruta_id', data.rutaId],
        ['direccion', data.direccion],
        ['distrito_id', data.distritoId],
        ['hora_entrada', data.horaEntrada],
        ['hora_salida', data.horaSalida],
        ['consignas', data.consignas]
    ]);
}

async function actualizarLugar(id, data) {
    return withConnection((conexion) => conexion.query(`
        UPDATE dbo.lugares_servicio
        SET ruta_id = ?,
            direccion = ?,
            distrito_id = ?,
            hora_entrada = ?,
            hora_salida = ?,
            consignas = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [
        data.rutaId,
        data.direccion,
        data.distritoId,
        data.horaEntrada,
        data.horaSalida,
        data.consignas,
        id
    ]));
}

async function cambiarEstadoLugar(id, activo) {
    return cambiarActivo('dbo.lugares_servicio', id, activo);
}

async function listarEas() {
    return withConnection((conexion) => conexion.query(`
        SELECT e.id, e.codigo, e.nombre, e.direccion, e.distrito_id,
               d.nombre AS distrito,
               e.activo
        FROM dbo.eas_estaciones e
        LEFT JOIN dbo.catalogo_detalles d ON d.id = e.distrito_id
        ORDER BY e.codigo, e.nombre
    `));
}

async function crearEas(data) {
    return insertarBasico('dbo.eas_estaciones', [
        ['codigo', data.codigo],
        ['nombre', data.nombre],
        ['direccion', data.direccion],
        ['distrito_id', data.distritoId]
    ]);
}

async function actualizarEas(id, data) {
    return withConnection((conexion) => conexion.query(`
        UPDATE dbo.eas_estaciones
        SET codigo = ?,
            nombre = ?,
            direccion = ?,
            distrito_id = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [data.codigo, data.nombre, data.direccion, data.distritoId, id]));
}

async function cambiarEstadoEas(id, activo) {
    return cambiarActivo('dbo.eas_estaciones', id, activo);
}

async function listarRutas() {
    return withConnection((conexion) => conexion.query(`
        SELECT id, nombre, activo
        FROM dbo.rutas
        ORDER BY nombre
    `));
}

async function crearRuta(data) {
    return insertarBasico('dbo.rutas', [
        ['nombre', data.nombre]
    ]);
}

async function actualizarRuta(id, data) {
    return withConnection((conexion) => conexion.query(`
        UPDATE dbo.rutas
        SET nombre = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [data.nombre, id]));
}

async function cambiarEstadoRuta(id, activo) {
    return cambiarActivo('dbo.rutas', id, activo);
}

async function eliminarRuta(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.rutas WHERE id = ?', [id]));
}

async function listarMoviles() {
    return withConnection((conexion) => conexion.query(`
        SELECT m.id, m.numero_movil, m.placa, m.tipo_movil_id,
               tipo.nombre AS tipo,
               m.kilometraje_actual,
               m.kilometraje_ultimo_mantenimiento,
               m.proximo_mantenimiento,
               (m.proximo_mantenimiento - m.kilometraje_actual) AS kilometros_restantes,
               CASE
                   WHEN m.kilometraje_actual > m.proximo_mantenimiento THEN N'KILOMETRAJE_EXCEDIDO'
                   WHEN (m.proximo_mantenimiento - m.kilometraje_actual) <= 500 THEN N'EN_ESPERA'
                   ELSE N'MANTENIMIENTO_COMPLETADO'
               END AS estado_mantenimiento,
               m.estado_movil_id,
               estado.nombre AS estado,
               m.observacion,
               m.observacion_estado,
               m.activo
        FROM dbo.moviles m
        INNER JOIN dbo.catalogo_detalles tipo ON tipo.id = m.tipo_movil_id
        INNER JOIN dbo.catalogo_detalles estado ON estado.id = m.estado_movil_id
        ORDER BY m.numero_movil
    `));
}

async function crearMovil(data) {
    return insertarBasico('dbo.moviles', [
        ['numero_movil', data.numeroMovil],
        ['placa', data.placa],
        ['tipo_movil_id', data.tipoMovilId],
        ['kilometraje_actual', data.kilometrajeActual],
        ['kilometraje_ultimo_mantenimiento', data.kilometrajeUltimoMantenimiento],
        ['estado_movil_id', data.estadoMovilId],
        ['observacion', data.observacion],
        ['observacion_estado', data.observacionEstado]
    ]);
}

async function actualizarMovil(id, data) {
    return withConnection((conexion) => conexion.query(`
        UPDATE dbo.moviles
        SET numero_movil = ?,
            placa = ?,
            tipo_movil_id = ?,
            kilometraje_actual = ?,
            kilometraje_ultimo_mantenimiento = ?,
            estado_movil_id = ?,
            observacion = ?,
            observacion_estado = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [
        data.numeroMovil,
        data.placa,
        data.tipoMovilId,
        data.kilometrajeActual,
        data.kilometrajeUltimoMantenimiento,
        data.estadoMovilId,
        data.observacion,
        data.observacionEstado,
        id
    ]));
}

async function cambiarEstadoMovil(id, activo) {
    return cambiarActivo('dbo.moviles', id, activo);
}

async function listarAsignaciones() {
    return withConnection((conexion) => conexion.query(`
        SELECT a.id, a.eas_id, e.codigo AS eas_codigo, e.nombre AS eas,
               a.movil_id, m.numero_movil, m.placa,
               a.fecha_asignacion,
               a.estado_asignacion_id,
               estado.nombre AS estado,
               a.observacion,
               a.activo
        FROM dbo.movil_eas_asignaciones a
        INNER JOIN dbo.eas_estaciones e ON e.id = a.eas_id
        INNER JOIN dbo.moviles m ON m.id = a.movil_id
        INNER JOIN dbo.catalogo_detalles estado ON estado.id = a.estado_asignacion_id
        ORDER BY a.fecha_asignacion DESC, a.id DESC
    `));
}

async function crearAsignacion(data) {
    return withConnection(async (conexion) => {
        const estadoActivoId = await obtenerDetalleId(conexion, 'ESTADOS_ASIGNACION_MOVIL', 'ACTIVA');
        const estadoInactivoId = await obtenerDetalleId(conexion, 'ESTADOS_ASIGNACION_MOVIL', 'INACTIVA');
        const esActiva = Number(data.estadoAsignacionId) === Number(estadoActivoId);

        if (esActiva) {
            await conexion.query(`
                UPDATE dbo.movil_eas_asignaciones
                SET activo = 0,
                    estado_asignacion_id = ?,
                    fecha_actualizacion = SYSDATETIME()
                WHERE movil_id = ?
                  AND activo = 1
            `, [estadoInactivoId, data.movilId]);
        }

        const result = await conexion.query(`
            INSERT INTO dbo.movil_eas_asignaciones (
                eas_id, movil_id, fecha_asignacion, estado_asignacion_id, observacion, activo
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?)
        `, [
            data.easId,
            data.movilId,
            data.fechaAsignacion,
            data.estadoAsignacionId,
            data.observacion,
            esActiva ? 1 : 0
        ]);

        return result[0].id;
    });
}

async function actualizarAsignacion(id, data) {
    return withConnection(async (conexion) => {
        const estadoActivoId = await obtenerDetalleId(conexion, 'ESTADOS_ASIGNACION_MOVIL', 'ACTIVA');
        const estadoInactivoId = await obtenerDetalleId(conexion, 'ESTADOS_ASIGNACION_MOVIL', 'INACTIVA');
        const esActiva = Number(data.estadoAsignacionId) === Number(estadoActivoId);

        if (esActiva) {
            await conexion.query(`
                UPDATE dbo.movil_eas_asignaciones
                SET activo = 0,
                    estado_asignacion_id = ?,
                    fecha_actualizacion = SYSDATETIME()
                WHERE movil_id = ?
                  AND id <> ?
                  AND activo = 1
            `, [estadoInactivoId, data.movilId, id]);
        }

        await conexion.query(`
            UPDATE dbo.movil_eas_asignaciones
            SET eas_id = ?,
                movil_id = ?,
                fecha_asignacion = ?,
                estado_asignacion_id = ?,
                observacion = ?,
                activo = ?,
                fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
        `, [
            data.easId,
            data.movilId,
            data.fechaAsignacion,
            data.estadoAsignacionId,
            data.observacion,
            esActiva ? 1 : 0,
            id
        ]);
    });
}

async function obtenerAlertasMantenimiento() {
    return withConnection((conexion) => conexion.query(`
        SELECT *
        FROM dbo.vw_moviles_mantenimiento
        WHERE estado_mantenimiento != N'MANTENIMIENTO_COMPLETADO'
          AND activo = 1
        ORDER BY kilometros_restantes
    `));
}

async function listarMantenimientos(movilId) {
    return withConnection((conexion) => conexion.query(`
        SELECT mm.id, mm.movil_id, mm.fecha_mantenimiento, mm.kilometraje,
               mm.descripcion, tm.nombre AS tipo_mantenimiento, mm.activo
        FROM dbo.movil_mantenimiento mm
        LEFT JOIN dbo.catalogo_detalles tm ON tm.id = mm.tipo_mantenimiento_id
        WHERE mm.movil_id = ?
        ORDER BY mm.fecha_mantenimiento DESC, mm.id DESC
    `, [movilId]));
}

async function crearMantenimiento(data) {
    return withConnection(async (conexion) => {
        const result = await conexion.query(`
            INSERT INTO dbo.movil_mantenimiento (movil_id, fecha_mantenimiento, kilometraje, descripcion, tipo_mantenimiento_id)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?)
        `, [data.movilId, data.fechaMantenimiento, data.kilometraje, data.descripcion, data.tipoMantenimientoId]);

        await conexion.query(`
            UPDATE dbo.moviles
            SET kilometraje_ultimo_mantenimiento = ?,
                fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
        `, [data.kilometraje, data.movilId]);

        return result[0].id;
    });
}

async function obtenerCatalogo(conexion, codigo) {
    const result = await conexion.query(
        'SELECT TOP 1 id, codigo FROM dbo.catalogos WHERE codigo = ?',
        [codigo]
    );
    if (result.length === 0) {
        throw new Error(`Catalogo no encontrado: ${codigo}`);
    }
    return result[0];
}

async function obtenerDetallePorId(conexion, id) {
    const result = await conexion.query(
        'SELECT id, codigo, nombre, descripcion, orden, estado FROM dbo.catalogo_detalles WHERE id = ?',
        [id]
    );
    return result[0] || null;
}

async function obtenerDetalleId(conexion, catalogo, codigo) {
    const result = await conexion.query(`
        SELECT TOP 1 d.id
        FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
        WHERE c.codigo = ?
          AND d.codigo = ?
    `, [catalogo, codigo]);
    if (result.length === 0) {
        throw new Error(`No existe ${catalogo}.${codigo}`);
    }
    return result[0].id;
}

async function guardarPermisosRol(conexion, rolId, permisos) {
    await conexion.query('DELETE FROM dbo.rol_permiso WHERE rol_id = ?', [rolId]);
    const codigos = [...new Set((permisos || []).map((p) => p.toString()))];
    for (const codigo of codigos) {
        await conexion.query(`
            INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
            SELECT ?, id
            FROM dbo.permisos
            WHERE codigo = ?
        `, [rolId, codigo]);
    }
}

const TABLAS_PERMITIDAS = new Set([
    'dbo.lugares_servicio',
    'dbo.eas_estaciones',
    'dbo.moviles',
    'dbo.rutas',
]);

function validarTabla(tabla) {
    if (!TABLAS_PERMITIDAS.has(tabla)) {
        throw new Error(`Tabla no permitida: ${tabla}`);
    }
    return tabla;
}

async function insertarBasico(tabla, campos) {
    validarTabla(tabla);
    return withConnection(async (conexion) => {
        const columns = campos.map(([name]) => name);
        const values = campos.map(([, value]) => value);
        const marks = columns.map(() => '?').join(', ');
        const result = await conexion.query(`
            INSERT INTO ${tabla} (${columns.join(', ')})
            OUTPUT INSERTED.id
            VALUES (${marks})
        `, values);
        return result[0].id;
    });
}

async function cambiarActivo(tabla, id, activo) {
    validarTabla(tabla);
    return withConnection((conexion) => conexion.query(`
        UPDATE ${tabla}
        SET activo = ?,
            fecha_actualizacion = SYSDATETIME()
        WHERE id = ?
    `, [activo ? 1 : 0, id]));
}

async function eliminarDetalle(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.catalogo_detalles WHERE id = ?', [id]));
}

async function eliminarRol(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.rol_permiso WHERE rol_id = ?; DELETE FROM dbo.roles WHERE id = ?', [id, id]));
}

async function eliminarLugar(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.lugares_servicio WHERE id = ?', [id]));
}

async function eliminarEas(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.eas_estaciones WHERE id = ?', [id]));
}

async function eliminarMovil(id) {
    return withConnection(async (conexion) => {
        await conexion.query('DELETE FROM dbo.movil_mantenimiento WHERE movil_id = ?', [id]);
        await conexion.query('DELETE FROM dbo.movil_eas_asignaciones WHERE movil_id = ?', [id]);
        await conexion.query('DELETE FROM dbo.moviles WHERE id = ?', [id]);
    });
}

async function eliminarAsignacion(id) {
    return withConnection((conexion) => conexion.query('DELETE FROM dbo.movil_eas_asignaciones WHERE id = ?', [id]));
}

module.exports = {
    listarCatalogos,
    listarDetalles,
    crearDetalle,
    actualizarDetalle,
    cambiarEstadoDetalle,
    eliminarDetalle,
    listarRoles,
    crearRol,
    actualizarRol,
    cambiarEstadoRol,
    eliminarRol,
    listarPermisos,
    listarLugares,
    crearLugar,
    actualizarLugar,
    cambiarEstadoLugar,
    eliminarLugar,
    listarEas,
    crearEas,
    actualizarEas,
    cambiarEstadoEas,
    eliminarEas,
    listarRutas,
    crearRuta,
    actualizarRuta,
    cambiarEstadoRuta,
    eliminarRuta,
    listarMoviles,
    crearMovil,
    actualizarMovil,
    cambiarEstadoMovil,
    eliminarMovil,
    listarAsignaciones,
    crearAsignacion,
    actualizarAsignacion,
    eliminarAsignacion,
    obtenerAlertasMantenimiento,
    listarMantenimientos,
    crearMantenimiento
};
