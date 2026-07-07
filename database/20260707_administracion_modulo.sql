USE BITSAC;
GO

IF OBJECT_ID('dbo.catalogos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.catalogos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(80) NOT NULL UNIQUE,
        nombre NVARCHAR(120) NOT NULL,
        descripcion NVARCHAR(255) NULL,
        estado BIT NOT NULL CONSTRAINT DF_catalogos_estado DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_catalogos_fecha DEFAULT (SYSDATETIME())
    );
END;
GO

IF OBJECT_ID('dbo.catalogo_detalles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.catalogo_detalles (
        id INT IDENTITY(1,1) PRIMARY KEY,
        catalogo_id INT NOT NULL,
        codigo NVARCHAR(80) NOT NULL,
        nombre NVARCHAR(160) NOT NULL,
        descripcion NVARCHAR(255) NULL,
        orden INT NOT NULL CONSTRAINT DF_catalogo_detalles_orden DEFAULT (0),
        estado BIT NOT NULL CONSTRAINT DF_catalogo_detalles_estado DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_catalogo_detalles_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_catalogo_detalles_catalogos FOREIGN KEY (catalogo_id) REFERENCES dbo.catalogos(id),
        CONSTRAINT UQ_catalogo_detalles_codigo UNIQUE (catalogo_id, codigo)
    );
END;
GO

IF COL_LENGTH('dbo.catalogos', 'descripcion') IS NULL
    ALTER TABLE dbo.catalogos ADD descripcion NVARCHAR(255) NULL;
GO

IF COL_LENGTH('dbo.catalogo_detalles', 'fecha_actualizacion') IS NULL
    ALTER TABLE dbo.catalogo_detalles ADD fecha_actualizacion DATETIME2 NULL;
GO

DECLARE @catalogosAdmin TABLE (codigo NVARCHAR(80), nombre NVARCHAR(120), descripcion NVARCHAR(255));
INSERT INTO @catalogosAdmin (codigo, nombre, descripcion)
VALUES
('GRADOS', N'Grados', N'Grados institucionales del personal'),
('AREAS', N'Areas', N'Areas institucionales'),
('FUNCIONES_OPERATIVAS', N'Funciones Operativas', N'Funciones operativas del personal'),
('GRUPOS', N'Grupos', N'Grupos operativos'),
('JORNADAS', N'Jornadas', N'Jornadas laborales'),
('TIPOS_ROTACION', N'Tipos de Rotacion', N'Tipos de rotacion del personal'),
('ESTADOS_PERSONAL', N'Estados de Personal', N'Estados de cuenta institucional'),
('DISTRITOS', N'Distritos / Unidades Operativas', N'Distritos o unidades operativas'),
('SUBUNIDADES_OPERATIVAS', N'Subunidades Operativas', N'Subunidades por distrito'),
('TIPOS_SERVICIO_LUGAR', N'Tipos de Servicio', N'Tipos de lugares de servicio'),
('TIPOS_MOVIL', N'Tipos de Movil', N'Tipos de vehiculos o medios'),
('ESTADOS_MOVIL', N'Estados de Movil', N'Estados operativos de moviles'),
('ESTADOS_ASIGNACION_MOVIL', N'Estados de Asignacion de Moviles', N'Estados de asignacion movil-EAS');

MERGE dbo.catalogos AS target
USING @catalogosAdmin AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, descripcion = source.descripcion, estado = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, nombre, descripcion, estado) VALUES (source.codigo, source.nombre, source.descripcion, 1);
GO

