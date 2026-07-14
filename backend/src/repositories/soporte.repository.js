const { query, transaction } = require('../config/db');

let schemaPromise;

/**
 * El módulo puede desplegarse antes de que se ejecute la migración. Crear el
 * esquema de forma idempotente evita que una tabla faltante afecte al resto de
 * la API y hace que las primeras peticiones concurrentes compartan el trabajo.
 */
function ensureSchema() {
    if (schemaPromise) return schemaPromise;

    schemaPromise = (async () => {
        await query(`
            IF OBJECT_ID('dbo.alertas_soporte', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.alertas_soporte (
                    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    codigo_alerta NVARCHAR(30) NULL,
                    titulo NVARCHAR(200) NOT NULL,
                    descripcion NVARCHAR(3000) NOT NULL,
                    usuario_id INT NOT NULL,
                    usuario_nombre NVARCHAR(200) NOT NULL,
                    rol NVARCHAR(100) NULL,
                    area NVARCHAR(150) NULL,
                    modulo NVARCHAR(100) NOT NULL,
                    prioridad NVARCHAR(20) NOT NULL CONSTRAINT DF_alertas_prioridad DEFAULT N'Media',
                    estado NVARCHAR(30) NOT NULL CONSTRAINT DF_alertas_estado DEFAULT N'Nuevo',
                    imagen NVARCHAR(500) NULL,
                    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_creacion DEFAULT SYSDATETIME(),
                    fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_actualizacion DEFAULT SYSDATETIME(),
                    asignado_a INT NULL,
                    asignado_nombre NVARCHAR(200) NULL,
                    fecha_primera_respuesta DATETIME2 NULL,
                    fecha_resolucion DATETIME2 NULL,
                    activo BIT NOT NULL CONSTRAINT DF_alertas_activo DEFAULT 1,
                    CONSTRAINT CK_alertas_prioridad CHECK (prioridad IN (N'Crítica',N'Alta',N'Media',N'Baja')),
                    CONSTRAINT CK_alertas_estado CHECK (estado IN (N'Nuevo',N'En proceso',N'Pendiente',N'Resuelto',N'Cancelado'))
                );
            END`);
        await query(`
            IF OBJECT_ID('dbo.alertas_soporte_comentarios', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.alertas_soporte_comentarios (
                    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    alerta_id BIGINT NOT NULL,
                    usuario_id INT NOT NULL,
                    usuario_nombre NVARCHAR(200) NOT NULL,
                    rol NVARCHAR(100) NULL,
                    comentario NVARCHAR(3000) NOT NULL,
                    es_interno BIT NOT NULL CONSTRAINT DF_alertas_comentario_interno DEFAULT 0,
                    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_comentario_fecha DEFAULT SYSDATETIME(),
                    CONSTRAINT FK_alertas_comentarios_alerta FOREIGN KEY (alerta_id) REFERENCES dbo.alertas_soporte(id)
                );
            END`);
        await query(`
            IF OBJECT_ID('dbo.alertas_soporte_historial', 'U') IS NULL
            BEGIN
                CREATE TABLE dbo.alertas_soporte_historial (
                    id BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
                    alerta_id BIGINT NOT NULL,
                    usuario_id INT NOT NULL,
                    usuario_nombre NVARCHAR(200) NOT NULL,
                    accion NVARCHAR(100) NOT NULL,
                    valor_anterior NVARCHAR(300) NULL,
                    valor_nuevo NVARCHAR(300) NULL,
                    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_historial_fecha DEFAULT SYSDATETIME(),
                    CONSTRAINT FK_alertas_historial_alerta FOREIGN KEY (alerta_id) REFERENCES dbo.alertas_soporte(id)
                );
            END`);
        await query(`
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_alertas_soporte_usuario_fecha' AND object_id=OBJECT_ID('dbo.alertas_soporte'))
                CREATE INDEX IX_alertas_soporte_usuario_fecha ON dbo.alertas_soporte(usuario_id, fecha_creacion DESC) INCLUDE (estado, prioridad, modulo, activo);
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_alertas_soporte_estado_prioridad' AND object_id=OBJECT_ID('dbo.alertas_soporte'))
                CREATE INDEX IX_alertas_soporte_estado_prioridad ON dbo.alertas_soporte(activo, estado, prioridad, fecha_creacion DESC) INCLUDE (usuario_id, modulo, asignado_a);
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_alertas_comentarios_alerta' AND object_id=OBJECT_ID('dbo.alertas_soporte_comentarios'))
                CREATE INDEX IX_alertas_comentarios_alerta ON dbo.alertas_soporte_comentarios(alerta_id, fecha_creacion);
            IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_alertas_historial_alerta' AND object_id=OBJECT_ID('dbo.alertas_soporte_historial'))
                CREATE INDEX IX_alertas_historial_alerta ON dbo.alertas_soporte_historial(alerta_id, fecha_creacion);`);
    })().catch((error) => {
        schemaPromise = undefined;
        throw error;
    });

    return schemaPromise;
}

