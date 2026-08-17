-- =====================================================================
-- Corrección de NULLs en dbo.lugares_servicio
-- 1) turno_id: se hereda del turno de la ruta cuando falta.
-- 2) tipo_servicio_id: los registros marcadores (ENCARGADO DE RUTA /
--    DISTRITO / CIRCUITO) reciben el tipo del catálogo homónimo.
-- Idempotente: solo actualiza filas con NULL y con coincidencia exacta.
-- =====================================================================
SET NOCOUNT ON;
USE [BITSAC];
GO

-- 1) Backfill de turno_id desde la ruta
UPDATE ls
SET    ls.turno_id = r.turno_id,
       ls.fecha_actualizacion = SYSDATETIME()
FROM   dbo.lugares_servicio ls
INNER JOIN dbo.rutas r ON r.id = ls.ruta_id
WHERE  ls.activo = 1
  AND  ls.turno_id IS NULL
  AND  r.turno_id IS NOT NULL;

PRINT N'1) Lugares con turno heredado de la ruta: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- 2) Tipo de servicio para marcadores de encargado (coincidencia por nombre)
UPDATE ls
SET    ls.tipo_servicio_id = cd.id,
       ls.fecha_actualizacion = SYSDATETIME()
FROM   dbo.lugares_servicio ls
INNER JOIN dbo.catalogos c
        ON c.codigo = N'TIPOS_SERVICIO_LUGAR' AND c.estado = 1
INNER JOIN dbo.catalogo_detalles cd
        ON cd.catalogo_id = c.id
       AND UPPER(LTRIM(RTRIM(cd.nombre))) = UPPER(LTRIM(RTRIM(ls.nombre)))
       AND cd.estado = 1
WHERE  ls.activo = 1
  AND  ls.tipo_servicio_id IS NULL;

PRINT N'2) Marcadores con tipo de servicio asignado: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- 3) Verificación posterior
SELECT
    (SELECT COUNT(*) FROM dbo.lugares_servicio WHERE activo = 1 AND turno_id IS NULL)      AS lugares_sin_turno,
    (SELECT COUNT(*) FROM dbo.lugares_servicio WHERE activo = 1 AND tipo_servicio_id IS NULL) AS lugares_sin_tipo;
GO
