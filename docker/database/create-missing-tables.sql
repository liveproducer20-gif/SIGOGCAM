SET NOCOUNT ON;
USE [BITSAC];
GO

-- 1. turnos
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'turnos')
BEGIN
    CREATE TABLE dbo.turnos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        hora_inicio TIME(0) NULL,
        hora_fin TIME(0) NULL,
        activo BIT NOT NULL DEFAULT 1,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
    INSERT INTO dbo.turnos (nombre, hora_inicio, hora_fin) VALUES
        ('MATUTINO', '06:00', '14:00'),
        ('VESPERTINO', '14:00', '22:00'),
        ('NOCTURNO', '22:00', '06:00');
    PRINT 'Tabla turnos creada.';
END
ELSE PRINT 'turnos ya existe.';
GO

-- 2. sectores
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'sectores')
BEGIN
    CREATE TABLE dbo.sectores (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(150) NOT NULL,
        distrito_id INT NULL,
        ruta_id INT NULL,
        activo BIT NOT NULL DEFAULT 1,
        cantidad_agentes_requeridos INT NOT NULL DEFAULT 0,
        orden_distribucion INT NOT NULL DEFAULT 0,
        creado_por INT NULL,
        actualizado_por INT NULL,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NULL
    );
    PRINT 'Tabla sectores creada.';
END
ELSE PRINT 'sectores ya existe.';
GO

-- 3. asignaciones_punto
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'asignaciones_punto')
BEGIN
    CREATE TABLE dbo.asignaciones_punto (
        id INT IDENTITY(1,1) PRIMARY KEY,
        punto_id INT NULL,
        personal_id INT NULL,
        tipo_asignacion NVARCHAR(50) NOT NULL DEFAULT 'FIJA',
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE NULL,
        turno_id INT NULL,
        hora_inicio TIME(0) NULL,
        hora_fin TIME(0) NULL,
        funcion NVARCHAR(100) NULL,
        observaciones NVARCHAR(500) NULL,
        estado NVARCHAR(30) NOT NULL DEFAULT 'ACTIVA',
        activo BIT NOT NULL DEFAULT 1,
        creado_por INT NULL,
        actualizado_por INT NULL,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NULL
    );
    PRINT 'Tabla asignaciones_punto creada.';
END
ELSE PRINT 'asignaciones_punto ya existe.';
GO

-- 4. asignaciones_ruta
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'asignaciones_ruta')
BEGIN
    CREATE TABLE dbo.asignaciones_ruta (
        id INT IDENTITY(1,1) PRIMARY KEY,
        agente_id INT NULL,
        distrito_id INT NULL,
        ruta_id INT NULL,
        sector_id INT NULL,
        fecha_asignacion DATE NOT NULL,
        turno NVARCHAR(100) NULL,
        hora_inicio TIME(0) NULL,
        hora_fin TIME(0) NULL,
        estado NVARCHAR(30) NOT NULL DEFAULT 'PENDIENTE',
        tipo_asignacion NVARCHAR(30) NOT NULL DEFAULT 'ALEATORIA',
        sorteo_id NVARCHAR(100) NULL,
        asignado_por INT NULL,
        observacion NVARCHAR(500) NULL,
        deleted_at DATETIME2 NULL,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        fecha_actualizacion DATETIME2 NULL
    );
    PRINT 'Tabla asignaciones_ruta creada.';
END
ELSE PRINT 'asignaciones_ruta ya existe.';
GO

-- 5. sorteos_historial
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'sorteos_historial')
BEGIN
    CREATE TABLE dbo.sorteos_historial (
        id INT IDENTITY(1,1) PRIMARY KEY,
        sorteo_id NVARCHAR(100) NOT NULL,
        usuario_id INT NULL,
        distrito_id INT NULL,
        ruta_id INT NULL,
        fecha_servicio DATE NOT NULL,
        turno NVARCHAR(100) NULL,
        hora_inicio TIME(0) NULL,
        hora_fin TIME(0) NULL,
        sectores_incluidos NVARCHAR(MAX) NULL,
        agentes_requeridos INT NOT NULL DEFAULT 0,
        agentes_disponibles INT NOT NULL DEFAULT 0,
        agentes_seleccionados INT NOT NULL DEFAULT 0,
        agentes_confirmados INT NOT NULL DEFAULT 0,
        veces_sorteo INT NOT NULL DEFAULT 1,
        resultado NVARCHAR(50) NOT NULL DEFAULT 'CONFIRMADO',
        ip NVARCHAR(50) NULL,
        fecha_ejecucion DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        deleted_at DATETIME2 NULL
    );
    PRINT 'Tabla sorteos_historial creada.';
END
ELSE PRINT 'sorteos_historial ya existe.';
GO

-- 6. registro_cambios
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'registro_cambios')
BEGIN
    CREATE TABLE dbo.registro_cambios (
        id INT IDENTITY(1,1) PRIMARY KEY,
        desarrollador NVARCHAR(150) NOT NULL,
        fecha DATE NOT NULL,
        hora TIME(0) NOT NULL,
        titulo NVARCHAR(200) NOT NULL,
        detalle NVARCHAR(MAX) NULL,
        fecha_creacion DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
    PRINT 'Tabla registro_cambios creada.';
END
ELSE PRINT 'registro_cambios ya existe.';
GO

PRINT 'Script completado.';
GO
