USE BITSAC;
GO

PRINT 'Corrigiendo tablas desalojo...';
GO

-- 1. Dropear tablas en orden inverso de dependencias
IF OBJECT_ID(N'dbo.cartilla_temp_policia', N'U') IS NOT NULL
    DROP TABLE dbo.cartilla_temp_policia;
GO
PRINT '  cartilla_temp_policia eliminada.';
GO

IF OBJECT_ID(N'dbo.cartilla_temp_cp', N'U') IS NOT NULL
    DROP TABLE dbo.cartilla_temp_cp;
GO
PRINT '  cartilla_temp_cp eliminada.';
GO

IF OBJECT_ID(N'dbo.eas_direcciones', N'U') IS NOT NULL
    DROP TABLE dbo.eas_direcciones;
GO
PRINT '  eas_direcciones eliminada.';
GO

IF OBJECT_ID(N'dbo.servidores_policiales', N'U') IS NOT NULL
    DROP TABLE dbo.servidores_policiales;
GO
PRINT '  servidores_policiales eliminada.';
GO

-- 2. Crear servidores_policiales (sin FK inline)
CREATE TABLE dbo.servidores_policiales (
    id INT IDENTITY(1,1) PRIMARY KEY,
    eas_id INT NOT NULL,
    nombre NVARCHAR(200) NOT NULL,
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
GO
PRINT '  servidores_policiales creada.';
GO

-- 3. eas_direcciones
CREATE TABLE dbo.eas_direcciones (
    id INT IDENTITY(1,1) PRIMARY KEY,
    eas_id INT NOT NULL,
    direccion NVARCHAR(500) NOT NULL,
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
GO
PRINT '  eas_direcciones creada.';
GO

-- 4. cartilla_temp_cp
CREATE TABLE dbo.cartilla_temp_cp (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    nombre_cp NVARCHAR(200) NOT NULL,
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
GO
PRINT '  cartilla_temp_cp creada.';
GO

-- 5. cartilla_temp_policia
CREATE TABLE dbo.cartilla_temp_policia (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL,
    servidor_policial_id INT,
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
GO
PRINT '  cartilla_temp_policia creada.';
GO

-- 6. FK condicionales
IF OBJECT_ID(N'dbo.eas_estaciones', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.servidores_policiales ADD CONSTRAINT FK_servidores_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id);
    ALTER TABLE dbo.eas_direcciones ADD CONSTRAINT FK_direcciones_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id);
    PRINT '  FK a eas_estaciones agregadas.';
END
GO

IF OBJECT_ID(N'dbo.personal', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.cartilla_temp_cp ADD CONSTRAINT FK_tempcp_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id);
    ALTER TABLE dbo.cartilla_temp_policia ADD CONSTRAINT FK_temppol_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id);
    PRINT '  FK a personal agregadas.';
END
GO

IF OBJECT_ID(N'dbo.servidores_policiales', N'U') IS NOT NULL
BEGIN
    ALTER TABLE dbo.cartilla_temp_policia ADD CONSTRAINT FK_temppol_servidor FOREIGN KEY (servidor_policial_id) REFERENCES dbo.servidores_policiales(id);
    PRINT '  FK a servidores_policiales agregada.';
END
ELSE
    PRINT '  AVISO: dbo.servidores_policiales no existe. FK_temppol_servidor omitida.';
GO

PRINT '';
PRINT '>>> LISTO -- Todas las tablas recreadas correctamente.';
GO