DECLARE @detalles TABLE (catalogo NVARCHAR(80), codigo NVARCHAR(80), nombre NVARCHAR(160), orden INT);
INSERT INTO @detalles (catalogo, codigo, nombre, orden)
VALUES
('GRADOS','AGENTE',N'Agente',10),
('GRADOS','CABO',N'Cabo',20),
('GRADOS','SARGENTO',N'Sargento',30),
('GRADOS','TENIENTE',N'Teniente',40),
('AREAS','OPERATIVA',N'Operativa',10),
('AREAS','ADMINISTRATIVA',N'Administrativa',20),
('AREAS','COMUNICACIONES',N'Comunicaciones',30),
('FUNCIONES_OPERATIVAS','RADIOPERADOR',N'Radioperador',10),
('FUNCIONES_OPERATIVAS','ENCARGADO',N'Encargado',20),
('FUNCIONES_OPERATIVAS','PATRULLAJE',N'Patrullaje',30),
('FUNCIONES_OPERATIVAS','ADMINISTRATIVO',N'Administrativo',40),
('GRUPOS','GRUPO_A',N'Grupo A',10),
('GRUPOS','GRUPO_B',N'Grupo B',20),
('JORNADAS','DIURNA',N'Diurna',10),
('JORNADAS','NOCTURNA',N'Nocturna',20),
('JORNADAS','ROTATIVA',N'Rotativa',30),
('TIPOS_ROTACION','FIJA',N'Fija',10),
('TIPOS_ROTACION','ROTATIVA',N'Rotativa',20),
('ESTADOS_PERSONAL','ACTIVO',N'Activo',10),
('ESTADOS_PERSONAL','INACTIVO',N'Inactivo',20),
('DISTRITOS','MODELO',N'Distrito Modelo',10),
('DISTRITOS','SUR',N'Distrito Sur',20),
('DISTRITOS','NORTE',N'Distrito Norte',30),
('SUBUNIDADES_OPERATIVAS','CENTRAL',N'Central',10),
('SUBUNIDADES_OPERATIVAS','EAS',N'EAS',20),
('TIPOS_SERVICIO_LUGAR','EAS',N'EAS',10),
('TIPOS_SERVICIO_LUGAR','PEDESTRE',N'Pedestre',20),
('TIPOS_SERVICIO_LUGAR','MOTORIZADO',N'Motorizado',30),
('TIPOS_SERVICIO_LUGAR','CICLISTA',N'Ciclista',40),
('TIPOS_SERVICIO_LUGAR','ADMINISTRATIVO',N'Administrativo',50),
('TIPOS_SERVICIO_LUGAR','AMBIENTE',N'Ambiente',60),
('TIPOS_SERVICIO_LUGAR','K9',N'K9',70),
('TIPOS_SERVICIO_LUGAR','OTRO',N'Otro',80),
('TIPOS_MOVIL','CAMIONETA',N'Camioneta',10),
('TIPOS_MOVIL','MOTOCICLETA',N'Motocicleta',20),
('TIPOS_MOVIL','BICICLETA',N'Bicicleta',30),
('TIPOS_MOVIL','OTRO',N'Otro',40),
('ESTADOS_MOVIL','OPERATIVO',N'Operativo',10),
('ESTADOS_MOVIL','MANTENIMIENTO',N'Mantenimiento',20),
('ESTADOS_MOVIL','INACTIVO',N'Inactivo',30),
('ESTADOS_ASIGNACION_MOVIL','ACTIVA',N'Activa',10),
('ESTADOS_ASIGNACION_MOVIL','INACTIVA',N'Inactiva',20);

MERGE dbo.catalogo_detalles AS target
USING (
    SELECT c.id AS catalogo_id, d.codigo, d.nombre, d.orden
    FROM @detalles d
    INNER JOIN dbo.catalogos c ON c.codigo = d.catalogo
) AS source
ON target.catalogo_id = source.catalogo_id AND target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, orden = source.orden, estado = 1, fecha_actualizacion = SYSDATETIME()
WHEN NOT MATCHED THEN
    INSERT (catalogo_id, codigo, nombre, orden, estado)
    VALUES (source.catalogo_id, source.codigo, source.nombre, source.orden, 1);
GO

IF OBJECT_ID('dbo.personal', 'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.personal', 'password_hash') IS NULL
        ALTER TABLE dbo.personal ADD password_hash NVARCHAR(255) NULL;

    IF COL_LENGTH('dbo.personal', 'grado_id') IS NULL
        ALTER TABLE dbo.personal ADD grado_id INT NULL;

    IF COL_LENGTH('dbo.personal', 'funcion_operativa_id') IS NULL
        ALTER TABLE dbo.personal ADD funcion_operativa_id INT NULL;

    IF COL_LENGTH('dbo.personal', 'tipo_rotacion_id') IS NULL
        ALTER TABLE dbo.personal ADD tipo_rotacion_id INT NULL;

    IF COL_LENGTH('dbo.personal', 'fecha_actualizacion') IS NULL
        ALTER TABLE dbo.personal ADD fecha_actualizacion DATETIME2 NULL;

    IF COL_LENGTH('dbo.personal', 'activo') IS NULL
        ALTER TABLE dbo.personal ADD activo BIT NOT NULL CONSTRAINT DF_personal_activo DEFAULT (1);
