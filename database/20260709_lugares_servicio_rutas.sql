USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== 1/4: AGREGANDO CATALOGO RUTAS ===';

IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'RUTAS')
BEGIN
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion, estado)
    VALUES ('RUTAS', N'Rutas', N'Rutas de lugares de servicio', 1);
    PRINT '  Catalogo RUTAS creado.';
END
ELSE
    PRINT '  Catalogo RUTAS ya existe.';
GO

DECLARE @rutaCatalogoId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'RUTAS');

MERGE dbo.catalogo_detalles AS target
USING (VALUES
    (@rutaCatalogoId, 'RUTA_9_OCTUBRE', N'Ruta 9 de Octubre', 10),
    (@rutaCatalogoId, 'RUTA_MALECON', N'Ruta Malecón', 20),
    (@rutaCatalogoId, 'RUTA_CENTRO', N'Ruta Centro', 30),
    (@rutaCatalogoId, 'RUTA_NORTE', N'Ruta Norte', 40),
    (@rutaCatalogoId, 'RUTA_SUR', N'Ruta Sur', 50),
    (@rutaCatalogoId, 'RUTA_ESTE', N'Ruta Este', 60),
    (@rutaCatalogoId, 'RUTA_OESTE', N'Ruta Oeste', 70)
) AS source(catalogo_id, codigo, nombre, orden)
ON target.catalogo_id = source.catalogo_id AND target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, orden = source.orden, estado = 1
WHEN NOT MATCHED THEN
    INSERT (catalogo_id, codigo, nombre, orden, estado)
    VALUES (source.catalogo_id, source.codigo, source.nombre, source.orden, 1);
GO

PRINT '  Rutas sembradas.';

PRINT '=== 2/4: RESPALDANDO lugares_servicio ===';

IF OBJECT_ID('dbo.lugares_servicio_backup_old', 'U') IS NULL
    EXEC('SELECT * INTO dbo.lugares_servicio_backup_old FROM dbo.lugares_servicio');
GO

PRINT '=== 3/4: MODIFICANDO lugares_servicio ===';

-- Eliminar FK obsoletas
IF OBJECT_ID('FK_lugares_servicio_subunidad', 'F') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP CONSTRAINT FK_lugares_servicio_subunidad;
    PRINT '  FK subunidad eliminada.';
END

IF OBJECT_ID('FK_lugares_servicio_tipo', 'F') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP CONSTRAINT FK_lugares_servicio_tipo;
    PRINT '  FK tipo eliminada.';
END

-- Agregar nuevas columnas
IF COL_LENGTH('dbo.lugares_servicio', 'ruta_id') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD ruta_id INT NULL;
    PRINT '  Columna ruta_id agregada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'hora_entrada') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD hora_entrada NVARCHAR(5) NULL;
    PRINT '  Columna hora_entrada agregada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'hora_salida') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD hora_salida NVARCHAR(5) NULL;
    PRINT '  Columna hora_salida agregada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'consignas') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD consignas NVARCHAR(500) NULL;
    PRINT '  Columna consignas agregada.';
END

-- Eliminar columnas viejas
IF COL_LENGTH('dbo.lugares_servicio', 'nombre') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN nombre;
    PRINT '  Columna nombre eliminada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'subunidad_operativa_id') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN subunidad_operativa_id;
    PRINT '  Columna subunidad_operativa_id eliminada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'tipo_servicio_id') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN tipo_servicio_id;
    PRINT '  Columna tipo_servicio_id eliminada.';
END

IF COL_LENGTH('dbo.lugares_servicio', 'observacion') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN observacion;
    PRINT '  Columna observacion eliminada.';
END

-- Hacer ruta_id NOT NULL y agregar FK
IF COL_LENGTH('dbo.lugares_servicio', 'ruta_id') IS NOT NULL
BEGIN
    DECLARE @rutaCatalogoId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'RUTAS');

    -- Asignar un ruta_id valido a las filas que aun esten NULL.
    -- Si no hay detalles de RUTAS, usar el primer catalogo_detalles disponible como fallback.
    IF @rutaCatalogoId IS NOT NULL
    BEGIN
        EXEC('UPDATE dbo.lugares_servicio SET ruta_id = (SELECT TOP 1 id FROM dbo.catalogo_detalles WHERE catalogo_id = ' + @rutaCatalogoId + ' ORDER BY id) WHERE ruta_id IS NULL');
    END

    -- Verificar que no quede ninguna fila con ruta_id NULL antes del ALTER NOT NULL.
    IF NOT EXISTS (SELECT 1 FROM dbo.lugares_servicio WHERE ruta_id IS NULL)
    BEGIN
        IF OBJECT_ID('FK_lugares_servicio_ruta', 'F') IS NULL
        BEGIN
            ALTER TABLE dbo.lugares_servicio ALTER COLUMN ruta_id INT NOT NULL;
            ALTER TABLE dbo.lugares_servicio ADD CONSTRAINT FK_lugares_servicio_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.catalogo_detalles(id);
            PRINT '  FK ruta agregada.';
        END
    END
    ELSE
        PRINT '  AVISO: quedan filas con ruta_id NULL. No se aplico ALTER NOT NULL.';
END

PRINT '=== 4/4: VERIFICACION ===';

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'lugares_servicio'
ORDER BY ORDINAL_POSITION;
GO

COMMIT TRANSACTION;
GO

PRINT 'Migracion completada.';
GO
