/*******************************************************************************
 * 20260807 - Quitar horas de los lugares de servicio
 *
 * Solicitud: el módulo "Lugares de servicio" no solicita hora de inicio ni fin;
 * se eliminan las columnas conectadas en la BD.
 *******************************************************************************/

USE BITSAC;
GO

SET NOCOUNT ON;

DECLARE @tabla VARCHAR(64) = 'dbo.lugares_servicio';

-- 1) Eliminar columnas de horas asociadas al lugar de servicio
IF COL_LENGTH('dbo.lugares_servicio','hora_entrada') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN hora_entrada;
    PRINT 'OK - Columna hora_entrada eliminada';
END
ELSE
    PRINT 'hora_entrada no existe o ya fue eliminada';
GO

IF COL_LENGTH('dbo.lugares_servicio','hora_salida') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN hora_salida;
    PRINT 'OK - Columna hora_salida eliminada';
END
ELSE
    PRINT 'hora_salida no existe o ya fue eliminada';
GO

IF COL_LENGTH('dbo.lugares_servicio','hora_inicio') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN hora_inicio;
    PRINT 'OK - Columna hora_inicio eliminada';
END
ELSE
    PRINT 'hora_inicio no existe o ya fue eliminada';
GO

IF COL_LENGTH('dbo.lugares_servicio','hora_fin') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP COLUMN hora_fin;
    PRINT 'OK - Columna hora_fin eliminada';
END
ELSE
    PRINT 'hora_fin no existe o ya fue eliminada';
GO

-- 2) Asegurar columna creado_por para inserciones del módulo geográfico
IF COL_LENGTH('dbo.lugares_servicio','creado_por') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD creado_por INT;
    PRINT 'OK - Columna creado_por agregada';
END
ELSE
    PRINT 'creado_por ya existe';
GO

-- 3) Asegurar columna descripcion / direccion_referencial / estado (por si la migración no llegó)
IF COL_LENGTH('dbo.lugares_servicio','descripcion') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD descripcion NVARCHAR(500) NULL;
    PRINT 'OK - Columna descripcion agregada';
END
GO

IF COL_LENGTH('dbo.lugares_servicio','direccion_referencial') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD direccion_referencial NVARCHAR(300) NULL;
    PRINT 'OK - Columna direccion_referencial agregada';
END
GO

IF COL_LENGTH('dbo.lugares_servicio','estado') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD estado NVARCHAR(20) NOT NULL CONSTRAINT DF_lugares_estado_mig DEFAULT (N'ACTIVO');
    PRINT 'OK - Columna estado agregada';
END
GO

IF COL_LENGTH('dbo.lugares_servicio','orden_distribucion') IS NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio ADD orden_distribucion INT NOT NULL CONSTRAINT DF_lugares_orden_migracion DEFAULT (0);
    PRINT 'OK - Columna orden_distribucion agregada';
END
GO

-- 4) Si los lugares_servicio todavía tienen la columna sector_id, eliminarla (de la antigua estructura)
IF COL_LENGTH('dbo.lugares_servicio','sector_id') IS NOT NULL
BEGIN
    ALTER TABLE dbo.lugares_servicio DROP CONSTRAINT IF EXISTS FK_lugares_sector;
    ALTER TABLE dbo.lugares_servicio DROP COLUMN IF EXISTS sector_id;
    PRINT 'OK - Columna sector_id eliminada';
END
GO

-- 5) Crear tabla rutas_geograficas (trazado geográfico de rutas) si no existe
IF OBJECT_ID(N'dbo.rutas_geograficas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.rutas_geograficas (
        id                    BIGINT IDENTITY(1,1) NOT NULL,
        distrito_id           INT NOT NULL,
        ruta_id               INT NOT NULL,
        nombre                NVARCHAR(150) NOT NULL,
        descripcion           NVARCHAR(500) NULL,
        tipo_geometria        NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_tipo DEFAULT (N'lineal'),
        geojson               NVARCHAR(MAX) NULL,
        color                 NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_color DEFAULT (N'#2563EB'),
        grosor                DECIMAL(4,1) NOT NULL CONSTRAINT DF_rutasgeo_grosor DEFAULT (6),
        opacidad              DECIMAL(3,2) NOT NULL CONSTRAINT DF_rutasgeo_opacidad DEFAULT (0.55),
        estado                NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_estado DEFAULT (N'ACTIVA'),
        creado_por            INT NOT NULL,
        actualizado_por       INT NULL,
        activo                BIT NOT NULL CONSTRAINT DF_rutasgeo_activo DEFAULT (1),
        fecha_creacion        DATETIME2 NOT NULL CONSTRAINT DF_rutasgeo_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion   DATETIME2 NULL,
        CONSTRAINT PK_rutas_geograficas PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_rutasgeo_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_rutasgeo_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
    );
    PRINT 'OK - Tabla rutas_geograficas creada';
END
ELSE
    PRINT 'rutas_geograficas ya existe';
GO

PRINT 'Migración 20260807_quitar_horas_lugares_servicio completada.';
GO