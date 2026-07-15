const { getPool } = require('../config/db');

const pool = () => getPool();
const q = async (sql, params) => {
    const p = await pool();
    const c = await p.connect();
    try { return await c.query(sql, params); } finally { await c.close(); }
};

// ---- Módulos del Sistema ----
async function listarModulos() {
    return q(`
        SELECT id, nombre, codigo, icono, ruta, plataforma,
               orden_global AS orden, tiene_submenus,
               estado AS activo, fecha_creacion,
               CAST(NULL AS INT) AS modulo_padre_id
        FROM dbo.modulos_sistema
        ORDER BY orden_global, nombre
    `);
}

async function obtenerModulo(id) {
    const r = await q(`
        SELECT id, nombre, codigo, icono, ruta, plataforma,
               orden_global AS orden, tiene_submenus,
               estado AS activo, fecha_creacion,
               CAST(NULL AS INT) AS modulo_padre_id
        FROM dbo.modulos_sistema WHERE id = ?
    `, [id]);
    return r[0] || null;
}

async function crearModulo({ nombre, codigo, icono, ruta, modulo_padre_id, orden, activo }) {
    const r = await q(
        `INSERT INTO dbo.modulos_sistema
            (nombre, codigo, icono, ruta, plataforma, orden_global, tiene_submenus, estado)
         OUTPUT INSERTED.*
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [nombre, codigo, icono, ruta, 'ambos', orden || 0, modulo_padre_id ? 1 : 0, activo ?? 1]
    );
    return obtenerModulo(r[0].id);
}

async function actualizarModulo(id, { nombre, codigo, icono, ruta, modulo_padre_id, orden, activo }) {
    await q(
        `UPDATE dbo.modulos_sistema
         SET nombre = ?, codigo = ?, icono = ?, ruta = ?,
             orden_global = ?, tiene_submenus = ?, estado = ?
         WHERE id = ?`,
        [nombre, codigo, icono, ruta, orden || 0, modulo_padre_id ? 1 : 0, activo ?? 1, id]
    );
    return obtenerModulo(id);
}

async function eliminarModulo(id) {
    await q('UPDATE dbo.modulos_sistema SET estado = 0 WHERE id = ?', [id]);
}

// ---- Permisos de Módulo ----
async function listarPermisosPorModulo(moduloId) {
    return q(`
        SELECT DISTINCT p.*
        FROM dbo.permisos p
        CROSS JOIN dbo.modulos_sistema ms
        WHERE ms.id = ? AND p.activo = 1
          AND (
            p.modulo = ms.codigo
            OR (ms.codigo = 'eventos_anuncios' AND p.modulo IN ('eventos','anuncios'))
            OR (ms.codigo = 'administracion' AND p.modulo IN (
                'administracion','personal','catalogos','lugares_servicio',
                'eas','moviles','rutas','grados'
            ))
          )
        ORDER BY p.codigo
    `, [moduloId]);
}

async function listarPermisosNoAsignados(moduloCodigo) {
    return q(`
        SELECT * FROM dbo.permisos
        WHERE (modulo IS NULL OR modulo = '')
          AND activo = 1
        ORDER BY codigo
    `, []);
}

// ---- Menú por Rol ----
async function obtenerMenuRol(rolId) {
    return q(`
        SELECT rmc.*,
               0 AS nivel,
               rmc.nombre_visual AS etiqueta_personalizada,
               ms.nombre AS modulo_nombre, ms.codigo AS modulo_codigo,
               ms.icono, ms.ruta
        FROM dbo.rol_menu_configuracion rmc
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
        WHERE rmc.rol_id = ?
        ORDER BY rmc.orden
    `, [rolId]);
}

async function guardarMenuRol(rolId, items) {
    const p = await pool();
    const c = await p.connect();
    try {
        await c.beginTransaction();
        const actuales = await c.query(
            'SELECT * FROM dbo.rol_menu_configuracion WHERE rol_id = ?',
            [rolId]
        );
        const actualPorModulo = new Map(
            actuales.map(item => [Number(item.modulo_id), item])
        );
        await c.query('DELETE FROM dbo.rol_menu_configuracion WHERE rol_id = ?', [rolId]);
        for (const item of items) {
            const actual = actualPorModulo.get(Number(item.modulo_id)) || {};
            await c.query(
                `INSERT INTO dbo.rol_menu_configuracion
                    (rol_id, modulo_id, modulo_padre_id, grupo, nombre_visual,
                     orden, visible, habilitado, expandido)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
                [
                    rolId,
                    item.modulo_id,
                    item.modulo_padre_id || actual.modulo_padre_id || null,
                    item.grupo || actual.grupo || 'MENU_PRINCIPAL',
                    item.nombre_visual || item.etiqueta_personalizada || actual.nombre_visual || null,
                    item.orden || 0,
                    item.visible ?? 1,
                    item.habilitado ?? actual.habilitado ?? 1,
                    item.expandido ?? actual.expandido ?? 0
                ]
            );
        }
        await c.commit();
    } catch (e) {
        await c.rollback();
        throw e;
    } finally {
        await c.close();
    }
}

