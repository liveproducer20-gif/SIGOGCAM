SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH(N'dbo.distribucion_encargados', N'circuito_id') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD circuito_id INT NULL;
IF COL_LENGTH(N'dbo.distribucion_encargados', N'auxiliar_1_id') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD auxiliar_1_id INT NULL;
IF COL_LENGTH(N'dbo.distribucion_encargados', N'auxiliar_2_id') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD auxiliar_2_id INT NULL;
IF COL_LENGTH(N'dbo.distribucion_encargados', N'movil_id') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD movil_id INT NULL;
IF COL_LENGTH(N'dbo.distribucion_encargados', N'usar_encargado_distrito') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD usar_encargado_distrito BIT NOT NULL
        CONSTRAINT DF_distribucion_encargados_usar_distrito DEFAULT (0);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_distribucion_encargados_circuito')
    ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT FK_distribucion_encargados_circuito
        FOREIGN KEY (circuito_id) REFERENCES dbo.circuitos(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_distribucion_encargados_auxiliar_1')
    ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT FK_distribucion_encargados_auxiliar_1
        FOREIGN KEY (auxiliar_1_id) REFERENCES dbo.personal(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_distribucion_encargados_auxiliar_2')
    ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT FK_distribucion_encargados_auxiliar_2
        FOREIGN KEY (auxiliar_2_id) REFERENCES dbo.personal(id);
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_distribucion_encargados_movil')
    ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT FK_distribucion_encargados_movil
        FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id);

DECLARE @constraint_name SYSNAME;
DECLARE @drop_sql NVARCHAR(MAX);
SELECT @constraint_name=cc.name
FROM sys.check_constraints cc
WHERE cc.parent_object_id=OBJECT_ID(N'dbo.distribucion_encargados')
  AND cc.name IN (N'CK_distribucion_encargados_tipo',N'CK_distribucion_encargados_consistencia');
WHILE @constraint_name IS NOT NULL
BEGIN
    SET @drop_sql=N'ALTER TABLE dbo.distribucion_encargados DROP CONSTRAINT ' + QUOTENAME(@constraint_name);
    EXEC sys.sp_executesql @drop_sql;
    SET @constraint_name=NULL;
    SELECT TOP 1 @constraint_name=cc.name
    FROM sys.check_constraints cc
    WHERE cc.parent_object_id=OBJECT_ID(N'dbo.distribucion_encargados')
      AND cc.name IN (N'CK_distribucion_encargados_tipo',N'CK_distribucion_encargados_consistencia');
END;

ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT CK_distribucion_encargados_tipo
    CHECK (tipo_responsabilidad IN (N'ENCARGADO_DISTRITO',N'ENCARGADO_CIRCUITO',N'ENCARGADO_RUTA'));
ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT CK_distribucion_encargados_consistencia CHECK (
    (tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND ruta_id IS NULL AND circuito_id IS NULL
        AND requiere_encargado=1 AND agente_id IS NOT NULL
        AND auxiliar_1_id IS NULL AND auxiliar_2_id IS NULL AND movil_id IS NULL)
 OR (tipo_responsabilidad=N'ENCARGADO_CIRCUITO' AND ruta_id IS NULL AND circuito_id IS NOT NULL
        AND requiere_encargado=1 AND agente_id IS NOT NULL
        AND (auxiliar_1_id IS NULL OR auxiliar_1_id<>agente_id)
        AND (auxiliar_2_id IS NULL OR auxiliar_2_id<>agente_id)
        AND (auxiliar_1_id IS NULL OR auxiliar_2_id IS NULL OR auxiliar_1_id<>auxiliar_2_id))
 OR (tipo_responsabilidad=N'ENCARGADO_RUTA' AND ruta_id IS NOT NULL AND circuito_id IS NULL
        AND auxiliar_1_id IS NULL AND auxiliar_2_id IS NULL AND movil_id IS NULL
        AND ((requiere_encargado=1 AND agente_id IS NOT NULL) OR (requiere_encargado=0 AND agente_id IS NULL)))
);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_encargado_circuito' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE UNIQUE INDEX UX_distribucion_encargado_circuito
        ON dbo.distribucion_encargados(distribucion_id,circuito_id)
        WHERE tipo_responsabilidad=N'ENCARGADO_CIRCUITO' AND deleted_at IS NULL;

COMMIT TRANSACTION;
