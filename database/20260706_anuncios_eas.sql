USE BITSAC;
GO

IF OBJECT_ID('dbo.anuncios', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.anuncios (
        id INT IDENTITY(1,1) PRIMARY KEY,
        titulo NVARCHAR(180) NOT NULL,
        descripcion NVARCHAR(MAX) NOT NULL,
        prioridad NVARCHAR(30) NOT NULL CONSTRAINT DF_anuncios_prioridad DEFAULT ('Normal'),
        imagen_nombre NVARCHAR(255) NULL,
        imagen_url NVARCHAR(MAX) NULL,
        fecha_publicacion DATETIME NOT NULL CONSTRAINT DF_anuncios_fecha_publicacion DEFAULT (GETDATE()),
        fecha_expiracion DATETIME NULL,
        publicado BIT NOT NULL CONSTRAINT DF_anuncios_publicado DEFAULT (1),
        notificar BIT NOT NULL CONSTRAINT DF_anuncios_notificar DEFAULT (1),
        creado_por INT NULL,
        fecha_creacion DATETIME NOT NULL CONSTRAINT DF_anuncios_fecha_creacion DEFAULT (GETDATE()),
        fecha_actualizacion DATETIME NULL
    );
END;
GO

IF OBJECT_ID('dbo.anuncio_personal', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.anuncio_personal (
        id INT IDENTITY(1,1) PRIMARY KEY,
        anuncio_id INT NOT NULL,
        personal_id INT NOT NULL,
        fecha_asignacion DATETIME NOT NULL CONSTRAINT DF_anuncio_personal_fecha DEFAULT (GETDATE()),
        fecha_visto DATETIME NULL,
        CONSTRAINT FK_anuncio_personal_anuncio FOREIGN KEY (anuncio_id) REFERENCES dbo.anuncios(id) ON DELETE CASCADE
    );
END;
GO

IF OBJECT_ID('dbo.eas_estaciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.eas_estaciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(20) NOT NULL UNIQUE,
        nombre NVARCHAR(120) NOT NULL,
        ubicacion NVARCHAR(160) NOT NULL,
        direccion NVARCHAR(250) NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_eas_estaciones_activo DEFAULT (1)
    );
END;
GO

MERGE dbo.eas_estaciones AS target
USING (VALUES
    ('ECO 1', 'URDESA', 'URDESA', 'AV. VICTOR EMILIO ESTRADA Y CIRCUNVALACION SUR'),
    ('ECO 2', 'LOMAS DE URDESA', 'LOMAS DE URDESA', 'AV. CERROS Y LOMAS DE URDESA'),
    ('ECO 3', 'KENNEDY VIEJA', 'KENNEDY VIEJA', 'AV. FRANCISCO URBINA Y AV. DEL PERIODISTA'),
    ('ECO 4', 'KENNEDY NUEVA', 'KENNEDY NUEVA', 'AV. JOSE SANTIAGO CASTILLO Y VICTOR HUGO'),
    ('ECO 5', 'FAE/ATARAZANA', 'FAE/ATARAZANA', 'AV. AL RAUL COUSIN Y CRNL LUIS LOPES'),
    ('ECO 6', 'PUERTO SANTA ANA', 'PUERTO SANTA ANA', 'PUERTO SANTA ANA'),
    ('ECO 7', 'SAMANES', 'SAMANES', 'AV TEODORO ALVARADO OLEAS'),
    ('ECO 8', 'PARQUE CENTENARIO', 'PARQUE CENTENARIO', 'CALLE LORENZO DE GARAICOA Y VELEZ'),
    ('ECO 9', 'PLAZA SAN FRANCISCO', 'PLAZA SAN FRANCISCO', 'AV. 9 DE OCTUBRE Y PEDRO CARBO'),
    ('ECO 10', 'VIA A LA COSTA', 'VIA A LA COSTA', 'CDLA. TERRANOSTRA'),
    ('ECO 11', 'BARRIO CENTENARIO', 'BARRIO CENTENARIO', 'AV. DOLORES SUCRE Y MARACAIBO'),
    ('ECO 12', 'CEIBOS', 'CEIBOS', 'DR ALBERTO DACACH Y AV 15AVA NO')
) AS source (codigo, nombre, ubicacion, direccion)
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET nombre = source.nombre, ubicacion = source.ubicacion, direccion = source.direccion, activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, nombre, ubicacion, direccion)
    VALUES (source.codigo, source.nombre, source.ubicacion, source.direccion);
GO

IF OBJECT_ID('dbo.eas_roles_central', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.eas_roles_central (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(80) NOT NULL UNIQUE,
        activo BIT NOT NULL CONSTRAINT DF_eas_roles_central_activo DEFAULT (1)
    );
END;
GO

MERGE dbo.eas_roles_central AS target
USING (VALUES
    ('Jefe de patrulla'),
    ('Conductor'),
    ('Auxiliar'),
    ('Motorizado'),
    ('K9'),
    ('Radioperador'),
    ('Comunicaciones')
) AS source (nombre)
ON target.nombre = source.nombre
WHEN MATCHED THEN
    UPDATE SET activo = 1
WHEN NOT MATCHED THEN
    INSERT (nombre) VALUES (source.nombre);
GO
