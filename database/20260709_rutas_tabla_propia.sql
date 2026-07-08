USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== 1/4: CREANDO TABLA dbo.rutas ===';

IF OBJECT_ID(N'dbo.rutas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.rutas (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(180) NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_rutas_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_rutas_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL
    );
    PRINT '  Tabla dbo.rutas creada.';
END
ELSE
    PRINT '  dbo.rutas ya existe.';
GO

PRINT '=== 2/4: MIGRANDO DATOS DESDE catalogo_detalles ===';

IF EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'RUTAS')
   AND (SELECT COUNT(*) FROM dbo.rutas) = 0
BEGIN
    INSERT INTO dbo.rutas (nombre)
    SELECT nombre
    FROM dbo.catalogo_detalles
    WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo = 'RUTAS')
      AND estado = 1
    ORDER BY orden;
    PRINT '  Datos migrados a dbo.rutas.';
END
ELSE
    PRINT '  No se migraron datos (ya existen o no hay catalogo RUTAS).';
GO

PRINT '=== 3/4: ACTUALIZANDO lugares_servicio PARA USAR dbo.rutas ===';

-- Mapear ruta_id de catalogo_detalles a nuevo id de dbo.rutas
IF COL_LENGTH('dbo.lugares_servicio', 'ruta_id') IS NOT NULL
   AND OBJECT_ID(N'dbo.rutas', N'U') IS NOT NULL
BEGIN
    -- Eliminar FK vieja (apunta a catalogo_detalles)
    IF OBJECT_ID('FK_lugares_servicio_ruta', 'F') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.lugares_servicio DROP CONSTRAINT FK_lugares_servicio_ruta;
        PRINT '  FK antigua eliminada.';
    END

    -- Mapear ids de catalogo_detalles -> dbo.rutas
    UPDATE l
    SET l.ruta_id = r2.id
    FROM dbo.lugares_servicio l
    INNER JOIN dbo.catalogo_detalles cd ON cd.id = l.ruta_id
    INNER JOIN dbo.rutas r2 ON r2.nombre = cd.nombre;
    PRINT '  ruta_id actualizado a nuevos IDs.';

    -- Agregar FK a dbo.rutas
    ALTER TABLE dbo.lugares_servicio ADD CONSTRAINT FK_lugares_servicio_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id);
    PRINT '  FK a dbo.rutas agregada.';
END
GO

PRINT '=== 4/4: LIMPIANDO RUTAS DE catalogos ===';

IF EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'RUTAS')
BEGIN
    DELETE FROM dbo.catalogo_detalles WHERE catalogo_id = (SELECT id FROM dbo.catalogos WHERE codigo = 'RUTAS');
    DELETE FROM dbo.catalogos WHERE codigo = 'RUTAS';
    PRINT '  RUTAS eliminado de catalogos/catalogo_detalles.';
END
GO

COMMIT TRANSACTION;
GO

PRINT 'Migracion completada.';
GO