// ---- Mi Estructura (menú dinámico) ----
async function miEstructura(usuarioId) {
    return q(`
        SELECT ms.id,
               COALESCE(NULLIF(rmc.nombre_visual, ''), ms.nombre) AS nombre,
               ms.codigo, COALESCE(rmc.icono_visual, ms.icono) AS icono, ms.ruta,
               rmc.modulo_padre_id, rmc.grupo, rmc.orden,
               rmc.nombre_visual AS etiqueta_personalizada,
               rmc.visible, rmc.habilitado, rmc.expandido,
               rmc.mostrar_badge, rmc.color_badge
        FROM dbo.personal per
        INNER JOIN dbo.roles r ON r.id = per.rol_id
        INNER JOIN dbo.rol_menu_configuracion rmc ON rmc.rol_id = r.id
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
        WHERE per.id = ? AND r.activo = 1 AND rmc.visible = 1 AND ms.estado = 1
        ORDER BY rmc.orden
    `, [usuarioId]);
}

// ---- Alcance de Datos ----
async function obtenerAlcanceRol(rolId) {
    return q(`
        SELECT rad.id, rad.rol_id, rad.modulo_id, rad.tipo_alcance,
               ms.codigo AS modulo, ms.nombre AS entidad,
               rad.tipo_alcance AS alcance,
               CONVERT(NVARCHAR(MAX), rad.configuracion_json) AS condicion_adicional
        FROM dbo.rol_alcance_datos rad
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rad.modulo_id
        WHERE rad.rol_id = ?
        ORDER BY ms.orden_global, ms.nombre
    `, [rolId]);
}

async function guardarAlcanceRol(rolId, items) {
    const p = await pool();
    const c = await p.connect();
    try {
        await c.beginTransaction();
        await c.query('DELETE FROM dbo.rol_alcance_datos WHERE rol_id = ?', [rolId]);
        for (const item of items) {
            await c.query(
                `INSERT INTO dbo.rol_alcance_datos
                    (rol_id, modulo_id, tipo_alcance, configuracion_json)
                 SELECT ?, ms.id, ?, ?
                 FROM dbo.modulos_sistema ms
                 WHERE ms.codigo = ?`,
                [
                    rolId,
                    normalizarAlcance(item.alcance || item.tipo_alcance),
                    item.condicion_adicional ? JSON.stringify(item.condicion_adicional) : null,
                    item.modulo
                ]
            );
        }
        await c.commit();
    } catch (e) {
        await c.rollback();
        throw e;
    } finally {
        await c.close();
    }
}

// ---- Campos por Rol ----
async function obtenerCamposRol(rolId) {
    return q(`
        SELECT rcp.*, cs.nombre AS campo_nombre, cs.codigo AS campo_codigo,
               cs.tipo_dato, cs.clasificacion AS entidad,
               ms.nombre AS seccion,
               CAST(CASE WHEN rcp.nivel_acceso <> 'oculto' THEN 1 ELSE 0 END AS BIT) AS puede_ver,
               CAST(CASE WHEN rcp.nivel_acceso IN ('editable','obligatorio') THEN 1 ELSE 0 END AS BIT) AS puede_editar,
               CAST(CASE WHEN rcp.nivel_acceso = 'obligatorio' THEN 1 ELSE 0 END AS BIT) AS requerido
        FROM dbo.rol_campos_permisos rcp
        INNER JOIN dbo.campos_sistema cs ON cs.id = rcp.campo_id
        INNER JOIN dbo.modulos_sistema ms ON ms.id = cs.modulo_id
        WHERE rcp.rol_id = ?
        ORDER BY ms.orden_global, cs.nombre
    `, [rolId]);
}

async function guardarCamposRol(rolId, items) {
    const p = await pool();
    const c = await p.connect();
    try {
        await c.beginTransaction();
        await c.query('DELETE FROM dbo.rol_campos_permisos WHERE rol_id = ?', [rolId]);
        for (const item of items) {
            await c.query(
                `INSERT INTO dbo.rol_campos_permisos
                    (rol_id, campo_id, nivel_acceso, enmascarado)
                 VALUES (?, ?, ?, ?)`,
                [rolId, item.campo_id, nivelAccesoCampo(item), item.enmascarado ?? 0]
            );
        }
        await c.commit();
    } catch (e) {
        await c.rollback();
        throw e;
    } finally {
        await c.close();
    }
}

// ---- Versiones ----
async function listarVersiones(rolId) {
    return q(`
        SELECT CONVERT(VARCHAR(30), id) AS id, rol_id, version,
               comentario AS descripcion,
               creado_por, fecha_creacion AS creado_en,
               estado,
               CONVERT(NVARCHAR(MAX), configuracion_json) AS datos_json
        FROM dbo.versiones_configuracion_roles
        WHERE rol_id = ? ORDER BY version DESC
    `, [rolId]);
}

