/* EAS distribution support. Safe to execute repeatedly. */
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.circuito_eas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.circuito_eas (
        circuito_id INT NOT NULL,
        eas_id INT NOT NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_circuito_eas_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT PK_circuito_eas PRIMARY KEY (circuito_id, eas_id),
        CONSTRAINT FK_circuito_eas_circuito FOREIGN KEY (circuito_id) REFERENCES dbo.circuitos(id),
        CONSTRAINT FK_circuito_eas_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id)
    );
END;
GO

IF OBJECT_ID(N'dbo.eas_ruta_configuraciones', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.eas_ruta_configuraciones (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_eas_ruta_configuraciones PRIMARY KEY,
        eas_id INT NOT NULL,
        ruta_id INT NOT NULL,
        movil_id INT NULL,
        orden INT NOT NULL CONSTRAINT DF_eas_ruta_config_orden DEFAULT (1),
        activo BIT NOT NULL CONSTRAINT DF_eas_ruta_config_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_eas_ruta_config_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_eas_ruta_config_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id),
        CONSTRAINT FK_eas_ruta_config_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT FK_eas_ruta_config_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id)
    );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_eas_ruta_config_orden' AND object_id=OBJECT_ID(N'dbo.eas_ruta_configuraciones'))
    CREATE UNIQUE INDEX UX_eas_ruta_config_orden ON dbo.eas_ruta_configuraciones(eas_id,ruta_id,orden) WHERE activo=1;
GO

IF OBJECT_ID(N'dbo.distribucion_eas_detalle', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.distribucion_eas_detalle (
        id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribucion_eas_detalle PRIMARY KEY,
        distribucion_id BIGINT NOT NULL,
        eas_id INT NOT NULL,
        ruta_id INT NOT NULL,
        configuracion_id BIGINT NULL,
        rol NVARCHAR(3) NOT NULL,
        agente_id INT NULL,
        tipo_asignacion NVARCHAR(40) NULL,
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_distribucion_eas_detalle_estado DEFAULT (N'PENDIENTE'),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribucion_eas_detalle_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        deleted_at DATETIME2 NULL,
        CONSTRAINT FK_distribucion_eas_detalle_distribucion FOREIGN KEY (distribucion_id) REFERENCES dbo.distribuciones_personal(id),
        CONSTRAINT FK_distribucion_eas_detalle_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id),
        CONSTRAINT FK_distribucion_eas_detalle_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT FK_distribucion_eas_detalle_config FOREIGN KEY (configuracion_id) REFERENCES dbo.eas_ruta_configuraciones(id),
        CONSTRAINT FK_distribucion_eas_detalle_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
        CONSTRAINT CK_distribucion_eas_detalle_rol CHECK (rol IN (N'CP',N'JP',N'AUX')),
        CONSTRAINT CK_distribucion_eas_detalle_estado CHECK (estado IN (N'ASIGNADO',N'PENDIENTE',N'CANCELADO'))
    );
END;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_eas_detalle_config' AND object_id=OBJECT_ID(N'dbo.distribucion_eas_detalle'))
    CREATE UNIQUE INDEX UX_distribucion_eas_detalle_config ON dbo.distribucion_eas_detalle(distribucion_id,eas_id,ruta_id,configuracion_id,rol)
    WHERE configuracion_id IS NOT NULL AND deleted_at IS NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_eas_detalle_virtual' AND object_id=OBJECT_ID(N'dbo.distribucion_eas_detalle'))
    CREATE UNIQUE INDEX UX_distribucion_eas_detalle_virtual ON dbo.distribucion_eas_detalle(distribucion_id,eas_id,ruta_id,rol)
    WHERE configuracion_id IS NULL AND deleted_at IS NULL;
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'IX_distribucion_eas_detalle_agente' AND object_id=OBJECT_ID(N'dbo.distribucion_eas_detalle'))
    CREATE INDEX IX_distribucion_eas_detalle_agente ON dbo.distribucion_eas_detalle(agente_id,distribucion_id) WHERE agente_id IS NOT NULL AND deleted_at IS NULL;
GO
