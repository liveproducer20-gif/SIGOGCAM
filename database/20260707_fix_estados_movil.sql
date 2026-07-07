USE BITSAC;
GO

PRINT '=== 1/3: ACTUALIZANDO CATALOGO ESTADOS_MOVIL ===';

-- Cambiar "Mantenimiento" a "En Mantenimiento"
UPDATE cd
SET cd.nombre = N'En Mantenimiento',
    cd.fecha_actualizacion = SYSDATETIME()
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'ESTADOS_MOVIL'
  AND cd.codigo = 'MANTENIMIENTO';

-- Agregar RETENIDO si no existe
IF NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'ESTADOS_MOVIL' AND cd.codigo = 'RETENIDO'
)
BEGIN
    DECLARE @catEstadosId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'ESTADOS_MOVIL');
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catEstadosId, 'RETENIDO', N'Retenido', 40);
END

-- Agregar INHABILITADO si no existe
IF NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'ESTADOS_MOVIL' AND cd.codigo = 'INHABILITADO'
)
BEGIN
    DECLARE @catEstadosId2 INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'ESTADOS_MOVIL');
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catEstadosId2, 'INHABILITADO', N'Inhabilitado', 50);
END

PRINT '=== 2/3: AGREGANDO COLUMNA observacion_estado A moviles ===';

IF COL_LENGTH('dbo.moviles', 'observacion_estado') IS NULL
BEGIN
    ALTER TABLE dbo.moviles ADD observacion_estado NVARCHAR(500) NULL;
    PRINT 'Columna observacion_estado agregada.';
END
ELSE
    PRINT 'Columna observacion_estado ya existe.';
GO

PRINT '=== 3/3: CORRIGIENDO TEXTOS mojibake EN CATALOGOS ===';

-- Reemplazar caracteres rotos comunes en todas las tablas de catalogos
UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, NCHAR(65533), N''),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE '%' + NCHAR(65533) + '%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã³', N'ó'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã³%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã¡', N'á'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã¡%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã©', N'é'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã©%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã­', N'í'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã­%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ãº', N'ú'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ãº%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã±', N'ñ'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã±%';

UPDATE dbo.catalogo_detalles
SET nombre = REPLACE(nombre, N'Ã', N'Á'),
    fecha_actualizacion = SYSDATETIME()
WHERE nombre LIKE N'%Ã%' AND nombre NOT LIKE N'%Ã³%' AND nombre NOT LIKE N'%Ã¡%' AND nombre NOT LIKE N'%Ã©%' AND nombre NOT LIKE N'%Ã­%' AND nombre NOT LIKE N'%Ãº%' AND nombre NOT LIKE N'%Ã±%';

PRINT 'Textos mojibake corregidos.';
GO

PRINT '=== VERIFICACION ===';
SELECT cd.codigo, cd.nombre
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'ESTADOS_MOVIL'
ORDER BY cd.orden;
GO
