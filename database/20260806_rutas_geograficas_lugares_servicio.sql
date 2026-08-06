USE BITSAC;
GO

PRINT '=== INICIO MIGRACION: Distribucion geografica - Rutas y Lugares de servicio ===';

-- ===================================================================
-- 1. TABLA rutas_geograficas (trazado geográfico de rutas)
-- ===================================================================
IF OBJECT_ID('dbo.rutas_geograficas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rutas_geograficas (
        id                    BIGINT IDENTITY(1,1) NOT NULL,
        distrito_id           INT NOT NULL,
        ruta_id               INT NOT NULL,
        nombre                NVARCHAR(150) NOT NULL,
        descripcion           NVARCHAR(500) NULL,
        tipo_geometria        NVARCHAR(20) NOT NULL DEFAULT 'lineal',
        geojson               NVARCHAR(MAX) NULL,
        color                 NVARCHAR(20) NOT NULL DEFAULT '#2563EB',
        grosor                DECIMAL(4,1) NOT NULL DEFAULT 6,
        opacidad              DECIMAL(3,2) NOT NULL DEFAULT 0.55,
        estado                NVARCHAR(20) NOT NULL DEFAULT 'ACTIVA',
        creado_por            INT NOT NULL,
        actualizado_por       INT NULL,
        activo                BIT NOT NULL DEFAULT 1,
        fecha_creacion        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion   DATETIME2 NULL,
        CONSTRAINT PK_rutas_geograficas PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_rutasgeo_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_rutasgeo_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
    );
    PRINT 'OK - Tabla rutas_geograficas creada.';
END
ELSE
    PRINT 'OK - Tabla rutas_geograficas ya existe.';
GO

-- ===================================================================
-- 2. MODIFICAR tabla lugares_servicio: eliminar dependencia de sector
-- ===================================================================
-- La tabla lugares_servicio ya existe. Verificar si tiene sector_id y limpiarlo.
IF COL_LENGTH('dbo.lugares_servicio', 'sector_id') IS NOT NULL
BEGIN
    -- Migrar datos: copiar sector_id a ruta_id si ruta_id es NULL
    UPDATE ls SET ls.ruta_id = s.ruta_id
    FROM dbo.lugares_servicio ls
    INNER JOIN dbo.sectores s ON s.id = ls.sector_id
    WHERE ls.ruta_id IS NULL AND s.ruta_id IS NOT NULL;

    -- Eliminar FK de sector_id si existe
    IF EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_lugares_sector' AND parent_object_id = OBJECT_ID('dbo.lugares_servicio'))
        ALTER TABLE dbo.lugares_servicio DROP CONSTRAINT FK_lugares_sector;

    -- Eliminar columna sector_id
    ALTER TABLE dbo.lugares_servicio DROP COLUMN sector_id;
    PRINT 'OK - Columna sector_id eliminada de lugares_servicio.';
END
GO

-- Asegurar que lugares_servicio tiene ruta_id NOT NULL
IF COL_LENGTH('dbo.lugares_servicio', 'ruta_id') IS NOT NULL
BEGIN
    -- Hacer ruta_id NOT NULL si tiene datos
    DECLARE @count INT;
    SELECT @count = COUNT(*) FROM dbo.lugares_servicio WHERE ruta_id IS NULL;
    IF @count = 0
        ALTER TABLE dbo.lugares_servicio ALTER COLUMN ruta_id INT NOT NULL;
    PRINT 'OK - ruta_id verificado en lugares_servicio.';
END
GO

-- ===================================================================
-- 3. TABLA lugares_servicio (si no existe, crear con estructura correcta)
-- ===================================================================
IF OBJECT_ID('dbo.lugares_servicio', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.lugares_servicio (
        id                    INT IDENTITY(1,1) NOT NULL,
        ruta_id               INT NOT NULL,
        nombre                NVARCHAR(180) NOT NULL,
        descripcion           NVARCHAR(500) NULL,
        direccion_referencial NVARCHAR(300) NULL,
        latitud               DECIMAL(10,7) NULL,
        longitud              DECIMAL(10,7) NULL,
        estado                NVARCHAR(20) NOT NULL DEFAULT 'ACTIVO',
        activo                BIT NOT NULL DEFAULT 1,
        creado_por            INT NOT NULL,
        fecha_creacion        DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion   DATETIME2 NULL,
        CONSTRAINT PK_lugares_servicio PRIMARY KEY CLUSTERED (id),
        CONSTRAINT FK_lugares_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
    );
    PRINT 'OK - Tabla lugares_servicio creada.';
END
GO

-- ===================================================================
-- 4. Migrar datos de sectores a lugares_servicio (si aplica)
-- ===================================================================
IF OBJECT_ID('dbo.sectores', 'U') IS NOT NULL
BEGIN
    -- Copiar sectores que no estén en lugares_servicio como lugares de servicio
    INSERT INTO dbo.lugares_servicio (ruta_id, nombre, descripcion, estado, activo, creado_por, fecha_creacion)
    SELECT s.ruta_id, s.nombre, NULL, 'ACTIVO', 1, ISNULL(s.creado_por, 1), SYSDATETIME()
    FROM dbo.sectores s
    WHERE s.activo = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.lugares_servicio ls WHERE ls.ruta_id = s.ruta_id AND ls.nombre = s.nombre);

    PRINT 'OK - Datos de sectores migrados a lugares_servicio.';
END
GO

PRINT '=== FIN MIGRACION: Distribucion geografica - Rutas y Lugares de servicio ===';
GO
