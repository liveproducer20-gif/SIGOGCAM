const { getPool } = require('../config/db');

const pool = () => getPool();
const q = async (sql, params) => {
    const p = await pool();
    const c = await p.connect();
    try { return await c.query(sql, params); } finally { await c.close(); }
};

// ---- Módulos del Sistema ----
async function listarModulos() {
    return q('SELECT * FROM dbo.modulos_sistema ORDER BY orden, nombre');
}

async function obtenerModulo(id) {
    const r = await q('SELECT * FROM dbo.modulos_sistema WHERE id = ?', [id]);
    return r[0] || null;
}

async function crearModulo({ nombre, codigo, icono, ruta, modulo_padre_id, orden, activo }) {
    const r = await q(
        `INSERT INTO dbo.modulos_sistema (nombre, codigo, icono, ruta, modulo_padre_id, orden, activo)
         OUTPUT INSERTED.*
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [nombre, codigo, icono, ruta, modulo_padre_id || null, orden || 0, activo ?? 1]
    );
    return r[0];
}

async function actualizarModulo(id, { nombre, codigo, icono, ruta, modulo_padre_id, orden, activo }) {
    await q(
        `UPDATE dbo.modulos_sistema
         SET nombre = ?, codigo = ?, icono = ?, ruta = ?,
             modulo_padre_id = ?, orden = ?, activo = ?
         WHERE id = ?`,
        [nombre, codigo, icono, ruta, modulo_padre_id || null, orden || 0, activo ?? 1, id]
    );
    return obtenerModulo(id);
}

async function eliminarModulo(id) {
    await q('DELETE FROM dbo.modulos_sistema WHERE id = ?', [id]);
}

// ---- Permisos de Módulo ----
async function listarPermisosPorModulo(moduloCodigo) {
    return q(`
        SELECT * FROM dbo.permisos
        WHERE modulo = ? AND activo = 1
        ORDER BY codigo
    `, [moduloCodigo]);
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
        SELECT rmc.*, ms.nombre AS modulo_nombre, ms.codigo AS modulo_codigo,
               ms.icono, ms.ruta
        FROM dbo.rol_menu_configuracion rmc
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
        WHERE rmc.rol_id = ?
        ORDER BY rmc.nivel, rmc.orden
    `, [rolId]);
}

async function guardarMenuRol(rolId, items) {
    const p = await pool();
    const c = await p.connect();
    try {
        await c.beginTransaction();
        await c.query('DELETE FROM dbo.rol_menu_configuracion WHERE rol_id = ?', [rolId]);
        for (const item of items) {
            await c.query(
                `INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, nivel, orden, visible, etiqueta_personalizada)
                 VALUES (?, ?, ?, ?, ?, ?)`,
                [rolId, item.modulo_id, item.nivel || 0, item.orden || 0, item.visible ?? 1, item.etiqueta_personalizada || null]
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
async function miEstructura(rolCodigo) {
    return q(`
        SELECT ms.id, ms.nombre, ms.codigo, ms.icono, ms.ruta,
               ms.modulo_padre_id, rmc.nivel, rmc.orden, rmc.etiqueta_personalizada
        FROM dbo.roles r
        INNER JOIN dbo.rol_menu_configuracion rmc ON rmc.rol_id = r.id
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
        WHERE r.codigo = ? AND r.activo = 1 AND rmc.visible = 1 AND ms.activo = 1
        ORDER BY rmc.nivel, rmc.orden
    `, [rolCodigo]);
}

// ---- Alcance de Datos ----
async function obtenerAlcanceRol(rolId) {
    return q('SELECT * FROM dbo.rol_alcance_datos WHERE rol_id = ?', [rolId]);
}

async function guardarAlcanceRol(rolId, items) {
    const p = await pool();
    const c = await p.connect();
    try {
        await c.beginTransaction();
        await c.query('DELETE FROM dbo.rol_alcance_datos WHERE rol_id = ?', [rolId]);
        for (const item of items) {
            await c.query(
                `INSERT INTO dbo.rol_alcance_datos (rol_id, modulo, alcance, entidad, condicion_adicional)
                 VALUES (?, ?, ?, ?, ?)`,
                [rolId, item.modulo, item.alcance, item.entidad, item.condicion_adicional ? JSON.stringify(item.condicion_adicional) : null]
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
               cs.tipo_dato, cs.entidad, cs.seccion
        FROM dbo.rol_campos_permisos rcp
        INNER JOIN dbo.campos_sistema cs ON cs.id = rcp.campo_id
        WHERE rcp.rol_id = ?
        ORDER BY cs.entidad, cs.seccion, cs.orden
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
                `INSERT INTO dbo.rol_campos_permisos (rol_id, campo_id, puede_ver, puede_editar, requerido)
                 VALUES (?, ?, ?, ?, ?)`,
                [rolId, item.campo_id, item.puede_ver ?? 1, item.puede_editar ?? 0, item.requerido ?? 0]
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
        SELECT * FROM dbo.versiones_configuracion_roles
        WHERE rol_id = ? ORDER BY version DESC
    `, [rolId]);
}

async function crearVersion(rolId, datosJson, descripcion, creadoPor) {
    const r = await q(`
        INSERT INTO dbo.versiones_configuracion_roles (rol_id, datos_json, descripcion, creado_por)
         OUTPUT INSERTED.*
         VALUES (?, ?, ?, ?)
    `, [rolId, datosJson, descripcion || '', creadoPor || null]);
    return r[0];
}

async function obtenerVersion(versionId) {
    const r = await q('SELECT * FROM dbo.versiones_configuracion_roles WHERE id = ?', [versionId]);
    return r[0] || null;
}

// ---- Auditoría ----
async function listarAuditoria({ rolId, modulo, accion, desde, hasta, limite }) {
    let sql = 'SELECT * FROM dbo.auditoria_roles_permisos WHERE 1=1';
    const params = [];
    if (rolId) { sql += ' AND rol_id = ?'; params.push(rolId); }
    if (modulo) { sql += ' AND modulo = ?'; params.push(modulo); }
    if (accion) { sql += ' AND accion = ?'; params.push(accion); }
    if (desde) { sql += ' AND creado_en >= ?'; params.push(desde); }
    if (hasta) { sql += ' AND creado_en <= ?'; params.push(hasta); }
    sql += ' ORDER BY creado_en DESC';
    if (limite) { sql += ' OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY'; params.push(limite); }
    return q(sql, params);
}

async function registrarAuditoria({ rolId, modulo, accion, detalle, usuarioId, datosAntiguos, datosNuevos }) {
    await q(
        `INSERT INTO dbo.auditoria_roles_permisos (rol_id, modulo, accion, detalle, usuario_id, datos_antiguos, datos_nuevos)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [rolId, modulo, accion, detalle || '', usuarioId || null, datosAntiguos ? JSON.stringify(datosAntiguos) : null, datosNuevos ? JSON.stringify(datosNuevos) : null]
    );
}

// ---- Campos del Sistema ----
async function listarCamposSistema(entidad) {
    let sql = 'SELECT * FROM dbo.campos_sistema';
    const params = [];
    if (entidad) { sql += ' WHERE entidad = ?'; params.push(entidad); }
    sql += ' ORDER BY entidad, seccion, orden';
    return q(sql, params);
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
