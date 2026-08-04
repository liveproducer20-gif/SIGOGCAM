USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID(N'dbo.turnos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.turnos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(120) NOT NULL,
        hora_inicio TIME(0) NOT NULL,
        hora_fin TIME(0) NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_turnos_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_turnos_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL
    );
END;

IF NOT EXISTS (SELECT 1 FROM dbo.turnos)
BEGIN
    INSERT INTO dbo.turnos (nombre, hora_inicio, hora_fin)
    VALUES (N'Matutino', '06:00', '14:30'), (N'Vespertino', '14:30', '22:30'), (N'Nocturno', '22:30', '06:00');
END;

IF COL_LENGTH('dbo.rutas', 'distrito_id') IS NULL
    ALTER TABLE dbo.rutas ADD distrito_id INT NULL;
IF COL_LENGTH('dbo.rutas', 'turno_id') IS NULL
    ALTER TABLE dbo.rutas ADD turno_id INT NULL;
IF COL_LENGTH('dbo.rutas', 'hora_inicio') IS NULL
    ALTER TABLE dbo.rutas ADD hora_inicio TIME(0) NULL;
IF COL_LENGTH('dbo.rutas', 'hora_fin') IS NULL
    ALTER TABLE dbo.rutas ADD hora_fin TIME(0) NULL;
GO

UPDATE r
SET distrito_id = source.distrito_id, fecha_actualizacion = SYSDATETIME()
FROM dbo.rutas r
INNER JOIN (
    SELECT ruta_id, MIN(distrito_id) AS distrito_id
    FROM dbo.lugares_servicio
    WHERE activo = 1 AND ruta_id IS NOT NULL AND distrito_id IS NOT NULL
    GROUP BY ruta_id
    HAVING COUNT(DISTINCT distrito_id) = 1
) source ON source.ruta_id = r.id
WHERE r.distrito_id IS NULL;

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_rutas_distrito')
    ALTER TABLE dbo.rutas ADD CONSTRAINT FK_rutas_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_rutas_turno')
    ALTER TABLE dbo.rutas ADD CONSTRAINT FK_rutas_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id);

IF OBJECT_ID(N'dbo.sectores', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sectores (
        id INT IDENTITY(1,1) PRIMARY KEY,
        distrito_id INT NOT NULL,
        ruta_id INT NOT NULL,
        nombre NVARCHAR(180) NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_sectores_activo DEFAULT (1),
        creado_por INT NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_sectores_fecha DEFAULT (SYSDATETIME()),
        actualizado_por INT NULL,
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_sectores_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_sectores_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT UQ_sectores_ruta_nombre UNIQUE (ruta_id, nombre)
    );
END;

IF COL_LENGTH('dbo.lugares_servicio', 'sector_id') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD sector_id INT NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'nombre') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD nombre NVARCHAR(180) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'tipo_servicio_id') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD tipo_servicio_id INT NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'observacion') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD observacion NVARCHAR(500) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'ubicacion_especifica') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD ubicacion_especifica NVARCHAR(220) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'latitud') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD latitud DECIMAL(10,7) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'longitud') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD longitud DECIMAL(10,7) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'turno_id') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD turno_id INT NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'hora_inicio') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD hora_inicio TIME(0) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'hora_fin') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD hora_fin TIME(0) NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'cantidad_requerida') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD cantidad_requerida INT NOT NULL CONSTRAINT DF_lugares_cantidad DEFAULT (1);
IF COL_LENGTH('dbo.lugares_servicio', 'estado_operativo') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD estado_operativo NVARCHAR(30) NOT NULL CONSTRAINT DF_lugares_estado_op DEFAULT (N'SIN_ASIGNACION');
IF COL_LENGTH('dbo.lugares_servicio', 'creado_por') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD creado_por INT NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'actualizado_por') IS NULL
    ALTER TABLE dbo.lugares_servicio ADD actualizado_por INT NULL;
GO

UPDATE dbo.lugares_servicio SET nombre = direccion WHERE nombre IS NULL;
IF COL_LENGTH('dbo.lugares_servicio', 'hora_entrada') IS NOT NULL
    EXEC(N'UPDATE dbo.lugares_servicio SET hora_inicio = TRY_CONVERT(TIME(0), hora_entrada) WHERE hora_inicio IS NULL');
