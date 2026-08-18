-- Crear tabla dbo.asistencia_personal (faltante para el módulo de asistencia)
-- El módulo de asistencia (backend_python/app/modules/asistencia) la referencia
-- en todas sus consultas, pero nunca fue creada.
IF OBJECT_ID(N'dbo.asistencia_personal', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.asistencia_personal (
        id                 INT IDENTITY(1,1) NOT NULL,
        personal_id        INT NOT NULL,
        distrito_id        INT NULL,
        ruta_id            INT NULL,
        lugar_id           INT NULL,
        fecha              DATE NOT NULL,
        turno              NVARCHAR(50) NOT NULL,
        hora_ingreso       DATETIME NULL,
        hora_salida        DATETIME NULL,
        estado_asistencia  NVARCHAR(50) NOT NULL DEFAULT N'PENDIENTE',
        tipo_asignacion    NVARCHAR(50) NULL,
        observaciones      NVARCHAR(500) NULL,
        registrado_por     INT NULL,
        deleted_at         DATETIME NULL,
        fecha_creacion     DATETIME NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME NULL,
        CONSTRAINT PK_asistencia_personal PRIMARY KEY (id)
    );
    PRINT 'Tabla dbo.asistencia_personal creada';
END
GO

-- Índice único por agente/fecha/turno para respetar la validación 409 del backend
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'UX_asistencia_personal_agente_fecha_turno'
      AND object_id = OBJECT_ID(N'dbo.asistencia_personal')
)
BEGIN
    CREATE UNIQUE INDEX UX_asistencia_personal_agente_fecha_turno
        ON dbo.asistencia_personal (personal_id, fecha, turno)
        WHERE deleted_at IS NULL;
    PRINT 'Índice único UX_asistencia_personal_agente_fecha_turno creado';
END
GO

-- Índice para el listado con filtros (fecha DESC)
IF NOT EXISTS (
    SELECT 1 FROM sys.indexes
    WHERE name = N'IX_asistencia_personal_fecha'
      AND object_id = OBJECT_ID(N'dbo.asistencia_personal')
)
BEGIN
    CREATE INDEX IX_asistencia_personal_fecha
        ON dbo.asistencia_personal (fecha DESC, turno);
    PRINT 'Índice IX_asistencia_personal_fecha creado';
END
GO

-- Claves foráneas
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_asistencia_personal_personal')
    ALTER TABLE dbo.asistencia_personal ADD CONSTRAINT FK_asistencia_personal_personal
        FOREIGN KEY (personal_id) REFERENCES dbo.personal(id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_asistencia_personal_distrito')
    ALTER TABLE dbo.asistencia_personal ADD CONSTRAINT FK_asistencia_personal_distrito
        FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_asistencia_personal_ruta')
    ALTER TABLE dbo.asistencia_personal ADD CONSTRAINT FK_asistencia_personal_ruta
        FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = N'FK_asistencia_personal_lugar')
    ALTER TABLE dbo.asistencia_personal ADD CONSTRAINT FK_asistencia_personal_lugar
        FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id);
GO
