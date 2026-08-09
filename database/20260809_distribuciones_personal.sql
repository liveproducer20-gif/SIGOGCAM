/* SIGO - cabecera y detalle del Tablero de Distribución. Idempotente. */
SET XACT_ABORT ON;
GO

/* Compatibilidad con instalaciones donde sector_id aún referencia dbo.sectores. */
IF COL_LENGTH(N'dbo.asignaciones_ruta', N'lugar_id') IS NULL
    ALTER TABLE dbo.asignaciones_ruta ADD lugar_id INT NULL;
GO
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.asignaciones_ruta') AND name=N'sector_id' AND is_nullable=0)
    ALTER TABLE dbo.asignaciones_ruta ALTER COLUMN sector_id INT NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_asignaciones_ruta_lugar')
    ALTER TABLE dbo.asignaciones_ruta ADD CONSTRAINT FK_asignaciones_ruta_lugar FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id);
GO

IF OBJECT_ID(N'dbo.distribuciones_personal', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.distribuciones_personal (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribuciones_personal PRIMARY KEY,
        nombre NVARCHAR(220) NOT NULL,
        fecha_distribucion DATE NOT NULL,
        creado_por INT NOT NULL,
        distrito_id INT NOT NULL,
        turno_id INT NOT NULL,
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_distribuciones_estado DEFAULT (N'BORRADOR'),
        porcentaje_cobertura DECIMAL(5,2) NOT NULL CONSTRAINT DF_distribuciones_cobertura DEFAULT (0),
        total_requerido INT NOT NULL CONSTRAINT DF_distribuciones_requerido DEFAULT (0),
        total_asignado INT NOT NULL CONSTRAINT DF_distribuciones_asignado DEFAULT (0),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribuciones_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        eliminado_por INT NULL,
        deleted_at DATETIME2 NULL,
        CONSTRAINT FK_distribuciones_usuario FOREIGN KEY (creado_por) REFERENCES dbo.personal(id),
        CONSTRAINT FK_distribuciones_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_distribuciones_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id),
        CONSTRAINT FK_distribuciones_eliminado_por FOREIGN KEY (eliminado_por) REFERENCES dbo.personal(id),
        CONSTRAINT CK_distribuciones_estado CHECK (estado IN (N'BORRADOR', N'PARCIAL', N'COMPLETA', N'ELIMINADA')),
        CONSTRAINT CK_distribuciones_cobertura CHECK (porcentaje_cobertura BETWEEN 0 AND 100)
    );
END;
GO

IF OBJECT_ID(N'dbo.distribucion_personal_detalle', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.distribucion_personal_detalle (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribucion_personal_detalle PRIMARY KEY,
        distribucion_id BIGINT NOT NULL,
        ruta_id INT NOT NULL,
        lugar_id INT NOT NULL,
        cantidad_requerida INT NOT NULL,
        agente_id INT NULL,
        asignacion_ruta_id BIGINT NULL,
        tipo_asignacion NVARCHAR(40) NULL,
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_distribucion_detalle_estado DEFAULT (N'PENDIENTE'),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribucion_detalle_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        deleted_at DATETIME2 NULL,
        CONSTRAINT FK_distribucion_detalle_cabecera FOREIGN KEY (distribucion_id) REFERENCES dbo.distribuciones_personal(id),
        CONSTRAINT FK_distribucion_detalle_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT FK_distribucion_detalle_lugar FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id),
        CONSTRAINT FK_distribucion_detalle_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_distribucion_detalle_asignacion FOREIGN KEY (asignacion_ruta_id) REFERENCES dbo.asignaciones_ruta(id),
        CONSTRAINT CK_distribucion_detalle_estado CHECK (estado IN (N'ASIGNADO', N'PENDIENTE', N'CANCELADO'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_fecha_turno' AND object_id=OBJECT_ID(N'dbo.distribuciones_personal'))
    CREATE UNIQUE INDEX UX_distribucion_fecha_turno ON dbo.distribuciones_personal (distrito_id, turno_id, fecha_distribucion) WHERE deleted_at IS NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_agente' AND object_id=OBJECT_ID(N'dbo.distribucion_personal_detalle'))
    CREATE UNIQUE INDEX UX_distribucion_agente ON dbo.distribucion_personal_detalle (distribucion_id, agente_id) WHERE agente_id IS NOT NULL AND deleted_at IS NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_distribucion_detalle_lugar' AND object_id=OBJECT_ID(N'dbo.distribucion_personal_detalle'))
    CREATE INDEX IX_distribucion_detalle_lugar ON dbo.distribucion_personal_detalle (distribucion_id, ruta_id, lugar_id) INCLUDE (agente_id, estado);
GO
IF NOT EXISTS (SELECT 1 FROM dbo.asignaciones_ruta WHERE deleted_at IS NULL GROUP BY agente_id, fecha_asignacion, turno HAVING COUNT(*) > 1)
AND NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_asignacion_ruta_agente_turno' AND object_id=OBJECT_ID(N'dbo.asignaciones_ruta'))
    CREATE UNIQUE INDEX UX_asignacion_ruta_agente_turno ON dbo.asignaciones_ruta (agente_id, fecha_asignacion, turno) WHERE deleted_at IS NULL;
GO
IF NOT EXISTS (SELECT 1 FROM dbo.permisos WHERE codigo=N'tablero_distribucion.eliminar')
    INSERT INTO dbo.permisos (codigo, descripcion, modulo, activo) VALUES (N'tablero_distribucion.eliminar', N'Eliminar distribuciones de personal', N'distribucion', 1);
GO
