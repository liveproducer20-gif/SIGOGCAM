USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== 1/6: AGREGANDO COLUMNAS FALTANTES A dbo.personal ===';

IF COL_LENGTH('dbo.personal', 'foto_perfil_url') IS NULL
    ALTER TABLE dbo.personal ADD foto_perfil_url NVARCHAR(MAX) NULL;

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

GO

PRINT '=== 2/6: CREANDO TABLAS DE ADMINISTRACION (SI NO EXISTEN) ===';

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

PRINT '=== 3/6: SEMBRANDO CATALOGOS ===';

MERGE dbo.catalogos AS target
USING (VALUES
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
    ('ESTADOS_ASIGNACION_MOVIL', N'Estados de Asignacion de Moviles', N'Estados de asignacion movil-EAS')
) AS source(codigo, nombre, descripcion)
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, descripcion = source.descripcion, estado = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, nombre, descripcion, estado) VALUES (source.codigo, source.nombre, source.descripcion, 1);
GO

MERGE dbo.catalogo_detalles AS target
USING (
    SELECT c.id AS catalogo_id, d.*
    FROM (VALUES
        ('GRADOS','AGENTE_1',N'Agente 1',5),
        ('GRADOS','AGENTE_2',N'Agente 2',10),
        ('GRADOS','AGENTE_3',N'Agente 3',15),
        ('GRADOS','AGENTE_4',N'Agente 4',20),
        ('GRADOS','SUB_INSPECTOR',N'Sub-Inspector',25),
        ('GRADOS','INSPECTOR',N'Inspector',30),
        ('GRADOS','JEFE_CONTROL_MUNICIPAL',N'Jefe de Control Municipal',35),
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
        ('TIPOS_SERVICIO_LUGAR','OTRO',N'Otro',60),
        ('TIPOS_MOVIL','CAMIONETA',N'Camioneta',10),
        ('TIPOS_MOVIL','MOTOCICLETA',N'Motocicleta',20),
        ('TIPOS_MOVIL','BICICLETA',N'Bicicleta',30),
        ('TIPOS_MOVIL','OTRO',N'Otro',40),
        ('ESTADOS_MOVIL','OPERATIVO',N'Operativo',10),
        ('ESTADOS_MOVIL','MANTENIMIENTO',N'Mantenimiento',20),
        ('ESTADOS_MOVIL','INACTIVO',N'Inactivo',30),
        ('ESTADOS_ASIGNACION_MOVIL','ACTIVA',N'Activa',10),
        ('ESTADOS_ASIGNACION_MOVIL','INACTIVA',N'Inactiva',20)
    ) AS d(catalogo, codigo, nombre, orden)
    INNER JOIN dbo.catalogos c ON c.codigo = d.catalogo
) AS source
ON target.catalogo_id = source.catalogo_id AND target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, orden = source.orden, estado = 1, fecha_actualizacion = SYSDATETIME()
WHEN NOT MATCHED THEN
    INSERT (catalogo_id, codigo, nombre, orden, estado)
    VALUES (source.catalogo_id, source.codigo, source.nombre, source.orden, 1);
GO

PRINT '=== 4/6: CREANDO VISTA vw_personal_detalle ===';

