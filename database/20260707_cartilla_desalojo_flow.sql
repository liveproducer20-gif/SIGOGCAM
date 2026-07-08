USE BITSAC;
GO

PRINT 'Creando tablas para flujo de cartilla Desalojo de Vendedores No Regularizados...';

-- Tabla de servidores policiales
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'servidores_policiales')
BEGIN
    CREATE TABLE dbo.servidores_policiales (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(200) NOT NULL,
        grado NVARCHAR(100),
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
    );
    PRINT '  Tabla dbo.servidores_policiales creada.';
END
ELSE
    PRINT '  dbo.servidores_policiales ya existe.';
GO

-- Insertar servidores policiales por defecto
IF NOT EXISTS (SELECT 1 FROM dbo.servidores_policiales)
BEGIN
    INSERT INTO dbo.servidores_policiales (nombre, grado) VALUES
        (N'Sin servidor policial', NULL),
        (N'Cabo 1° Jose Loor', N'Cabo Primero'),
        (N'Cabo 2° Manuel Mendoza', N'Cabo Segundo'),
        (N'Cabo Jose Loor S', N'Cabo'),
        (N'Cabo Elvis Cevallos', N'Cabo');
    PRINT '  Servidores policiales por defecto insertados.';
END
GO

-- Tabla de direcciones por EAS
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'eas_direcciones')
BEGIN
    CREATE TABLE dbo.eas_direcciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        eas_id INT NOT NULL FOREIGN KEY REFERENCES dbo.eas_estaciones(id),
        direccion NVARCHAR(500) NOT NULL,
        activo BIT DEFAULT 1,
        fecha_creacion DATETIME2 DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2
    );
    PRINT '  Tabla dbo.eas_direcciones creada.';
END
ELSE
    PRINT '  dbo.eas_direcciones ya existe.';
GO

-- Insertar direcciones por defecto para cada EAS (usando la direccion principal)
IF NOT EXISTS (SELECT 1 FROM dbo.eas_direcciones)
BEGIN
    INSERT INTO dbo.eas_direcciones (eas_id, direccion)
    SELECT id, direccion FROM dbo.eas_estaciones WHERE activo = 1;
    PRINT '  Direcciones por defecto insertadas (1 por EAS).';
END
GO

-- Tabla temporal para CP (8h)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'cartilla_temp_cp')
BEGIN
    CREATE TABLE dbo.cartilla_temp_cp (
        id INT IDENTITY(1,1) PRIMARY KEY,
        usuario_id INT NOT NULL FOREIGN KEY REFERENCES dbo.personal(id),
        nombre_cp NVARCHAR(200) NOT NULL,
        fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
    );
    PRINT '  Tabla dbo.cartilla_temp_cp creada.';
END
ELSE
    PRINT '  dbo.cartilla_temp_cp ya existe.';
GO

-- Tabla temporal para seleccion de policia (8h)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = 'cartilla_temp_policia')
BEGIN
    CREATE TABLE dbo.cartilla_temp_policia (
        id INT IDENTITY(1,1) PRIMARY KEY,
        usuario_id INT NOT NULL FOREIGN KEY REFERENCES dbo.personal(id),
        servidor_policial_id INT FOREIGN KEY REFERENCES dbo.servidores_policiales(id),
        fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
    );
    PRINT '  Tabla dbo.cartilla_temp_policia creada.';
END
ELSE
    PRINT '  dbo.cartilla_temp_policia ya existe.';
GO

PRINT '';
PRINT 'Tablas creadas correctamente.';
GO
