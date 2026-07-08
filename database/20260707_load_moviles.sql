USE BITSAC;
GO

PRINT '=== 1/4: CREANDO CATALOGO TIPOS_MANTENIMIENTO ===';

IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_MANTENIMIENTO')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion)
    VALUES ('TIPOS_MANTENIMIENTO', N'Tipos de Mantenimiento', N'Tipos de mantenimiento de moviles');

DECLARE @catMantId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'TIPOS_MANTENIMIENTO');

IF NOT EXISTS (SELECT 1 FROM dbo.catalogo_detalles WHERE catalogo_id = @catMantId AND codigo = 'PREVENTIVO')
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catMantId, 'PREVENTIVO', N'Preventivo', 10);

IF NOT EXISTS (SELECT 1 FROM dbo.catalogo_detalles WHERE catalogo_id = @catMantId AND codigo = 'CORRECTIVO')
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catMantId, 'CORRECTIVO', N'Correctivo', 20);

PRINT '=== 2/4: CREANDO TABLA movil_mantenimiento ===';

IF OBJECT_ID('dbo.movil_mantenimiento', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.movil_mantenimiento (
        id INT IDENTITY(1,1) PRIMARY KEY,
        movil_id INT NOT NULL,
        fecha_mantenimiento DATETIME2 NOT NULL,
        kilometraje INT NOT NULL,
        descripcion NVARCHAR(500) NULL,
        tipo_mantenimiento_id INT NULL,
        activo BIT NOT NULL CONSTRAINT DF_movil_mant_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_movil_mant_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_movil_mant_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id)
    );

    PRINT 'Tabla movil_mantenimiento creada.';
END
ELSE
    PRINT 'Tabla movil_mantenimiento ya existe.';
GO

PRINT '=== 3/4: CARGANDO TIPOS_MOVIL Y ESTADOS_MOVIL ===';

DECLARE @tipoCamioneta INT, @tipoMoto INT, @tipoBici INT, @tipoOtro INT;
DECLARE @estadoOperativo INT;

SELECT @tipoCamioneta = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'CAMIONETA';
SELECT @tipoMoto = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'MOTOCICLETA';
SELECT @tipoBici = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'BICICLETA';
SELECT @tipoOtro = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'OTRO';
SELECT @estadoOperativo = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'ESTADOS_MOVIL' AND cd.codigo = 'OPERATIVO';

IF @tipoCamioneta IS NULL OR @tipoMoto IS NULL OR @tipoBici IS NULL OR @tipoOtro IS NULL OR @estadoOperativo IS NULL
BEGIN
    PRINT 'ERROR: No se encontraron catalogos TIPOS_MOVIL / ESTADOS_MOVIL';
    THROW 50000, 'Catalogos de movil no encontrados', 1;
END
GO

PRINT '=== 4/4: INSERTANDO MOVILES 01-220 ===';

DECLARE @i INT = 1;
DECLARE @tipoCamioneta INT, @tipoMoto INT, @tipoBici INT, @tipoOtro INT;
DECLARE @estadoOperativo INT;

SELECT @tipoCamioneta = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'CAMIONETA';
SELECT @tipoMoto = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'MOTOCICLETA';
SELECT @tipoBici = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'BICICLETA';
SELECT @tipoOtro = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'TIPOS_MOVIL' AND cd.codigo = 'OTRO';
SELECT @estadoOperativo = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id WHERE c.codigo = 'ESTADOS_MOVIL' AND cd.codigo = 'OPERATIVO';

WHILE @i <= 220
BEGIN
    DECLARE @num NVARCHAR(10) = RIGHT('0' + CAST(@i AS NVARCHAR), 2);
    DECLARE @nombreMovil NVARCHAR(80) = 'Movil ' + @num;
    DECLARE @tipoId INT = CASE
        WHEN @i BETWEEN 1 AND 80 THEN @tipoCamioneta
        WHEN @i BETWEEN 81 AND 140 THEN @tipoMoto
        WHEN @i BETWEEN 141 AND 180 THEN @tipoBici
        ELSE @tipoOtro
    END;

    IF NOT EXISTS (SELECT 1 FROM dbo.moviles WHERE numero_movil = @nombreMovil)
    BEGIN
        INSERT INTO dbo.moviles (numero_movil, placa, tipo_movil_id, kilometraje_actual, kilometraje_ultimo_mantenimiento, estado_movil_id, activo)
        VALUES (@nombreMovil, NULL, @tipoId, 0, 0, @estadoOperativo, 1);
    END

    SET @i = @i + 1;
END

PRINT 'Moviles insertados/verificados (01-220).';
GO

PRINT '=== VERIFICACION ===';
SELECT COUNT(*) AS total_moviles FROM dbo.moviles;
GO
