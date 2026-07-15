USE BITSAC;
GO

-- Ampliación aditiva y compatible: los registros existentes permanecen válidos.
IF COL_LENGTH('dbo.cartillas_generadas', 'tipo') IS NULL
    ALTER TABLE dbo.cartillas_generadas ADD tipo NVARCHAR(60) NULL;
GO
IF COL_LENGTH('dbo.cartillas_generadas', 'subtipo') IS NULL
    ALTER TABLE dbo.cartillas_generadas ADD subtipo NVARCHAR(80) NULL;
GO
IF COL_LENGTH('dbo.cartillas_generadas', 'datos_json') IS NULL
    ALTER TABLE dbo.cartillas_generadas ADD datos_json NVARCHAR(MAX) NULL;
GO
IF COL_LENGTH('dbo.cartillas_generadas', 'fecha_actualizacion') IS NULL
    ALTER TABLE dbo.cartillas_generadas ADD fecha_actualizacion DATETIME2(0) NULL;
GO

IF NOT EXISTS (
    SELECT 1 FROM sys.check_constraints
    WHERE name = 'CK_cartillas_generadas_datos_json'
)
BEGIN
    ALTER TABLE dbo.cartillas_generadas ADD CONSTRAINT CK_cartillas_generadas_datos_json
        CHECK (datos_json IS NULL OR ISJSON(datos_json) = 1);
END;
GO
