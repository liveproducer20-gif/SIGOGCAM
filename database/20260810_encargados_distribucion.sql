SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.catalogo_detalles', 'asignar_encargado') IS NULL
    ALTER TABLE dbo.catalogo_detalles ADD asignar_encargado BIT NOT NULL CONSTRAINT DF_catalogo_detalles_asignar_encargado DEFAULT (0);

IF COL_LENGTH('dbo.rutas', 'asignar_encargado') IS NULL
    ALTER TABLE dbo.rutas ADD asignar_encargado BIT NOT NULL CONSTRAINT DF_rutas_asignar_encargado DEFAULT (0);

IF OBJECT_ID(N'dbo.distribucion_encargados', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.distribucion_encargados (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribucion_encargados PRIMARY KEY,
        distribucion_id BIGINT NOT NULL,
        distrito_id INT NOT NULL,
        ruta_id INT NULL,
        tipo_responsabilidad NVARCHAR(30) NOT NULL,
        requiere_encargado BIT NOT NULL,
        agente_id INT NULL,
        tipo_asignacion NVARCHAR(40) NULL,
        estado NVARCHAR(20) NOT NULL CONSTRAINT DF_distribucion_encargados_estado DEFAULT (N'ASIGNADO'),
        creado_por INT NOT NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribucion_encargados_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        deleted_at DATETIME2 NULL,
        CONSTRAINT FK_distribucion_encargados_distribucion FOREIGN KEY (distribucion_id) REFERENCES dbo.distribuciones_personal(id),
        CONSTRAINT FK_distribucion_encargados_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_distribucion_encargados_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT FK_distribucion_encargados_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_distribucion_encargados_creador FOREIGN KEY (creado_por) REFERENCES dbo.personal(id),
        CONSTRAINT CK_distribucion_encargados_tipo CHECK (tipo_responsabilidad IN (N'ENCARGADO_DISTRITO', N'ENCARGADO_RUTA')),
        CONSTRAINT CK_distribucion_encargados_consistencia CHECK (
            (tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND ruta_id IS NULL AND requiere_encargado=1 AND agente_id IS NOT NULL)
            OR (tipo_responsabilidad=N'ENCARGADO_RUTA' AND ruta_id IS NOT NULL AND ((requiere_encargado=1 AND agente_id IS NOT NULL) OR (requiere_encargado=0 AND agente_id IS NULL)))
        )
    );
END;

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_encargado_distrito' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE UNIQUE INDEX UX_distribucion_encargado_distrito ON dbo.distribucion_encargados(distribucion_id) WHERE tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_encargado_ruta' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE UNIQUE INDEX UX_distribucion_encargado_ruta ON dbo.distribucion_encargados(distribucion_id,ruta_id) WHERE tipo_responsabilidad=N'ENCARGADO_RUTA' AND deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_distribucion_encargados_agente' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE INDEX IX_distribucion_encargados_agente ON dbo.distribucion_encargados(agente_id,distribucion_id) WHERE deleted_at IS NULL;

COMMIT TRANSACTION;
