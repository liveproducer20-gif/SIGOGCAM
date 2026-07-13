USE BITSAC;
GO

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
        prioridad NVARCHAR(20) NOT NULL CONSTRAINT DF_alertas_prioridad DEFAULT 'Media',
        estado NVARCHAR(30) NOT NULL CONSTRAINT DF_alertas_estado DEFAULT 'Nuevo',
        imagen NVARCHAR(500) NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_creacion DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NOT NULL CONSTRAINT DF_alertas_actualizacion DEFAULT SYSDATETIME(),
        asignado_a INT NULL,
        asignado_nombre NVARCHAR(200) NULL,
        fecha_primera_respuesta DATETIME2 NULL,
        fecha_resolucion DATETIME2 NULL,
        activo BIT NOT NULL CONSTRAINT DF_alertas_activo DEFAULT 1,
        CONSTRAINT CK_alertas_prioridad CHECK (prioridad IN ('Crítica','Alta','Media','Baja')),
        CONSTRAINT CK_alertas_estado CHECK (estado IN ('Nuevo','En proceso','Pendiente','Resuelto','Cancelado'))
    );
END;
GO

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
END;
GO

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
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_soporte_usuario_fecha')
    CREATE INDEX IX_alertas_soporte_usuario_fecha ON dbo.alertas_soporte(usuario_id, fecha_creacion DESC) INCLUDE (estado, prioridad, modulo, activo);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_soporte_estado_prioridad')
    CREATE INDEX IX_alertas_soporte_estado_prioridad ON dbo.alertas_soporte(activo, estado, prioridad, fecha_creacion DESC) INCLUDE (usuario_id, modulo, asignado_a);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_comentarios_alerta')
    CREATE INDEX IX_alertas_comentarios_alerta ON dbo.alertas_soporte_comentarios(alerta_id, fecha_creacion);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_historial_alerta')
    CREATE INDEX IX_alertas_historial_alerta ON dbo.alertas_soporte_historial(alerta_id, fecha_creacion);
GO

UPDATE dbo.alertas_soporte
SET codigo_alerta = CONCAT('ALT-', YEAR(fecha_creacion), '-', RIGHT('000000' + CONVERT(VARCHAR(20), id), 6))
WHERE codigo_alerta IS NULL;
GO

