USE BITSAC;
GO

IF OBJECT_ID('dbo.personal', 'U') IS NULL
BEGIN
    THROW 50003, 'No existe la tabla dbo.personal en la base BITSAC.', 1;
END;
GO

IF COL_LENGTH('dbo.personal', 'password_hash') IS NULL
BEGIN
    ALTER TABLE dbo.personal ADD password_hash NVARCHAR(255) NULL;
END;
GO