IF OBJECT_ID('dbo.vw_personal_detalle', 'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_detalle;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_detalle AS
SELECT
    p.id,
    p.cedula,
    p.nombres,
    p.apellidos,
    p.correo_institucional,
    p.telefono,
    p.fecha_nacimiento,
    p.fecha_ingreso,
    ISNULL(r.nombre, ''SIN ROL'') AS rol,
    ISNULL(ep.nombre, ''SIN ESTADO'') AS estado_personal,
    ISNULL(p.activo, 1) AS activo,
    LTRIM(RTRIM(ISNULL(p.nombres, '''') + '' '' + ISNULL(p.apellidos, ''''))) AS nombre_completo
FROM dbo.personal p
LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id;
');
GO

PRINT '=== 5/6: ACTUALIZANDO PERMISOS DEL SISTEMA ===';

-- Agregar permisos nuevos que no existan
DECLARE @permisosNuevos TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255), modulo NVARCHAR(80));
INSERT INTO @permisosNuevos (codigo, descripcion, modulo)
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
USING @permisosNuevos AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, modulo = source.modulo, activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, descripcion, modulo, activo) VALUES (source.codigo, source.descripcion, source.modulo, 1);
GO

-- Asignar permisos nuevos al rol Administrador
INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM dbo.roles r
CROSS JOIN dbo.permisos p
WHERE r.nombre = 'Administrador'
  AND p.codigo IN (
    'administracion.ver','catalogos.ver','catalogos.crear','catalogos.editar','catalogos.estado',
    'personal.ver','personal.crear','personal.editar','personal.editar_estado','personal.reset_password',
    'roles.ver','roles.crear','roles.editar','permisos.ver',
    'lugares_servicio.ver','lugares_servicio.crear','lugares_servicio.editar','lugares_servicio.estado',
    'eas.ver','eas.crear','eas.editar','eas.estado',
    'moviles.ver','moviles.crear','moviles.editar','moviles.estado','moviles.asignar',
    'dashboard.mantenimiento',
    'eventos.ver','eventos.crear','eventos.editar','eventos.eliminar','eventos.convocar','eventos.publicar',
    'anuncios.ver','anuncios.crear','anuncios.editar','anuncios.eliminar',
    'cartillas.ver','cartillas.generar',
    'insignias.ver',
    'perfil.ver','perfil.editar'
  )
  AND NOT EXISTS (
    SELECT 1 FROM dbo.rol_permiso rp
    WHERE rp.rol_id = r.id AND rp.permiso_id = p.id
  );
GO

-- Asignar permisos nuevos al rol Operaciones
INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM dbo.roles r
CROSS JOIN dbo.permisos p
WHERE r.nombre = 'Operaciones'
  AND p.codigo IN (
    'administracion.ver','catalogos.ver',
    'lugares_servicio.ver','lugares_servicio.crear','lugares_servicio.editar','lugares_servicio.estado',
    'eas.ver','eas.crear','eas.editar','eas.estado',
    'moviles.ver','moviles.crear','moviles.editar','moviles.estado','moviles.asignar',
    'dashboard.mantenimiento',
    'eventos.ver','eventos.crear','eventos.editar','eventos.convocar',
    'anuncios.ver','anuncios.crear','anuncios.editar',
    'cartillas.ver','cartillas.generar',
    'insignias.ver',
    'perfil.ver','perfil.editar'
  )
  AND NOT EXISTS (
    SELECT 1 FROM dbo.rol_permiso rp
    WHERE rp.rol_id = r.id AND rp.permiso_id = p.id
  );
GO

PRINT '=== 6/6: CREANDO VISTAS ADICIONALES ===';

IF OBJECT_ID('dbo.vw_personal_operativo', 'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_operativo;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_operativo AS
SELECT *
FROM dbo.vw_personal_detalle
WHERE activo = 1;
');
GO

IF OBJECT_ID('dbo.vw_personal_disponible', 'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_disponible;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_disponible AS
SELECT *
FROM dbo.vw_personal_detalle
WHERE activo = 1;
');
GO

IF OBJECT_ID('dbo.vw_personal_disponible_sin_evento', 'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_disponible_sin_evento;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_disponible_sin_evento AS
SELECT *
FROM dbo.vw_personal_detalle
WHERE activo = 1;
');
GO

COMMIT TRANSACTION;
GO

PRINT '=== VERIFICACION POST-MIGRACION ===';

SELECT 'vw_personal_detalle' AS objeto,
       CASE WHEN OBJECT_ID('dbo.vw_personal_detalle', 'V') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END AS estado
UNION ALL
SELECT 'dbo.catalogos',
       CASE WHEN OBJECT_ID('dbo.catalogos', 'U') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END
UNION ALL
SELECT 'dbo.lugares_servicio',
       CASE WHEN OBJECT_ID('dbo.lugares_servicio', 'U') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END
UNION ALL
SELECT 'dbo.eas_estaciones',
       CASE WHEN OBJECT_ID('dbo.eas_estaciones', 'U') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END
UNION ALL
SELECT 'dbo.moviles',
       CASE WHEN OBJECT_ID('dbo.moviles', 'U') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END
UNION ALL
SELECT 'dbo.movil_eas_asignaciones',
       CASE WHEN OBJECT_ID('dbo.movil_eas_asignaciones', 'U') IS NOT NULL THEN 'EXISTE' ELSE 'FALTA' END;
GO
