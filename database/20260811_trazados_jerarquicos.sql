SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF COL_LENGTH(N'dbo.rutas_geograficas',N'nivel_geografico') IS NULL
    ALTER TABLE dbo.rutas_geograficas ADD nivel_geografico NVARCHAR(12) NOT NULL
        CONSTRAINT DF_rutasgeo_nivel DEFAULT (N'RUTA') WITH VALUES;
GO

IF COL_LENGTH(N'dbo.rutas_geograficas',N'circuito_id') IS NULL
    ALTER TABLE dbo.rutas_geograficas ADD circuito_id INT NULL;
GO

IF EXISTS (
    SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA=N'dbo' AND TABLE_NAME=N'rutas_geograficas'
      AND COLUMN_NAME=N'ruta_id' AND IS_NULLABLE=N'NO'
)
    ALTER TABLE dbo.rutas_geograficas ALTER COLUMN ruta_id INT NULL;
GO

UPDATE dbo.rutas_geograficas
SET nivel_geografico=N'RUTA'
WHERE nivel_geografico IS NULL OR nivel_geografico NOT IN (N'DISTRITO',N'CIRCUITO',N'RUTA');
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_rutasgeo_circuito' AND parent_object_id=OBJECT_ID(N'dbo.rutas_geograficas'))
    ALTER TABLE dbo.rutas_geograficas ADD CONSTRAINT FK_rutasgeo_circuito
        FOREIGN KEY(circuito_id) REFERENCES dbo.circuitos(id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name=N'CK_rutasgeo_nivel_objetivo' AND parent_object_id=OBJECT_ID(N'dbo.rutas_geograficas'))
    ALTER TABLE dbo.rutas_geograficas ADD CONSTRAINT CK_rutasgeo_nivel_objetivo CHECK (
        (nivel_geografico=N'DISTRITO' AND circuito_id IS NULL AND ruta_id IS NULL) OR
        (nivel_geografico=N'CIRCUITO' AND circuito_id IS NOT NULL AND ruta_id IS NULL) OR
        (nivel_geografico=N'RUTA' AND ruta_id IS NOT NULL)
    );
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_rutasgeo_distrito_activo' AND object_id=OBJECT_ID(N'dbo.rutas_geograficas'))
    CREATE UNIQUE INDEX UX_rutasgeo_distrito_activo ON dbo.rutas_geograficas(distrito_id)
        WHERE activo=1 AND nivel_geografico=N'DISTRITO';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_rutasgeo_circuito_activo' AND object_id=OBJECT_ID(N'dbo.rutas_geograficas'))
    CREATE UNIQUE INDEX UX_rutasgeo_circuito_activo ON dbo.rutas_geograficas(circuito_id)
        WHERE activo=1 AND nivel_geografico=N'CIRCUITO';
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_rutasgeo_ruta_activo' AND object_id=OBJECT_ID(N'dbo.rutas_geograficas'))
    CREATE UNIQUE INDEX UX_rutasgeo_ruta_activo ON dbo.rutas_geograficas(ruta_id)
        WHERE activo=1 AND nivel_geografico=N'RUTA';
GO

PRINT 'Trazados jerárquicos instalados correctamente.';
GO