function whereFor(filters, user) {
    const clauses = ['a.activo = 1'];
    const params = [];
    if (user.rol !== 'ADMINISTRADOR') {
        clauses.push('a.usuario_id = ?');
        params.push(Number(user.id));
    }
    if (filters.estado) { clauses.push('a.estado = ?'); params.push(filters.estado); }
    if (filters.prioridad) { clauses.push('a.prioridad = ?'); params.push(filters.prioridad); }
    if (filters.modulo) { clauses.push('a.modulo = ?'); params.push(filters.modulo); }
    if (filters.usuario) { clauses.push('a.usuario_nombre LIKE ?'); params.push(`%${filters.usuario}%`); }
    if (filters.area) { clauses.push('a.area = ?'); params.push(filters.area); }
    if (filters.desde) { clauses.push('a.fecha_creacion >= ?'); params.push(filters.desde); }
    if (filters.buscar) {
        clauses.push('(a.titulo LIKE ? OR a.descripcion LIKE ? OR a.codigo_alerta LIKE ? OR a.usuario_nombre LIKE ?)');
        const value = `%${filters.buscar}%`;
        params.push(value, value, value, value);
    }
    return { sql: clauses.join(' AND '), params };
}

async function listar(filters, user) {
    const page = Math.max(1, Number(filters.page) || 1);
    const pageSize = Math.min(100, Math.max(5, Number(filters.pageSize) || 20));
    const where = whereFor(filters, user);
    const rows = await query(`
        SELECT a.*
        FROM dbo.alertas_soporte a
        WHERE ${where.sql}
        ORDER BY a.fecha_creacion DESC
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY`, [...where.params, (page - 1) * pageSize, pageSize]);
    const count = await query(`SELECT COUNT_BIG(1) total FROM dbo.alertas_soporte a WHERE ${where.sql}`, where.params);
    return { datos: rows, total: Number(count[0]?.total || 0), page, pageSize };
}

async function estadisticas(user) {
    const own = user.rol === 'ADMINISTRADOR' ? '' : ' AND usuario_id = ?';
    const params = user.rol === 'ADMINISTRADOR' ? [] : [Number(user.id)];
    const rows = await query(`
        SELECT COUNT_BIG(1) total,
          SUM(CASE WHEN prioridad='Crítica' THEN 1 ELSE 0 END) criticas,
          SUM(CASE WHEN prioridad='Alta' THEN 1 ELSE 0 END) altas,
          SUM(CASE WHEN prioridad='Media' THEN 1 ELSE 0 END) medias,
          SUM(CASE WHEN prioridad='Baja' THEN 1 ELSE 0 END) bajas,
          SUM(CASE WHEN estado NOT IN ('Resuelto','Cancelado') THEN 1 ELSE 0 END) pendientes,
          AVG(CASE WHEN fecha_primera_respuesta IS NOT NULL THEN DATEDIFF(MINUTE, fecha_creacion, fecha_primera_respuesta) END) promedio_minutos
        FROM dbo.alertas_soporte WHERE activo=1${own}`, params);
    return rows[0] || {};
}

async function detalle(id, user) {
    const params = [Number(id)];
    let access = '';
    if (user.rol !== 'ADMINISTRADOR') { access = ' AND usuario_id = ?'; params.push(Number(user.id)); }
    const tickets = await query(`SELECT * FROM dbo.alertas_soporte WHERE id=? AND activo=1${access}`, params);
    if (!tickets[0]) return null;
    const comentarios = await query(`SELECT * FROM dbo.alertas_soporte_comentarios WHERE alerta_id=? ${user.rol === 'ADMINISTRADOR' ? '' : 'AND es_interno=0'} ORDER BY fecha_creacion`, [Number(id)]);
    const historial = await query('SELECT * FROM dbo.alertas_soporte_historial WHERE alerta_id=? ORDER BY fecha_creacion', [Number(id)]);
    return { alerta: tickets[0], comentarios, historial };
}

