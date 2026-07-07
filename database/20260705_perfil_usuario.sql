USE BITSAC;
GO

IF OBJECT_ID('dbo.personal', 'U') IS NULL
BEGIN
    THROW 50001, 'No existe la tabla dbo.personal en la base BITSAC. Verifique que esta sea la base correcta o que el usuario tenga permisos.', 1;
END;
GO

IF COL_LENGTH('dbo.personal', 'foto_perfil_url') IS NULL
BEGIN
    ALTER TABLE dbo.personal ADD foto_perfil_url NVARCHAR(MAX) NULL;
END;
GO

IF COL_LENGTH('dbo.personal', 'foto_perfil_url') IS NOT NULL
BEGIN
    ALTER TABLE dbo.personal ALTER COLUMN foto_perfil_url NVARCHAR(MAX) NULL;
END;
GO
