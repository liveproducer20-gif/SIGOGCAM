USE BITSAC;
GO

PRINT '=== 1/4: ACTUALIZANDO FUNCIONES_OPERATIVAS ===';

-- Desactivar RADIOPERADOR
UPDATE cd
SET cd.estado = 0,
    cd.fecha_actualizacion = SYSDATETIME()
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND cd.codigo = 'RADIOPERADOR';

-- Agregar SUPERVISION si no existe
IF NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND cd.codigo = 'SUPERVISION'
)
BEGIN
    DECLARE @catFuncId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'FUNCIONES_OPERATIVAS');
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catFuncId, 'SUPERVISION', N'Supervisión', 25);
END

-- Agregar AUXILIAR si no existe
IF NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND cd.codigo = 'AUXILIAR'
)
BEGIN
    DECLARE @catFuncId2 INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'FUNCIONES_OPERATIVAS');
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catFuncId2, 'AUXILIAR', N'Auxiliar', 35);
END

-- Reordenar: ENCARGADO=10, SUPERVISION=20, ADMINISTRATIVO=30, FILA_PEDESTRE=40, AUXILIAR=50
UPDATE cd
SET cd.orden = CASE cd.codigo
    WHEN 'ENCARGADO' THEN 10
    WHEN 'SUPERVISION' THEN 20
    WHEN 'ADMINISTRATIVO' THEN 30
    WHEN 'FILA_PEDESTRE' THEN 40
    WHEN 'AUXILIAR' THEN 50
    ELSE cd.orden
END,
cd.fecha_actualizacion = SYSDATETIME()
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'FUNCIONES_OPERATIVAS'
  AND cd.codigo IN ('ENCARGADO','SUPERVISION','ADMINISTRATIVO','FILA_PEDESTRE','AUXILIAR');

PRINT '=== 2/4: ACTUALIZANDO AREAS ===';

-- Agregar AGENTE a AREAS si no existe
IF NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'AREAS' AND cd.codigo = 'AGENTE'
)
BEGIN
    DECLARE @catAreaId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'AREAS');
    INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
    VALUES (@catAreaId, 'AGENTE', N'Agente', 40);
END

-- Eliminar SUPERVISION de AREAS si existe
IF EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
    WHERE c.codigo = 'AREAS' AND cd.codigo = 'SUPERVISION'
)
BEGIN
    DECLARE @supAreaId INT = (SELECT cd.id FROM dbo.catalogo_detalles cd
        INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
        WHERE c.codigo = 'AREAS' AND cd.codigo = 'SUPERVISION');
    DELETE FROM dbo.catalogo_detalles WHERE id = @supAreaId;
END

PRINT '=== 3/4: CORRIGIENDO TILDES EN CATALOGOS ===';

UPDATE cd
SET cd.nombre = N'Rotación',
    cd.fecha_actualizacion = SYSDATETIME()
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'TIPOS_ROTACION' AND cd.codigo = 'ROTATIVA' AND cd.nombre = N'Rotativa';

UPDATE cd
SET cd.nombre = N'Teléfono',
    cd.fecha_actualizacion = SYSDATETIME()
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'TIPOS_SERVICIO_LUGAR' AND cd.codigo = 'OTRO' AND cd.nombre = N'Telefono';

PRINT '=== 4/4: CORRIGIENDO TILDES EN CATALOGOS MAESTROS ===';

UPDATE dbo.catalogos
SET nombre = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        nombre,
        N'Rotacion', N'Rotación'),
        N'Asignacion', N'Asignación'),
        N'Vehiculos', N'Vehículos'),
        N'Catalogo', N'Catálogo'),
        N'Operaciones', N'Operaciones'),
        N'Institucional', N'Institucional'),
        N'descripcion', N'descripción')
WHERE nombre LIKE N'%Rotacion%'
   OR nombre LIKE N'%Asignacion%'
   OR nombre LIKE N'%Vehiculos%'
   OR nombre LIKE N'%Catalogo%'
   OR nombre LIKE N'%Operaciones%';

PRINT '=== VERIFICACION ===';
PRINT 'FUNCIONES_OPERATIVAS activas:';
SELECT cd.codigo, cd.nombre, cd.orden
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND cd.estado = 1
ORDER BY cd.orden;

PRINT 'AREAS:';
SELECT cd.codigo, cd.nombre, cd.orden
FROM dbo.catalogo_detalles cd
INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
WHERE c.codigo = 'AREAS'
ORDER BY cd.orden;
GO
