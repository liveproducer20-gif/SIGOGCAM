USE BITSAC;
GO

-- ===================================================================
-- MIGRACIÓN: Registro de cambios (Changelog / Respaldo lógico)
-- Tabla para registrar actualizaciones del sistema con detalle
-- ===================================================================

PRINT '=== INICIO MIGRACION: Registro de cambios ===';

-- Crear tabla registro_cambios
IF OBJECT_ID('dbo.registro_cambios', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.registro_cambios (
        id              INT IDENTITY(1,1) NOT NULL,
        desarrollador   NVARCHAR(150) NOT NULL,
        fecha           DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE),
        hora            TIME(0) NOT NULL DEFAULT CAST(GETDATE() AS TIME(0)),
        titulo          NVARCHAR(200) NOT NULL,
        detalle         NVARCHAR(MAX) NULL,
        creado_por      INT NULL,
        fecha_creacion  DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT PK_registro_cambios PRIMARY KEY CLUSTERED (id)
    );

    PRINT 'OK - Tabla registro_cambios creada.';
END
ELSE
BEGIN
    PRINT 'OK - Tabla registro_cambios ya existe.';
END
GO

-- Índice por fecha para ordenamiento rápido
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_registro_cambios_fecha' AND object_id = OBJECT_ID('dbo.registro_cambios'))
    CREATE INDEX IX_registro_cambios_fecha ON dbo.registro_cambios (fecha DESC, hora DESC);
GO

PRINT '=== FIN MIGRACION: Registro de cambios ===';
GO