async function crearVersion(rolId, datosJson, descripcion, creadoPor) {
    const r = await q(`
        INSERT INTO dbo.versiones_configuracion_roles
            (rol_id, version, estado, configuracion_json, comentario, creado_por)
         OUTPUT CONVERT(VARCHAR(30), INSERTED.id) AS id
         SELECT ?, COALESCE(MAX(version), 0) + 1, 'borrador', ?, ?, ?
         FROM dbo.versiones_configuracion_roles WHERE rol_id = ?
    `, [rolId, datosJson || '{}', descripcion || '', creadoPor, rolId]);
    return obtenerVersion(r[0].id);
}

async function obtenerVersion(versionId) {
    const r = await q(`
        SELECT CONVERT(VARCHAR(30), id) AS id, rol_id, version, estado,
               comentario AS descripcion, fecha_creacion AS creado_en,
               CONVERT(NVARCHAR(MAX), configuracion_json) AS datos_json
        FROM dbo.versiones_configuracion_roles WHERE id = ?
    `, [versionId]);
    return r[0] || null;
}

// ---- Auditoría ----
async function listarAuditoria({ rolId, modulo, accion, desde, hasta, limite }) {
    let sql = `SELECT CONVERT(VARCHAR(30), id) AS id, usuario_id, accion,
                      rol_afectado_id AS rol_id,
                      '' AS modulo, NULL AS detalle,
                      fecha AS creado_en,
                      CONVERT(NVARCHAR(MAX), valor_anterior) AS datos_antiguos,
                      CONVERT(NVARCHAR(MAX), valor_nuevo) AS datos_nuevos
               FROM dbo.auditoria_roles_permisos WHERE 1=1`;
    const params = [];
    if (rolId) { sql += ' AND rol_afectado_id = ?'; params.push(rolId); }
    // El esquema de auditoría no almacena módulo por separado.
    if (accion) { sql += ' AND accion = ?'; params.push(accion); }
    if (desde) { sql += ' AND fecha >= ?'; params.push(desde); }
    if (hasta) { sql += ' AND fecha <= ?'; params.push(hasta); }
    sql += ' ORDER BY fecha DESC';
    if (limite) { sql += ' OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY'; params.push(limite); }
    return q(sql, params);
}

async function registrarAuditoria({ rolId, modulo, accion, detalle, usuarioId, datosAntiguos, datosNuevos }) {
    const accionDb = normalizarAccionAuditoria(accion);
    const nuevo = datosNuevos || (detalle ? { detalle, modulo } : null);
    await q(
        `INSERT INTO dbo.auditoria_roles_permisos
            (usuario_id, accion, rol_afectado_id, valor_anterior, valor_nuevo)
         VALUES (?, ?, ?, ?, ?)`,
        [usuarioId, accionDb, rolId || null, datosAntiguos ? JSON.stringify(datosAntiguos) : null, nuevo ? JSON.stringify(nuevo) : null]
    );
}

// ---- Campos del Sistema ----
async function listarCamposSistema(entidad) {
    let sql = `SELECT cs.*, ms.codigo AS entidad, ms.nombre AS seccion
               FROM dbo.campos_sistema cs
               INNER JOIN dbo.modulos_sistema ms ON ms.id = cs.modulo_id`;
    const params = [];
    if (entidad) { sql += ' WHERE ms.codigo = ?'; params.push(entidad); }
    sql += ' ORDER BY ms.orden_global, cs.nombre';
    return q(sql, params);
}

function normalizarAlcance(value) {
    const alcance = (value || '').toString().toLowerCase();
    if (alcance === 'todos') return 'global';
    if (alcance === 'unidad' || alcance === 'departamento') return 'area';
    const validos = new Set([
        'propio', 'area', 'equipo', 'turno', 'distrito',
        'creado_por_usuario', 'asignado_usuario', 'global', 'personalizado'
    ]);
    return validos.has(alcance) ? alcance : 'propio';
}

function nivelAccesoCampo(item) {
    if (item.nivel_acceso) return item.nivel_acceso;
    if (item.requerido) return 'obligatorio';
    if (item.puede_editar) return 'editable';
    if (item.puede_ver) return 'lectura';
    return 'oculto';
}

function normalizarAccionAuditoria(accion) {
    const value = (accion || '').toString();
    const directas = new Set([
        'crear_rol', 'editar_rol', 'desactivar_rol', 'eliminar_rol',
        'asignar_permiso', 'quitar_permiso', 'publicar_config',
        'guardar_borrador', 'restaurar_version', 'asignar_usuario',
        'quitar_usuario'
    ]);
    if (directas.has(value)) return value;
    if (value === 'crear_version') return 'guardar_borrador';
    if (value === 'restaurar_version') return 'restaurar_version';
    return 'publicar_config';
}

module.exports = {
    listarModulos, obtenerModulo, crearModulo, actualizarModulo, eliminarModulo,
    listarPermisosPorModulo, listarPermisosNoAsignados,
    obtenerMenuRol, guardarMenuRol,
    miEstructura,
    obtenerAlcanceRol, guardarAlcanceRol,
    obtenerCamposRol, guardarCamposRol,
    listarVersiones, crearVersion, obtenerVersion,
    listarAuditoria, registrarAuditoria,
    listarCamposSistema
};
