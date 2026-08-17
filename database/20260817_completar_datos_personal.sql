-- =====================================================================
-- Completar datos faltantes de dbo.personal (cargo, area, grado,
-- funcion operativa) validando contra los catálogos existentes.
--
-- Reglas (todo derivado de catálogos y del patrón dominante de la BD):
--  1) grado  <- espejo del cargo cuando el cargo está en CARGOS y existe
--              un grado con el mismo nombre (Agente 1..4, Inspector,
--              Jefe de Control Municipal).
--  2) grado  <- valor modal por rol para los que siguen sin grado
--              (incluye remapear el grado huérfano 1107 que ya no existe).
--  3) cargo  <- espejo del grado cuando existe un cargo con el mismo nombre.
--  4) cargo  <- valor modal por rol.
--  5) area   <- valor modal por rol.
--  6) funcion<- valor modal por rol.
--  7) CARGO con referencia fuera del catálogo CARGOS: se remapea al
--     cargo modal del rol cuando existe (los roles administrativos sin
--     equivalente en CARGOS conservan su valor).
--
-- Idempotente: solo actualiza filas con NULL (o grado inválido).
-- Ejecutar como un solo lote (no separar con GO).
-- =====================================================================
SET NOCOUNT ON;
USE [BITSAC];

DECLARE @cargos_cat INT = (SELECT id FROM dbo.catalogos WHERE codigo = N'CARGOS');
DECLARE @mapa_rol TABLE (rol_codigo NVARCHAR(80), grado_nombre NVARCHAR(80) NULL, cargo_nombre NVARCHAR(80) NULL, area_nombre NVARCHAR(80) NULL, funcion_nombre NVARCHAR(80) NULL);
INSERT INTO @mapa_rol (rol_codigo, grado_nombre, cargo_nombre, area_nombre, funcion_nombre) VALUES
(N'ADMINISTRADOR',       N'Jefe de Control Municipal', N'Jefe de Control Municipal', N'Administración',   N'Encargado'),
(N'AGENTE',              N'Agente 1',                  N'Agente 1',                  N'Operativa',        N'Fila/Pedestre'),
(N'INSPECTOR',           N'Inspector',                 N'Inspector',                 N'Operativa',        N'Supervisión'),
(N'ENCARGADO',           N'Agente 3',                  N'Agente 3',                  N'Operativa',        N'Encargado'),
(N'OPERACIONES',         NULL,                         NULL,                         N'Operativa',        N'Encargado'),
(N'SUPERVISOR',          NULL,                         NULL,                         N'Operativa',        N'Supervisión'),
(N'AUDITORIA',           NULL,                         NULL,                         N'Administración',   N'Administrativo'),
(N'AUDITOR',             NULL,                         NULL,                         N'Administración',   N'Administrativo'),
(N'COMUNICACIONES',      NULL,                         NULL,                         N'Comunicaciones',   N'Administrativo'),
(N'RADIOPERADOR_SEGURA_EP', NULL,                      NULL,                         N'Radioperador',     NULL);

-- 1) GRADO desde CARGO (espejo por nombre)
UPDATE p
SET    p.grado_id = g.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.catalogo_detalles cd
        ON cd.id = p.cargo_id AND cd.catalogo_id = @cargos_cat
INNER JOIN dbo.grados g
        ON g.nombre = cd.nombre AND g.activo = 1
WHERE  p.grado_id IS NULL;
PRINT N'1) grados desde cargo (espejo): ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 2) GRADO modal por rol (y remapear grado huerfano 1107)
UPDATE p
SET    p.grado_id = g.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
INNER JOIN @mapa_rol m ON m.rol_codigo = UPPER(r.codigo)
INNER JOIN dbo.grados g ON g.nombre = m.grado_nombre AND g.activo = 1
WHERE  m.grado_nombre IS NOT NULL
  AND  (p.grado_id IS NULL OR p.grado_id NOT IN (SELECT id FROM dbo.grados WHERE activo = 1));
PRINT N'2) grados modal por rol: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 3) CARGO desde GRADO (espejo por nombre)
UPDATE p
SET    p.cargo_id = cd.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.grados g ON g.id = p.grado_id
INNER JOIN dbo.catalogo_detalles cd
        ON cd.nombre = g.nombre AND cd.catalogo_id = @cargos_cat
WHERE  p.cargo_id IS NULL;
PRINT N'3) cargos desde grado (espejo): ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 4) CARGO modal por rol
UPDATE p
SET    p.cargo_id = cd.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
INNER JOIN @mapa_rol m ON m.rol_codigo = UPPER(r.codigo)
INNER JOIN dbo.catalogo_detalles cd
        ON cd.nombre = m.cargo_nombre AND cd.catalogo_id = @cargos_cat
WHERE  m.cargo_nombre IS NOT NULL
  AND  p.cargo_id IS NULL;
PRINT N'4) cargos modal por rol: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 5) AREA modal por rol
UPDATE p
SET    p.area_id = cd.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
INNER JOIN @mapa_rol m ON m.rol_codigo = UPPER(r.codigo)
INNER JOIN dbo.catalogos c ON c.codigo = N'AREAS'
INNER JOIN dbo.catalogo_detalles cd
        ON cd.catalogo_id = c.id AND cd.nombre = m.area_nombre
WHERE  m.area_nombre IS NOT NULL
  AND  p.area_id IS NULL;
PRINT N'5) areas modal por rol: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 6) FUNCION modal por rol
UPDATE p
SET    p.funcion_operativa_id = cd.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
INNER JOIN @mapa_rol m ON m.rol_codigo = UPPER(r.codigo)
INNER JOIN dbo.catalogos c ON c.codigo = N'FUNCIONES_OPERATIVAS'
INNER JOIN dbo.catalogo_detalles cd
        ON cd.catalogo_id = c.id AND cd.nombre = m.funcion_nombre
WHERE  m.funcion_nombre IS NOT NULL
  AND  p.funcion_operativa_id IS NULL;
PRINT N'6) funciones modal por rol: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 7) CARGO con referencia fuera del catalogo CARGOS -> cargo modal del rol
UPDATE p
SET    p.cargo_id = cd.id,
       p.fecha_actualizacion = SYSDATETIME()
FROM   dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
INNER JOIN @mapa_rol m ON m.rol_codigo = UPPER(r.codigo)
LEFT JOIN dbo.catalogo_detalles cd_actual ON cd_actual.id = p.cargo_id
LEFT JOIN dbo.catalogos cat_actual ON cat_actual.id = cd_actual.catalogo_id
INNER JOIN dbo.catalogo_detalles cd
        ON cd.nombre = m.cargo_nombre AND cd.catalogo_id = @cargos_cat
WHERE  m.cargo_nombre IS NOT NULL
  AND  ISNULL(cat_actual.codigo, N'') <> N'CARGOS';
PRINT N'7) cargos corregidos (fuera de CARGOS): ' + CAST(@@ROWCOUNT AS NVARCHAR(10));

-- 8) Verificacion posterior
SELECT
    (SELECT COUNT(*) FROM dbo.personal WHERE cargo_id IS NULL)              AS sin_cargo,
    (SELECT COUNT(*) FROM dbo.personal WHERE area_id IS NULL)               AS sin_area,
    (SELECT COUNT(*) FROM dbo.personal WHERE grado_id IS NULL)              AS sin_grado,
    (SELECT COUNT(*) FROM dbo.personal WHERE funcion_operativa_id IS NULL)  AS sin_funcion,
    (SELECT COUNT(*) FROM dbo.personal)                                     AS total;