async function crear(data, user) {
    return transaction(async (cx) => {
        const profile = await cx.query(`SELECT TOP 1 p.nombres, p.apellidos, r.nombre rol, ar.nombre area FROM dbo.personal p LEFT JOIN dbo.roles r ON r.id=p.rol_id LEFT JOIN dbo.catalogo_detalles ar ON ar.id=p.area_id WHERE p.id=?`, [Number(user.id)]);
        const row = profile[0] || {};
        const name = `${row.nombres || user.nombres || ''} ${row.apellidos || user.apellidos || ''}`.trim() || user.nombreCompleto || user.correo;
        const inserted = await cx.query(`INSERT INTO dbo.alertas_soporte (titulo,descripcion,usuario_id,usuario_nombre,rol,area,modulo,prioridad,imagen) OUTPUT INSERTED.id VALUES (?,?,?,?,?,?,?,?,?)`, [data.titulo, data.descripcion, Number(user.id), name, row.rol || user.rol, row.area || null, data.modulo, data.prioridad, data.imagen || null]);
        const id = Number(inserted[0].id);
        const code = `ALT-${new Date().getFullYear()}-${id.toString().padStart(6, '0')}`;
        await cx.query('UPDATE dbo.alertas_soporte SET codigo_alerta=? WHERE id=?', [code, id]);
        await cx.query(`INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_id,usuario_nombre,accion,valor_nuevo) VALUES (?,?,?,?,?)`, [id, Number(user.id), name, 'Reporte creado', 'Nuevo']);
        return { id, codigo_alerta: code, usuario_id: Number(user.id), titulo: data.titulo };
    });
}

async function actualizar(id, changes, user) {
    return transaction(async (cx) => {
        const currentRows = await cx.query('SELECT * FROM dbo.alertas_soporte WHERE id=? AND activo=1', [Number(id)]);
        const current = currentRows[0];
        if (!current) return null;
        const name = user.nombreCompleto || `${user.nombres || ''} ${user.apellidos || ''}`.trim() || user.correo;
        if (changes.estado && changes.estado !== current.estado) {
            await cx.query(`UPDATE dbo.alertas_soporte SET estado=?, fecha_actualizacion=SYSDATETIME(), fecha_primera_respuesta=COALESCE(fecha_primera_respuesta,SYSDATETIME()), fecha_resolucion=CASE WHEN ?='Resuelto' THEN SYSDATETIME() ELSE fecha_resolucion END WHERE id=?`, [changes.estado, changes.estado, Number(id)]);
            await cx.query(`INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_id,usuario_nombre,accion,valor_anterior,valor_nuevo) VALUES (?,?,?,?,?,?)`, [Number(id), Number(user.id), name, 'Cambio de estado', current.estado, changes.estado]);
        }
        if (changes.prioridad && changes.prioridad !== current.prioridad) {
            await cx.query('UPDATE dbo.alertas_soporte SET prioridad=?, fecha_actualizacion=SYSDATETIME() WHERE id=?', [changes.prioridad, Number(id)]);
            await cx.query(`INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_id,usuario_nombre,accion,valor_anterior,valor_nuevo) VALUES (?,?,?,?,?,?)`, [Number(id), Number(user.id), name, 'Cambio de prioridad', current.prioridad, changes.prioridad]);
        }
        if (changes.asignadoA !== undefined) {
            await cx.query('UPDATE dbo.alertas_soporte SET asignado_a=?, asignado_nombre=?, estado=CASE WHEN estado=\'Nuevo\' THEN \'En proceso\' ELSE estado END, fecha_actualizacion=SYSDATETIME(), fecha_primera_respuesta=COALESCE(fecha_primera_respuesta,SYSDATETIME()) WHERE id=?', [changes.asignadoA || null, changes.asignadoNombre || null, Number(id)]);
            await cx.query(`INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_id,usuario_nombre,accion,valor_nuevo) VALUES (?,?,?,?,?)`, [Number(id), Number(user.id), name, 'Asignación', changes.asignadoNombre || 'Sin asignar']);
        }
        const next = await cx.query('SELECT * FROM dbo.alertas_soporte WHERE id=?', [Number(id)]);
        return next[0];
    });
}

async function comentar(id, comentario, interno, user) {
    const ticket = await query('SELECT * FROM dbo.alertas_soporte WHERE id=? AND activo=1', [Number(id)]);
    if (!ticket[0]) return null;
    const name = user.nombreCompleto || `${user.nombres || ''} ${user.apellidos || ''}`.trim() || user.correo;
    await query(`INSERT INTO dbo.alertas_soporte_comentarios(alerta_id,usuario_id,usuario_nombre,rol,comentario,es_interno) VALUES (?,?,?,?,?,?)`, [Number(id), Number(user.id), name, user.rol, comentario, interno ? 1 : 0]);
    await query(`UPDATE dbo.alertas_soporte SET fecha_actualizacion=SYSDATETIME(), fecha_primera_respuesta=CASE WHEN ?=1 THEN COALESCE(fecha_primera_respuesta,SYSDATETIME()) ELSE fecha_primera_respuesta END WHERE id=?`, [user.rol === 'ADMINISTRADOR' ? 1 : 0, Number(id)]);
    return ticket[0];
}

module.exports = { ensureSchema, listar, estadisticas, detalle, crear, actualizar, comentar };
