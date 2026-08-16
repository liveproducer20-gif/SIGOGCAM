SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF COL_LENGTH(N'dbo.distribucion_encargados', N'conductor_id') IS NULL
    ALTER TABLE dbo.distribucion_encargados ADD conductor_id INT NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_distribucion_encargados_conductor')
    ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT FK_distribucion_encargados_conductor
        FOREIGN KEY (conductor_id) REFERENCES dbo.personal(id);
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name=N'CK_distribucion_encargados_scope')
    ALTER TABLE dbo.distribucion_encargados DROP CONSTRAINT CK_distribucion_encargados_scope;
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name=N'CK_distribucion_encargados_consistencia')
    ALTER TABLE dbo.distribucion_encargados DROP CONSTRAINT CK_distribucion_encargados_consistencia;

ALTER TABLE dbo.distribucion_encargados ADD CONSTRAINT CK_distribucion_encargados_scope CHECK (
    (tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND ruta_id IS NULL AND circuito_id IS NULL
        AND requiere_encargado=1 AND agente_id IS NOT NULL)
 OR (tipo_responsabilidad=N'ENCARGADO_CIRCUITO' AND ruta_id IS NULL AND circuito_id IS NOT NULL
        AND requiere_encargado=1 AND agente_id IS NOT NULL)
 OR (tipo_responsabilidad=N'ENCARGADO_RUTA' AND ruta_id IS NOT NULL AND circuito_id IS NULL
        AND conductor_id IS NULL AND auxiliar_1_id IS NULL AND auxiliar_2_id IS NULL AND movil_id IS NULL
        AND ((requiere_encargado=1 AND agente_id IS NOT NULL) OR (requiere_encargado=0 AND agente_id IS NULL)))
);

COMMIT TRANSACTION;
GO
