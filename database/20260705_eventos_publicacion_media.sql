USE BITSAC;
GO

IF OBJECT_ID('dbo.eventos', 'U') IS NULL
BEGIN
    PRINT 'AVISO: dbo.eventos no existe aun (el esquema base lo crea el backend). Script omitido.';
    RETURN;
END;
GO

IF COL_LENGTH('dbo.eventos', 'prioridad') IS NULL
BEGIN
    ALTER TABLE dbo.eventos ADD prioridad NVARCHAR(30) NULL;
END;
GO

IF COL_LENGTH('dbo.eventos', 'imagen_url') IS NULL
BEGIN
    ALTER TABLE dbo.eventos ADD imagen_url NVARCHAR(MAX) NULL;
END
ELSE
BEGIN
    ALTER TABLE dbo.eventos ALTER COLUMN imagen_url NVARCHAR(MAX) NULL;
END;
GO

IF COL_LENGTH('dbo.eventos', 'pdf_nombre') IS NULL
BEGIN
    ALTER TABLE dbo.eventos ADD pdf_nombre NVARCHAR(255) NULL;
END;
GO

IF COL_LENGTH('dbo.eventos', 'pdf_url') IS NULL
BEGIN
    ALTER TABLE dbo.eventos ADD pdf_url NVARCHAR(MAX) NULL;
END
ELSE
BEGIN
    ALTER TABLE dbo.eventos ALTER COLUMN pdf_url NVARCHAR(MAX) NULL;
END;
GO

IF COL_LENGTH('dbo.eventos', 'notificar') IS NULL
BEGIN
    ALTER TABLE dbo.eventos ADD notificar BIT NOT NULL CONSTRAINT DF_eventos_notificar DEFAULT (1);
END;
GO
