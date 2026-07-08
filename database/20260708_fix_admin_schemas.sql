USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== 1/3: REPARANDO eas_estaciones ===';

-- Agregar columnas faltantes
IF COL_LENGTH('dbo.eas_estaciones', 'distrito_id') IS NULL
BEGIN
    ALTER TABLE dbo.eas_estaciones ADD distrito_id INT NULL;
    PRINT '  distrito_id agregado.';
END
ELSE
    PRINT '  distrito_id ya existe.';
GO

IF COL_LENGTH('dbo.eas_estaciones', 'fecha_creacion') IS NULL
BEGIN
    ALTER TABLE dbo.eas_estaciones ADD fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_eas_estaciones_fecha DEFAULT (SYSDATETIME());
    PRINT '  fecha_creacion agregado.';
END
ELSE
    PRINT '  fecha_creacion ya existe.';
GO

IF COL_LENGTH('dbo.eas_estaciones', 'fecha_actualizacion') IS NULL
BEGIN
    ALTER TABLE dbo.eas_estaciones ADD fecha_actualizacion DATETIME2 NULL;
    PRINT '  fecha_actualizacion agregado.';
END
ELSE
    PRINT '  fecha_actualizacion ya existe.';
GO

-- Hacer ubicacion nullable (el backend nunca envia este campo)
IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'eas_estaciones'
      AND COLUMN_NAME = 'ubicacion' AND IS_NULLABLE = 'NO'
)
BEGIN
    ALTER TABLE dbo.eas_estaciones ALTER COLUMN ubicacion NVARCHAR(160) NULL;
    PRINT '  ubicacion cambiado a NULL.';
END
ELSE
    PRINT '  ubicacion ya es NULL o no existe.';
GO

-- Actualizar registros existentes con fecha_creacion si estan en NULL
UPDATE dbo.eas_estaciones SET fecha_creacion = SYSDATETIME() WHERE fecha_creacion IS NULL;
PRINT '  fechas_creacion actualizadas.';
GO

PRINT '=== 2/3: REPARANDO lugares_servicio ===';

-- Verificar si hay tablas que referencien lugares_servicio (no deberia haber)
IF OBJECT_ID(N'dbo.lugares_servicio', N'U') IS NOT NULL
BEGIN
    IF COL_LENGTH('dbo.lugares_servicio', 'distrito_id') IS NULL
    BEGIN
        PRINT '  lugares_servicio tiene esquema antiguo. Recreando...';

        -- Eliminar FK que referencian a lugares_servicio
        IF OBJECT_ID(N'dbo.FK_servicio_lugar', N'F') IS NOT NULL
        BEGIN
            ALTER TABLE dbo.servicio_lugares DROP CONSTRAINT FK_servicio_lugar;
            PRINT '  FK_servicio_lugar eliminada temporalmente.';
        END

        -- Respaldar datos existentes si los hay
        IF EXISTS (SELECT 1 FROM dbo.lugares_servicio)
        BEGIN
            SELECT * INTO dbo.lugares_servicio_backup FROM dbo.lugares_servicio;
            PRINT '  Datos respaldados en lugares_servicio_backup.';
        END

        DROP TABLE dbo.lugares_servicio;
        PRINT '  Tabla antigua eliminada.';
    END
    ELSE
    BEGIN
        PRINT '  lugares_servicio ya tiene el esquema correcto.';
    END
END
GO

IF OBJECT_ID(N'dbo.lugares_servicio', N'U') IS NULL
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
        CONSTRAINT FK_lugares_servicio_subunidad FOREIGN KEY (subunidad_operativa_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_lugares_servicio_tipo FOREIGN KEY (tipo_servicio_id) REFERENCES dbo.catalogo_detalles(id)
    );
    PRINT '  lugares_servicio creada con esquema correcto.';

    -- Restaurar FK que referencian a lugares_servicio
    IF OBJECT_ID(N'dbo.servicio_lugares', N'U') IS NOT NULL
    BEGIN
        ALTER TABLE dbo.servicio_lugares ADD CONSTRAINT FK_servicio_lugar FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id);
        PRINT '  FK_servicio_lugar restaurada.';
    END
END
GO

PRINT '=== 3/3: VERIFICACION ===';

-- Tablas de administracion
SELECT 'eas_estaciones' AS tabla,
       CASE WHEN COL_LENGTH('dbo.eas_estaciones', 'distrito_id') IS NOT NULL
            AND COL_LENGTH('dbo.eas_estaciones', 'fecha_creacion') IS NOT NULL
            THEN 'OK' ELSE 'FALTA' END AS estado
UNION ALL
SELECT 'lugares_servicio',
       CASE WHEN COL_LENGTH('dbo.lugares_servicio', 'distrito_id') IS NOT NULL
            AND COL_LENGTH('dbo.lugares_servicio', 'tipo_servicio_id') IS NOT NULL
            THEN 'OK' ELSE 'FALTA' END;
GO

COMMIT TRANSACTION;
GO

PRINT 'Migracion completada.';
GO
