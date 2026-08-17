SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH('dbo.lugares_servicio', 'nombre') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN nombre NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.lugares_servicio', 'direccion') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN direccion NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.lugares_servicio', 'ubicacion_especifica') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN ubicacion_especifica NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.lugares_servicio', 'lugar_formacion') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN lugar_formacion NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.lugares_servicio', 'consignas') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN consignas NVARCHAR(MAX) NULL;

IF COL_LENGTH('dbo.lugares_servicio', 'observacion') IS NOT NULL
    ALTER TABLE dbo.lugares_servicio ALTER COLUMN observacion NVARCHAR(MAX) NULL;

COMMIT TRANSACTION;