END;
GO

IF OBJECT_ID('dbo.lugares_servicio', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.lugares_servicio (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(180) NOT NULL,
        direccion NVARCHAR(300) NOT NULL,
        distrito_id INT NOT NULL,
        subunidad_operativa_id INT NULL,
        tipo_servicio_id INT NOT NULL,
        observacion NVARCHAR(500) NULL,
        activo BIT NOT NULL CONSTRAINT DF_lugares_servicio_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_lugares_servicio_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_lugares_servicio_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_lugares_servicio_subunidad FOREIGN KEY (subunidad_operativa_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_lugares_servicio_tipo FOREIGN KEY (tipo_servicio_id) REFERENCES dbo.catalogo_detalles(id)
    );
END;
GO

IF OBJECT_ID('dbo.eas_estaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.eas_estaciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(40) NOT NULL UNIQUE,
        nombre NVARCHAR(160) NOT NULL,
        direccion NVARCHAR(300) NULL,
        distrito_id INT NULL,
        activo BIT NOT NULL CONSTRAINT DF_eas_estaciones_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_eas_estaciones_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL
    );
END;
GO

IF COL_LENGTH('dbo.eas_estaciones', 'direccion') IS NULL
    ALTER TABLE dbo.eas_estaciones ADD direccion NVARCHAR(300) NULL;
GO
IF COL_LENGTH('dbo.eas_estaciones', 'distrito_id') IS NULL
    ALTER TABLE dbo.eas_estaciones ADD distrito_id INT NULL;
GO
IF COL_LENGTH('dbo.eas_estaciones', 'fecha_actualizacion') IS NULL
    ALTER TABLE dbo.eas_estaciones ADD fecha_actualizacion DATETIME2 NULL;
GO

IF OBJECT_ID('dbo.moviles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.moviles (
        id INT IDENTITY(1,1) PRIMARY KEY,
        numero_movil NVARCHAR(40) NOT NULL UNIQUE,
        placa NVARCHAR(40) NULL,
        tipo_movil_id INT NOT NULL,
        kilometraje_actual INT NOT NULL CONSTRAINT DF_moviles_km_actual DEFAULT (0),
        kilometraje_ultimo_mantenimiento INT NOT NULL CONSTRAINT DF_moviles_km_mant DEFAULT (0),
        proximo_mantenimiento AS (kilometraje_ultimo_mantenimiento + 5000) PERSISTED,
        estado_movil_id INT NOT NULL,
        observacion NVARCHAR(500) NULL,
        activo BIT NOT NULL CONSTRAINT DF_moviles_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_moviles_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_moviles_tipo FOREIGN KEY (tipo_movil_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_moviles_estado FOREIGN KEY (estado_movil_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT CK_moviles_km CHECK (kilometraje_actual >= 0 AND kilometraje_ultimo_mantenimiento >= 0)
    );
END;
GO

IF OBJECT_ID('dbo.movil_eas_asignaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.movil_eas_asignaciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        eas_id INT NOT NULL,
        movil_id INT NOT NULL,
        fecha_asignacion DATETIME2 NOT NULL CONSTRAINT DF_movil_eas_fecha DEFAULT (SYSDATETIME()),
        estado_asignacion_id INT NOT NULL,
        observacion NVARCHAR(500) NULL,
        activo BIT NOT NULL CONSTRAINT DF_movil_eas_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_movil_eas_fecha_creacion DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_movil_eas_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id),
        CONSTRAINT FK_movil_eas_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id),
        CONSTRAINT FK_movil_eas_estado FOREIGN KEY (estado_asignacion_id) REFERENCES dbo.catalogo_detalles(id)
    );
END;
GO

IF COL_LENGTH('dbo.movil_eas_asignaciones', 'activo') IS NULL
    ALTER TABLE dbo.movil_eas_asignaciones ADD activo BIT NOT NULL CONSTRAINT DF_movil_eas_activo DEFAULT (1);
GO

;WITH asignaciones AS (
    SELECT id,
           ROW_NUMBER() OVER (
               PARTITION BY movil_id
               ORDER BY fecha_asignacion DESC, id DESC
           ) AS rn
    FROM dbo.movil_eas_asignaciones
    WHERE activo = 1
)
UPDATE asignaciones
SET activo = CASE WHEN rn = 1 THEN 1 ELSE 0 END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_movil_eas_asignacion_activa' AND object_id = OBJECT_ID('dbo.movil_eas_asignaciones'))
BEGIN
    CREATE UNIQUE INDEX UX_movil_eas_asignacion_activa
    ON dbo.movil_eas_asignaciones (movil_id)
    WHERE activo = 1;
END;
GO

IF OBJECT_ID('dbo.roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.roles (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(80) NOT NULL UNIQUE,
        descripcion NVARCHAR(255) NULL,
        activo BIT NOT NULL CONSTRAINT DF_roles_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_roles_fecha DEFAULT (SYSDATETIME()),
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
        activo BIT NOT NULL CONSTRAINT DF_permisos_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_permisos_fecha DEFAULT (SYSDATETIME())
    );
END;
GO

IF OBJECT_ID('dbo.rol_permiso', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_permiso (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        permiso_id INT NOT NULL,
        fecha_asignacion DATETIME2 NOT NULL CONSTRAINT DF_rol_permiso_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_rol_permiso_roles FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_permiso_permisos FOREIGN KEY (permiso_id) REFERENCES dbo.permisos(id),
        CONSTRAINT UQ_rol_permiso UNIQUE (rol_id, permiso_id)
    );
END;
GO

DECLARE @rolesAdmin TABLE (nombre NVARCHAR(80), descripcion NVARCHAR(255));
INSERT INTO @rolesAdmin (nombre, descripcion)
VALUES
(N'Administrador', N'Acceso total'),
(N'Operaciones', N'Gestion de servicios, eventos, lugares, EAS y moviles'),
(N'Auditor', N'Consulta, auditoria, historial y exportacion'),
(N'Radioperador SEGURA EP', N'Dashboards, ingresos, salidas, novedades y cartillas'),
(N'Encargado', N'Reportes, personal asignado y cartillas'),
(N'Comunicaciones', N'Administracion exclusiva del modulo Eventos'),
(N'Personal Operativo', N'Consulta de informacion propia');

MERGE dbo.roles AS target
USING @rolesAdmin AS source
ON target.nombre = source.nombre
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, activo = 1, fecha_actualizacion = SYSDATETIME()
WHEN NOT MATCHED THEN
    INSERT (nombre, descripcion, activo) VALUES (source.nombre, source.descripcion, 1);
GO

DECLARE @permisosAdmin TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255), modulo NVARCHAR(80));
INSERT INTO @permisosAdmin (codigo, descripcion, modulo)
VALUES
('administracion.ver',N'Ver modulo administracion',N'administracion'),
('catalogos.ver',N'Ver catalogos maestros',N'administracion'),
('catalogos.crear',N'Crear catalogos maestros',N'administracion'),
('catalogos.editar',N'Editar catalogos maestros',N'administracion'),
('catalogos.estado',N'Activar o inactivar catalogos maestros',N'administracion'),
('personal.reset_password',N'Restablecer contrasena de personal',N'personal'),
('lugares_servicio.ver',N'Ver lugares de servicio',N'administracion'),
('lugares_servicio.crear',N'Crear lugares de servicio',N'administracion'),
('lugares_servicio.editar',N'Editar lugares de servicio',N'administracion'),
('lugares_servicio.estado',N'Activar o inactivar lugares de servicio',N'administracion'),
('eas.ver',N'Ver EAS',N'administracion'),
('eas.crear',N'Crear EAS',N'administracion'),
('eas.editar',N'Editar EAS',N'administracion'),
('eas.estado',N'Activar o inactivar EAS',N'administracion'),
('moviles.ver',N'Ver moviles',N'administracion'),
('moviles.crear',N'Crear moviles',N'administracion'),
('moviles.editar',N'Editar moviles',N'administracion'),
('moviles.estado',N'Activar o inactivar moviles',N'administracion'),
('moviles.asignar',N'Asignar moviles a EAS',N'administracion'),
('dashboard.mantenimiento',N'Ver alertas de mantenimiento preventivo',N'dashboard');

MERGE dbo.permisos AS target
USING @permisosAdmin AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, modulo = source.modulo, activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, descripcion, modulo, activo) VALUES (source.codigo, source.descripcion, source.modulo, 1);
GO

