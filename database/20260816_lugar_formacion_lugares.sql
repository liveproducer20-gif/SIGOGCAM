-- Add lugar_formacion column to lugares_servicio for CSV import
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID(N'dbo.lugares_servicio')
      AND name = N'lugar_formacion'
)
BEGIN
    ALTER TABLE dbo.lugares_servicio
        ADD lugar_formacion NVARCHAR(300) NULL;
    PRINT 'Columna lugar_formacion agregada a dbo.lugares_servicio';
END
GO
