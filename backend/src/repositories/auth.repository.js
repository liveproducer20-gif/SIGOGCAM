const { getPool } = require('../config/db');

async function query(sql, params) {
    const pool = await getPool();
    const conexion = await pool.connect();
    try {
        return await conexion.query(sql, params);
    } finally {
        await conexion.close();
    }
}

async function buscarPorCorreo(correo) {
    const tienePassword = await tieneColumna('password_hash');
    const tieneFoto = await tieneColumna('foto_perfil_url');

    const extraSelect = [];
    if (tienePassword) extraSelect.push('p.password_hash');
    extraSelect.push('p.fecha_nacimiento');
    const extraScalarSelect = extraSelect.map(c => `, ${c}`).join('');
    const extraLobSelect = tieneFoto
        ? ', CONVERT(NVARCHAR(MAX), p.foto_perfil_url) AS foto_perfil_url'
        : '';

    const sql = `
        SELECT TOP 1
            vd.id, vd.cedula, vd.correo_institucional,
            vd.nombres, vd.apellidos, vd.nombre_completo,
            vd.rol, p.rol_id, r.codigo AS rol_codigo,
            vd.estado_personal, vd.activo
            ${extraScalarSelect}
            ${extraLobSelect}
        FROM vw_personal_detalle vd
        LEFT JOIN dbo.personal p ON p.id = vd.id
        LEFT JOIN dbo.roles r ON r.id = p.rol_id
        WHERE LOWER(vd.correo_institucional) = ?
          AND (vd.activo = 1 OR vd.activo = '1')
        ORDER BY vd.id
    `;
    const result = await query(sql, [correo]);
    return result[0] || null;
}

async function buscarPorId(id) {
    const sql = `
        SELECT TOP 1 vd.id, vd.cedula, p.password_hash
        FROM vw_personal_detalle vd
        INNER JOIN dbo.personal p ON p.id = vd.id
        WHERE vd.id = ?
    `;
    const result = await query(sql, [id]);
    return result[0] || null;
}

async function obtenerPermisos(rolId) {
    const sql = `
        SELECT p.codigo
        FROM roles r
        INNER JOIN rol_permiso rp ON rp.rol_id = r.id
        INNER JOIN permisos p ON p.id = rp.permiso_id
        WHERE r.id = ?
          AND r.activo = 1
          AND p.activo = 1
        ORDER BY p.codigo
    `;
    const result = await query(sql, [rolId]);
    return result.map(item => item.codigo);
}

async function actualizarPassword(id, hash) {
    await query(
        'UPDATE dbo.personal SET password_hash = ? WHERE id = ?',
        [hash, id]
    );
}

const _COLUMNAS_PERMITIDAS = new Set(['password_hash', 'foto_perfil_url']);

async function tieneColumna(columna) {
    if (!_COLUMNAS_PERMITIDAS.has(columna)) return false;
    const result = await query(
        `SELECT COL_LENGTH('dbo.personal', '${columna}') AS existe`
    );
    return Boolean(result[0]?.existe);
}

module.exports = {
    buscarPorCorreo,
    buscarPorId,
    obtenerPermisos,
    actualizarPassword,
    tieneColumna
};