DECLARE @asignacionesAdmin TABLE (rol NVARCHAR(80), permiso NVARCHAR(120));
INSERT INTO @asignacionesAdmin (rol, permiso)
SELECT N'Administrador', codigo FROM dbo.permisos;

INSERT INTO @asignacionesAdmin (rol, permiso)
VALUES
(N'Operaciones','administracion.ver'),(N'Operaciones','catalogos.ver'),
(N'Operaciones','lugares_servicio.ver'),(N'Operaciones','lugares_servicio.crear'),(N'Operaciones','lugares_servicio.editar'),(N'Operaciones','lugares_servicio.estado'),
(N'Operaciones','eas.ver'),(N'Operaciones','eas.crear'),(N'Operaciones','eas.editar'),(N'Operaciones','eas.estado'),
(N'Operaciones','moviles.ver'),(N'Operaciones','moviles.crear'),(N'Operaciones','moviles.editar'),(N'Operaciones','moviles.estado'),(N'Operaciones','moviles.asignar'),
(N'Operaciones','servicios.crear'),(N'Operaciones','servicios.editar'),(N'Operaciones','eventos.crear'),(N'Operaciones','eventos.editar'),(N'Operaciones','eventos.publicar'),(N'Operaciones','dashboard.mantenimiento'),
(N'Auditor','administracion.ver'),(N'Auditor','catalogos.ver'),(N'Auditor','personal.ver'),(N'Auditor','lugares_servicio.ver'),(N'Auditor','eas.ver'),(N'Auditor','moviles.ver'),(N'Auditor','auditoria.ver'),(N'Auditor','auditoria.detalle'),(N'Auditor','auditoria.exportar'),(N'Auditor','reportes.exportar'),
(N'Radioperador SEGURA EP','eventos.ver'),(N'Radioperador SEGURA EP','servicios.ver'),(N'Radioperador SEGURA EP','cartillas.generar'),(N'Radioperador SEGURA EP','cartillas.ver'),(N'Radioperador SEGURA EP','dashboard.mantenimiento'),(N'Radioperador SEGURA EP','novedades.crear'),
(N'Encargado','reportes.ver'),(N'Encargado','personal.ver_asignado'),(N'Encargado','cartillas.generar'),(N'Encargado','cartillas.ver'),
(N'Comunicaciones','eventos.ver'),(N'Comunicaciones','eventos.crear'),(N'Comunicaciones','eventos.editar'),(N'Comunicaciones','eventos.publicar'),(N'Comunicaciones','eventos.eliminar'),
(N'Personal Operativo','perfil.ver'),(N'Personal Operativo','eventos.ver_convocado'),(N'Personal Operativo','cartillas.ver');

INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM @asignacionesAdmin a
INNER JOIN dbo.roles r ON r.nombre = a.rol
INNER JOIN dbo.permisos p ON p.codigo = a.permiso
WHERE NOT EXISTS (
    SELECT 1
    FROM dbo.rol_permiso rp
    WHERE rp.rol_id = r.id
      AND rp.permiso_id = p.id
);
GO

IF OBJECT_ID('dbo.vw_moviles_mantenimiento', 'V') IS NOT NULL
    DROP VIEW dbo.vw_moviles_mantenimiento;
GO

CREATE VIEW dbo.vw_moviles_mantenimiento AS
SELECT
    m.id,
    m.numero_movil,
    m.placa,
    tm.nombre AS tipo,
    em.nombre AS estado,
    m.kilometraje_actual,
    m.kilometraje_ultimo_mantenimiento,
    m.proximo_mantenimiento,
    (m.proximo_mantenimiento - m.kilometraje_actual) AS kilometros_restantes,
    CASE
        WHEN m.kilometraje_actual > m.proximo_mantenimiento THEN N'Mantenimiento preventivo vencido'
        WHEN (m.proximo_mantenimiento - m.kilometraje_actual) <= 500 THEN N'Movil proximo a mantenimiento preventivo'
        ELSE NULL
    END AS alerta_mantenimiento,
    m.activo
FROM dbo.moviles m
INNER JOIN dbo.catalogo_detalles tm ON tm.id = m.tipo_movil_id
INNER JOIN dbo.catalogo_detalles em ON em.id = m.estado_movil_id;
GO
