USE BITSAC;
GO

IF OBJECT_ID('dbo.roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.roles (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(80) NOT NULL UNIQUE,
        descripcion NVARCHAR(255) NULL,
        activo BIT NOT NULL DEFAULT 1,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NULL
    );
END;
GO

IF OBJECT_ID('dbo.permisos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.permisos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(120) NOT NULL UNIQUE,
        descripcion NVARCHAR(255) NULL,
        modulo NVARCHAR(80) NOT NULL,
        activo BIT NOT NULL DEFAULT 1,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

IF OBJECT_ID('dbo.rol_permiso', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_permiso (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        permiso_id INT NOT NULL,
        fecha_asignacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_rol_permiso_roles FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_permiso_permisos FOREIGN KEY (permiso_id) REFERENCES dbo.permisos(id),
        CONSTRAINT UQ_rol_permiso UNIQUE (rol_id, permiso_id)
    );
END;
GO

IF OBJECT_ID('dbo.auditoria', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoria (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        usuario_id INT NULL,
        accion NVARCHAR(80) NOT NULL,
        modulo NVARCHAR(80) NOT NULL,
        tabla_afectada NVARCHAR(120) NULL,
        registro_id NVARCHAR(80) NULL,
        metodo NVARCHAR(12) NOT NULL,
        endpoint NVARCHAR(500) NOT NULL,
        ip NVARCHAR(80) NULL,
        user_agent NVARCHAR(500) NULL,
        datos_anteriores NVARCHAR(MAX) NULL,
        datos_nuevos NVARCHAR(MAX) NULL,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
END;
GO

DECLARE @roles TABLE (nombre NVARCHAR(80), descripcion NVARCHAR(255));
INSERT INTO @roles (nombre, descripcion)
VALUES
('Administrador', 'Control total del sistema'),
('Operaciones', 'Gestion operativa diaria'),
('Supervisor', 'Encargado de servicio asignado'),
('Inspector', 'Consulta y reporte operativo territorial'),
('Agente', 'Usuario operativo basico'),
('Comunicaciones', 'Gestion del modulo Eventos'),
('Consulta', 'Solo lectura general'),
('Auditoria', 'Control interno y trazabilidad');

MERGE dbo.roles AS target
USING @roles AS source
ON target.nombre = source.nombre
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, activo = 1, fecha_actualizacion = SYSDATETIME()
WHEN NOT MATCHED THEN
    INSERT (nombre, descripcion) VALUES (source.nombre, source.descripcion);
GO

DECLARE @permisos TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255), modulo NVARCHAR(80));
INSERT INTO @permisos (codigo, descripcion, modulo)
VALUES
('usuarios.ver','Ver usuarios','usuarios'),
('usuarios.crear','Crear usuarios','usuarios'),
('usuarios.editar','Editar usuarios','usuarios'),
('usuarios.eliminar','Eliminar usuarios','usuarios'),
('roles.ver','Ver roles','roles'),
('roles.crear','Crear roles','roles'),
('roles.editar','Editar roles','roles'),
('roles.eliminar','Eliminar roles','roles'),
('permisos.ver','Ver permisos','permisos'),
('personal.ver','Ver personal','personal'),
('personal.ver_asignado','Ver personal asignado','personal'),
('personal.crear','Crear personal','personal'),
('personal.editar','Editar personal','personal'),
('personal.editar_estado','Editar estado de personal','personal'),
('personal.eliminar','Eliminar personal','personal'),
('servicios.ver','Ver servicios','servicios'),
('servicios.ver_asignado','Ver servicios asignados','servicios'),
('servicios.crear','Crear servicios','servicios'),
('servicios.editar','Editar servicios','servicios'),
('servicios.eliminar','Eliminar servicios','servicios'),
('servicios.reemplazar_personal','Reemplazar personal de servicio','servicios'),
('servicios.aprobar_cambios','Aprobar cambios de servicio','servicios'),
('servicios.planificacion_manual','Planificacion manual','servicios'),
('servicios.planificacion_automatica','Planificacion automatica','servicios'),
('jornadas.ver','Ver jornadas','jornadas'),
('jornadas.crear','Crear jornadas','jornadas'),
('jornadas.editar','Editar jornadas','jornadas'),
('horarios.ver','Ver horarios','horarios'),
('horarios.crear','Crear horarios','horarios'),
('horarios.editar','Editar horarios','horarios'),
('grupos.ver','Ver grupos','grupos'),
('grupos.crear','Crear grupos','grupos'),
('grupos.editar','Editar grupos','grupos'),
('francos.ver','Ver francos','francos'),
('francos.crear','Crear francos','francos'),
('francos.editar','Editar francos','francos'),
('areas.ver','Ver areas','areas'),
('areas.crear','Crear areas','areas'),
('areas.editar','Editar areas','areas'),
('cargos.ver','Ver cargos','cargos'),
('cargos.crear','Crear cargos','cargos'),
('cargos.editar','Editar cargos','cargos'),
('eventos.ver','Ver eventos','eventos'),
('eventos.ver_convocado','Ver eventos convocado','eventos'),
('eventos.crear','Crear eventos','eventos'),
('eventos.editar','Editar eventos','eventos'),
('eventos.eliminar','Eliminar eventos','eventos'),
('eventos.publicar','Publicar eventos','eventos'),
('eventos.convocar','Convocar personal','eventos'),
('eventos.adjuntos','Gestionar adjuntos de eventos','eventos'),
('eventos.ubicacion','Gestionar ubicacion de eventos','eventos'),
('eventos.asistencia','Gestionar asistencia de eventos','eventos'),
('eventos.confirmar_asistencia','Confirmar asistencia propia','eventos'),
('eventos.reportes','Reportes de eventos','eventos'),
('anuncios.ver','Ver anuncios','anuncios'),
('anuncios.crear','Crear anuncios','anuncios'),
('anuncios.editar','Editar anuncios','anuncios'),
('anuncios.eliminar','Eliminar anuncios','anuncios'),
('cartillas.ver','Ver cartillas','cartillas'),
('cartillas.generar','Generar cartillas','cartillas'),
('reportes.ver','Ver reportes','reportes'),
('reportes.ver_servicio','Ver reportes de servicio','reportes'),
('reportes.exportar','Exportar reportes','reportes'),
('reportes.exportar_eventos','Exportar reportes de eventos','reportes'),
('novedades.ver','Ver novedades','novedades'),
('novedades.crear','Crear novedades','novedades'),
('novedades.crear_personal','Crear novedad personal','novedades'),
('novedades.editar','Editar novedades','novedades'),
('incidencias.ver','Ver incidencias','incidencias'),
('incidencias.crear','Crear incidencias','incidencias'),
('asistencia.registrar','Registrar asistencia','asistencia'),
('asistencia.confirmar','Confirmar asistencia','asistencia'),
('perfil.ver','Ver perfil','perfil'),
('horario.ver','Ver horario propio','horario'),
('servicio.ver_propio','Ver servicio propio','servicios'),
('consignas.ver','Ver consignas','consignas'),
('sugerencias.crear','Crear sugerencias','sugerencias'),
('auditoria.ver','Ver auditoria','auditoria'),
('auditoria.detalle','Ver detalle de auditoria','auditoria'),
('auditoria.exportar','Exportar auditoria','auditoria'),
('bitacoras.ver','Ver bitacoras','bitacoras'),
('bitacoras.detalle','Ver detalle de bitacoras','bitacoras'),
('estadisticas.ver','Ver estadisticas','estadisticas'),
('configuracion.ver','Ver configuracion','configuracion'),
('configuracion.editar','Editar configuracion','configuracion');

MERGE dbo.permisos AS target
USING @permisos AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, modulo = source.modulo, activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, descripcion, modulo) VALUES (source.codigo, source.descripcion, source.modulo);
GO

DECLARE @asignaciones TABLE (rol NVARCHAR(80), permiso NVARCHAR(120));

INSERT INTO @asignaciones (rol, permiso)
SELECT 'Administrador', codigo FROM dbo.permisos;

INSERT INTO @asignaciones (rol, permiso)
VALUES
('Operaciones','personal.ver'),('Operaciones','personal.editar_estado'),
('Operaciones','servicios.ver'),('Operaciones','servicios.crear'),('Operaciones','servicios.editar'),
('Operaciones','servicios.reemplazar_personal'),('Operaciones','servicios.aprobar_cambios'),('Operaciones','servicios.planificacion_manual'),
('Operaciones','novedades.ver'),('Operaciones','novedades.crear'),('Operaciones','novedades.editar'),
('Operaciones','eventos.ver'),('Operaciones','eventos.crear'),('Operaciones','eventos.editar'),
('Operaciones','anuncios.ver'),('Operaciones','anuncios.crear'),('Operaciones','anuncios.editar'),
('Operaciones','cartillas.ver'),('Operaciones','cartillas.generar'),('Operaciones','reportes.ver'),('Operaciones','reportes.exportar'),('Operaciones','auditoria.ver'),
('Supervisor','personal.ver_asignado'),('Supervisor','servicios.ver_asignado'),('Supervisor','asistencia.registrar'),('Supervisor','asistencia.confirmar'),
('Supervisor','novedades.ver'),('Supervisor','novedades.crear'),('Supervisor','eventos.ver'),('Supervisor','cartillas.ver'),('Supervisor','reportes.ver_servicio'),
('Inspector','personal.ver'),('Inspector','servicios.ver'),('Inspector','novedades.ver'),('Inspector','novedades.crear'),('Inspector','incidencias.ver'),('Inspector','incidencias.crear'),('Inspector','eventos.ver'),('Inspector','cartillas.ver'),('Inspector','reportes.ver'),
('Agente','perfil.ver'),('Agente','horario.ver'),('Agente','servicio.ver_propio'),('Agente','consignas.ver'),('Agente','eventos.ver_convocado'),('Agente','eventos.confirmar_asistencia'),('Agente','anuncios.ver'),('Agente','cartillas.ver'),('Agente','sugerencias.crear'),('Agente','novedades.crear_personal'),
('Comunicaciones','eventos.ver'),('Comunicaciones','eventos.crear'),('Comunicaciones','eventos.editar'),('Comunicaciones','eventos.eliminar'),('Comunicaciones','eventos.publicar'),('Comunicaciones','eventos.convocar'),('Comunicaciones','eventos.adjuntos'),('Comunicaciones','eventos.ubicacion'),('Comunicaciones','eventos.asistencia'),('Comunicaciones','eventos.reportes'),('Comunicaciones','reportes.exportar_eventos'),
('Consulta','personal.ver'),('Consulta','servicios.ver'),('Consulta','eventos.ver'),('Consulta','cartillas.ver'),('Consulta','reportes.ver'),
('Auditoria','auditoria.ver'),('Auditoria','auditoria.detalle'),('Auditoria','auditoria.exportar'),('Auditoria','bitacoras.ver'),('Auditoria','bitacoras.detalle'),('Auditoria','usuarios.ver'),('Auditoria','roles.ver'),('Auditoria','permisos.ver'),('Auditoria','personal.ver'),('Auditoria','servicios.ver'),('Auditoria','eventos.ver'),('Auditoria','cartillas.ver'),('Auditoria','reportes.ver'),('Auditoria','novedades.ver');

INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM @asignaciones a
INNER JOIN dbo.roles r ON r.nombre = a.rol
INNER JOIN dbo.permisos p ON p.codigo = a.permiso
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.rol_permiso rp
    WHERE rp.rol_id = r.id
      AND rp.permiso_id = p.id
);
GO
