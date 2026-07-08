USE BITSAC;
GO

PRINT 'Creando tablas para flujo de cartilla Desalojo de Vendedores No Regularizados...';

-- Tabla de servidores policiales por EAS
IF OBJECT_ID(N'dbo.cartilla_temp_policia', N'U') IS NOT NULL
    DROP TABLE dbo.cartilla_temp_policia;
GO
IF OBJECT_ID(N'dbo.servidores_policiales', N'U') IS NOT NULL
    DROP TABLE dbo.servidores_policiales;
GO

CREATE TABLE dbo.servidores_policiales (
    id INT IDENTITY(1,1) PRIMARY KEY,
    eas_id INT NOT NULL FOREIGN KEY REFERENCES dbo.eas_estaciones(id),
    nombre NVARCHAR(200) NOT NULL,
    activo BIT DEFAULT 1,
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
PRINT '  Tabla dbo.servidores_policiales creada (por EAS).';
GO

-- Tabla de direcciones por EAS
IF OBJECT_ID(N'dbo.eas_direcciones', N'U') IS NULL
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

-- Insertar direcciones por defecto para cada EAS (solo si la tabla está vacía)
IF NOT EXISTS (SELECT 1 FROM dbo.eas_direcciones)
BEGIN
    INSERT INTO dbo.eas_direcciones (eas_id, direccion)
    SELECT id, direccion FROM dbo.eas_estaciones WHERE activo = 1;
    PRINT '  Direcciones por defecto insertadas (1 por EAS).';
END
GO

-- Tabla temporal para CP (8h)
IF OBJECT_ID(N'dbo.cartilla_temp_cp', N'U') IS NULL
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
CREATE TABLE dbo.cartilla_temp_policia (
    id INT IDENTITY(1,1) PRIMARY KEY,
    usuario_id INT NOT NULL FOREIGN KEY REFERENCES dbo.personal(id),
    servidor_policial_id INT FOREIGN KEY REFERENCES dbo.servidores_policiales(id),
    fecha_creacion DATETIME2 DEFAULT SYSDATETIME()
);
PRINT '  Tabla dbo.cartilla_temp_policia creada.';
GO

PRINT '';
PRINT 'Tablas creadas correctamente.';
GO
