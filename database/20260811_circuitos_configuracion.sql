SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.circuitos', N'U') IS NOT NULL
BEGIN
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_circuitos_encargado' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT FK_circuitos_encargado;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_circuitos_auxiliar_1' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT FK_circuitos_auxiliar_1;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_circuitos_auxiliar_2' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT FK_circuitos_auxiliar_2;
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name=N'FK_circuitos_movil' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT FK_circuitos_movil;
    IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name=N'CK_circuitos_personal_distinto' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT CK_circuitos_personal_distinto;
    IF EXISTS (SELECT 1 FROM sys.default_constraints WHERE name=N'DF_circuitos_encargado_distrito' AND parent_object_id=OBJECT_ID(N'dbo.circuitos'))
        ALTER TABLE dbo.circuitos DROP CONSTRAINT DF_circuitos_encargado_distrito;

    IF COL_LENGTH(N'dbo.circuitos',N'encargado_id') IS NOT NULL ALTER TABLE dbo.circuitos DROP COLUMN encargado_id;
    IF COL_LENGTH(N'dbo.circuitos',N'usar_encargado_distrito') IS NOT NULL ALTER TABLE dbo.circuitos DROP COLUMN usar_encargado_distrito;
    IF COL_LENGTH(N'dbo.circuitos',N'auxiliar_1_id') IS NOT NULL ALTER TABLE dbo.circuitos DROP COLUMN auxiliar_1_id;
    IF COL_LENGTH(N'dbo.circuitos',N'auxiliar_2_id') IS NOT NULL ALTER TABLE dbo.circuitos DROP COLUMN auxiliar_2_id;
    IF COL_LENGTH(N'dbo.circuitos',N'movil_id') IS NOT NULL ALTER TABLE dbo.circuitos DROP COLUMN movil_id;
END;
GO

PRINT 'Circuitos configurados sin asignaciones operativas permanentes.';
GO