IF COL_LENGTH('dbo.lugares_servicio', 'hora_salida') IS NOT NULL
    EXEC(N'UPDATE dbo.lugares_servicio SET hora_fin = TRY_CONVERT(TIME(0), hora_salida) WHERE hora_fin IS NULL');
IF COL_LENGTH('dbo.lugares_servicio', 'consignas') IS NOT NULL
    EXEC(N'UPDATE dbo.lugares_servicio SET observacion = consignas WHERE observacion IS NULL');

IF OBJECT_ID(N'dbo.asignaciones_punto', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.asignaciones_punto (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        punto_id INT NOT NULL,
        personal_id INT NOT NULL,
        tipo_asignacion NVARCHAR(40) NOT NULL CONSTRAINT DF_asig_punto_tipo DEFAULT (N'FIJA'),
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NULL,
        turno_id INT NOT NULL,
        hora_inicio TIME(0) NOT NULL,
        hora_fin TIME(0) NOT NULL,
        funcion NVARCHAR(160) NULL,
        observaciones NVARCHAR(500) NULL,
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_asig_punto_estado DEFAULT (N'ACTIVA'),
        activo BIT NOT NULL CONSTRAINT DF_asig_punto_activo DEFAULT (1),
        creado_por INT NOT NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_asig_punto_fecha DEFAULT (SYSDATETIME()),
        actualizado_por INT NULL,
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_asig_punto_lugar FOREIGN KEY (punto_id) REFERENCES dbo.lugares_servicio(id),
        CONSTRAINT FK_asig_punto_personal FOREIGN KEY (personal_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_asig_punto_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id),
        CONSTRAINT CK_asig_punto_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_lugares_coordenadas_activas' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
    CREATE UNIQUE INDEX UX_lugares_coordenadas_activas ON dbo.lugares_servicio (latitud, longitud)
    WHERE activo = 1 AND latitud IS NOT NULL AND longitud IS NOT NULL;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lugares_geo_filtros' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
    CREATE INDEX IX_lugares_geo_filtros ON dbo.lugares_servicio (activo, distrito_id, ruta_id, sector_id, turno_id, estado_operativo)
    INCLUDE (latitud, longitud, nombre, cantidad_requerida);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asignaciones_punto_conflicto' AND object_id = OBJECT_ID('dbo.asignaciones_punto'))
    CREATE INDEX IX_asignaciones_punto_conflicto ON dbo.asignaciones_punto (personal_id, fecha_inicio, fecha_fin, hora_inicio, hora_fin, activo);

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_lugares_sector')
    ALTER TABLE dbo.lugares_servicio ADD CONSTRAINT FK_lugares_sector FOREIGN KEY (sector_id) REFERENCES dbo.sectores(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_lugares_turno')
    ALTER TABLE dbo.lugares_servicio ADD CONSTRAINT FK_lugares_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id);

DECLARE @permisos TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255));
INSERT INTO @permisos VALUES
(N'distribucion.ver', N'Ver distribución geográfica'),
(N'distribucion.crear', N'Crear puntos georreferenciados'),
(N'distribucion.editar', N'Editar puntos georreferenciados'),
(N'distribucion.desactivar', N'Desactivar puntos georreferenciados'),
(N'distribucion.asignar', N'Administrar asignaciones de personal'),
(N'distribucion.catalogos', N'Crear rutas y sectores desde distribución');

MERGE dbo.permisos AS target
USING @permisos AS source ON target.codigo = source.codigo
WHEN MATCHED THEN UPDATE SET descripcion = source.descripcion, modulo = N'distribucion', activo = 1
WHEN NOT MATCHED THEN INSERT (codigo, descripcion, modulo, activo) VALUES (source.codigo, source.descripcion, N'distribucion', 1);

INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM dbo.roles r
CROSS JOIN dbo.permisos p
WHERE p.codigo LIKE N'distribucion.%'
  AND (
      r.nombre IN (N'Administrador', N'Operaciones')
      OR (r.nombre = N'Supervisor' AND p.codigo IN (N'distribucion.ver', N'distribucion.asignar'))
      OR (r.nombre IN (N'Auditor', N'Auditoria') AND p.codigo = N'distribucion.ver')
  )
  AND NOT EXISTS (SELECT 1 FROM dbo.rol_permiso rp WHERE rp.rol_id = r.id AND rp.permiso_id = p.id);

COMMIT TRANSACTION;
GO
