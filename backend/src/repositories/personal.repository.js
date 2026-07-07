const { getPool } = require('../config/db');

async function obtenerTodo() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT vd.*,
                   p.cargo_id,
                   p.grado_id,
                   p.area_id,
                   p.funcion_operativa_id,
                   p.jornada_id,
                   p.grupo_id,
                   p.tipo_rotacion_id,
                   p.rol_id,
                   p.estado_personal_id
            FROM vw_personal_detalle vd
            INNER JOIN personal p ON p.id = vd.id
            ORDER BY apellidos, nombres
        `;

        return await conexion.query(sql);
    } finally {
        await conexion.close();
    }
}

async function obtenerOperativos() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT *
            FROM vw_personal_operativo
            ORDER BY apellidos, nombres
        `;

        return await conexion.query(sql);
    } finally {
        await conexion.close();
    }
}

async function obtenerDisponibles() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT *
            FROM vw_personal_disponible
            ORDER BY apellidos, nombres
        `;

        return await conexion.query(sql);
    } finally {
        await conexion.close();
    }
}

async function obtenerDisponiblesSinEvento() {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const sql = `
            SELECT *
            FROM vw_personal_disponible_sin_evento
            ORDER BY apellidos, nombres
        `;

        return await conexion.query(sql);
    } finally {
        await conexion.close();
    }
}

async function buscar(texto) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const filtro = `%${texto}%`;

        const sql = `
            SELECT *
            FROM vw_personal_detalle
            WHERE nombres LIKE ?
               OR apellidos LIKE ?
               OR cedula LIKE ?
               OR correo_institucional LIKE ?
            ORDER BY apellidos, nombres
        `;

        return await conexion.query(sql, [filtro, filtro, filtro, filtro]);
    } finally {
        await conexion.close();
    }
}

async function obtenerPerfil(id) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const tieneFoto = await tieneColumnaFoto(conexion);
        const fotoSelect = tieneFoto ? ', p.foto_perfil_url' : '';
        const sql = `
            SELECT TOP 1
                vd.id,
                vd.cedula,
                vd.nombres,
                vd.apellidos,
                vd.nombre_completo,
                vd.correo_institucional,
                vd.telefono,
                vd.fecha_nacimiento,
                vd.fecha_ingreso,
                vd.rol,
                vd.estado_personal
                ${fotoSelect}
            FROM vw_personal_detalle vd
            INNER JOIN personal p ON p.id = vd.id
            WHERE vd.id = ?
        `;

        const result = await conexion.query(sql, [id]);
        return result[0] || null;
    } finally {
        await conexion.close();
    }
}

async function actualizarPerfil(id, data) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const existeCedulaSql = `
            SELECT id
            FROM personal
            WHERE cedula = ?
              AND id <> ?
        `;
        const cedulaExistente = await conexion.query(existeCedulaSql, [
            data.cedula,
            id
        ]);

        if (cedulaExistente.length > 0) {
            throw new Error('Ya existe otro usuario con esa cedula');
        }

        const existeCorreoSql = `
            SELECT id
            FROM personal
            WHERE correo_institucional = ?
              AND id <> ?
        `;
        const existente = await conexion.query(existeCorreoSql, [
            data.correoInstitucional,
            id
        ]);

        if (existente.length > 0) {
            throw new Error('Ya existe otro usuario con ese correo institucional');
        }

        const tieneFoto = await tieneColumnaFoto(conexion);
        const fotoSet = tieneFoto ? ', foto_perfil_url = ?' : '';
        const sql = `
            UPDATE personal
            SET cedula = ?,
                correo_institucional = ?,
                telefono = ?,
                fecha_nacimiento = ?
                ${fotoSet}
            WHERE id = ?
        `;

        const params = [
            data.cedula,
            data.correoInstitucional,
            data.telefono,
            data.fechaNacimiento
        ];

        if (tieneFoto) {
            params.push(data.fotoPerfilUrl);
        }

        params.push(id);
        await conexion.query(sql, params);
        return await obtenerPerfil(id);
    } finally {
        await conexion.close();
    }
}

async function tieneColumnaFoto(conexion) {
    const result = await conexion.query(`
        SELECT COL_LENGTH('personal', 'foto_perfil_url') AS existe
    `);

    return Boolean(result[0]?.existe);
}

async function crear(data) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const existeSql = `
            SELECT id
            FROM personal
            WHERE cedula = ?
               OR correo_institucional = ?
        `;

        const existente = await conexion.query(existeSql, [
            data.cedula,
            data.correoInstitucional
        ]);

        if (existente.length > 0) {
            throw new Error('Ya existe personal registrado con esa cedula o correo');
        }

        const columnas = await columnasPersonal(conexion);
        const campos = camposPersonal(data, columnas);
        const names = campos.map(([name]) => name);
        const values = campos.map(([, value]) => value);
        const marks = names.map(() => '?').join(', ');

        const result = await conexion.query(`
            INSERT INTO personal (${names.join(', ')}, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (${marks}, GETDATE())
        `, values);

        return result[0].id;
    } finally {
        await conexion.close();
    }
}

async function actualizar(id, data) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const existeSql = `
            SELECT id
            FROM personal
            WHERE (cedula = ? OR correo_institucional = ?)
              AND id <> ?
        `;

        const existente = await conexion.query(existeSql, [
            data.cedula,
            data.correoInstitucional,
            id
        ]);

        if (existente.length > 0) {
            throw new Error('Ya existe personal registrado con esa cedula o correo');
        }

        const columnas = await columnasPersonal(conexion);
        const campos = camposPersonal(data, columnas)
            .filter(([name]) => name !== 'password_hash');
        if (columnas.has('fecha_actualizacion')) {
            campos.push(['fecha_actualizacion', new Date()]);
        }

        const setSql = campos.map(([name]) => `${name} = ?`).join(', ');
        const values = campos.map(([, value]) => value);
        values.push(id);

        await conexion.query(`
            UPDATE personal
            SET ${setSql}
            WHERE id = ?
        `, values);

        const result = await conexion.query(`
            SELECT *
            FROM vw_personal_detalle
            WHERE id = ?
        `, [id]);

        return result[0] || null;
    } finally {
        await conexion.close();
    }
}

async function cambiarEstado(id, activo) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const columnas = await columnasPersonal(conexion);
        const updates = [];
        const params = [];

        if (columnas.has('activo')) {
            updates.push('activo = ?');
            params.push(activo ? 1 : 0);
        }

        if (columnas.has('estado_personal_id')) {
            const codigoEstado = activo ? 'ACTIVO' : 'INACTIVO';
            const estadoId = await obtenerDetalleId(conexion, 'ESTADOS_PERSONAL', codigoEstado);
            if (estadoId) {
                updates.push('estado_personal_id = ?');
                params.push(estadoId);
            }
        }

        if (columnas.has('fecha_actualizacion')) {
            updates.push('fecha_actualizacion = ?');
            params.push(new Date());
        }

        if (updates.length === 0) {
            throw new Error('La tabla personal no tiene columnas para actualizar estado');
        }

        params.push(id);
        await conexion.query(`
            UPDATE personal
            SET ${updates.join(', ')}
            WHERE id = ?
        `, params);

        return { id, activo: Boolean(activo) };
    } finally {
        await conexion.close();
    }
}

async function obtenerBasico(id) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const result = await conexion.query(`
            SELECT TOP 1 id, fecha_nacimiento
            FROM personal
            WHERE id = ?
        `, [id]);
        return result[0] || null;
    } finally {
        await conexion.close();
    }
}

async function actualizarPassword(id, passwordHash) {
    const pool = await getPool();
    const conexion = await pool.connect();

    try {
        const columnas = await columnasPersonal(conexion);
        if (!columnas.has('password_hash')) {
            throw new Error('Ejecute la migracion de Administracion para habilitar password_hash');
        }

        await conexion.query(
            'UPDATE personal SET password_hash = ? WHERE id = ?',
            [passwordHash, id]
        );
    } finally {
        await conexion.close();
    }
}

async function columnasPersonal(conexion) {
    const result = await conexion.query(`
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
          AND TABLE_NAME = 'personal'
    `);
    return new Set(result.map((row) => row.COLUMN_NAME || row.column_name));
}

function camposPersonal(data, columnas) {
    const campos = [
        ['cedula', data.cedula],
        ['nombres', data.nombres],
        ['apellidos', data.apellidos],
        ['correo_institucional', data.correoInstitucional],
        ['telefono', data.telefono],
        ['fecha_nacimiento', data.fechaNacimiento],
        ['fecha_ingreso', data.fechaIngreso],
        ['cargo_id', data.cargoId],
        ['area_id', data.areaId],
        ['jornada_id', data.jornadaId],
        ['grupo_id', data.grupoId],
        ['rol_id', data.rolId],
        ['estado_personal_id', data.estadoPersonalId],
        ['grado_id', data.gradoId],
        ['funcion_operativa_id', data.funcionOperativaId],
        ['tipo_rotacion_id', data.tipoRotacionId],
        ['password_hash', data.passwordHash]
    ];

    return campos.filter(([name, value]) => columnas.has(name) && value !== undefined);
}

async function obtenerDetalleId(conexion, catalogo, codigo) {
    try {
        const result = await conexion.query(`
            SELECT TOP 1 d.id
            FROM dbo.catalogo_detalles d
            INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
            WHERE c.codigo = ?
              AND d.codigo = ?
        `, [catalogo, codigo]);
        return result[0]?.id || null;
    } catch (error) {
        return null;
    }
}

module.exports = {
    obtenerTodo,
    obtenerOperativos,
    obtenerDisponibles,
    obtenerDisponiblesSinEvento,
    buscar,
    obtenerPerfil,
    actualizarPerfil,
    crear,
    actualizar,
    cambiarEstado,
    obtenerBasico,
    actualizarPassword
};
