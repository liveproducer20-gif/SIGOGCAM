-- ============================================================================
-- 20260817_normalizar_cedulas_seed.sql
-- Normaliza las cédulas de las 180 cuentas creadas por los seeds
-- (seed_personal.py, seed_remaining.py, seed_agente1_100.py, seed_fix.py).
--
-- Análisis (2026-08-17):
--   - Los seeds generan cédulas aleatorias de 10 dígitos SIN aplicar el
--     algoritmo de dígito verificador ecuatoriano -> 180/180 inválidas.
--   - 55 de ellas tienen tercer dígito > 5 (inválido para cédula de persona
--     natural).
--   - Las cuentas seed se identifican por su correo en dominios inventados
--     (@seguraep.gob.ec, @gcam.gob.ec, @seguridad.gob.ec); el dominio real de
--     la organización es @bitsac.local.
--   - NO se tocan las cédulas de la organización (bloque admin 1388-1416 y
--     placeholders 09900000001-120 de 11 dígitos): varias comparten los
--     primeros 9 dígitos (0923456790-9, 0910000010-3...), así que recalcular
--     el dígito verificador crearía duplicados; requieren datos reales.
--
-- Correcciones (idempotentes):
--   1. Tercer dígito > 5 -> '5' (cédula de persona natural).
--   2. Dígito verificador recalculado con el algoritmo oficial.
--   3. fecha_ingreso del registro seed id=2648 (17 años al ingreso) -> día
--      siguiente a cumplir 18.
-- ============================================================================

PRINT '=== 1/3 Tercer dígito > 5 en cuentas seed ===';
UPDATE dbo.personal
SET cedula = STUFF(cedula, 3, 1, '5')
WHERE LEN(cedula) = 10
  AND CAST(SUBSTRING(cedula, 3, 1) AS INT) > 5
  AND (correo_institucional LIKE '%@seguraep.gob.ec'
       OR correo_institucional LIKE '%@gcam.gob.ec'
       OR correo_institucional LIKE '%@seguridad.gob.ec');
PRINT '  OK (filas actualizadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ')';

PRINT '=== 2/3 Dígito verificador recalculado en cuentas seed ===';
UPDATE dbo.personal
SET cedula = LEFT(cedula, 9) + CAST(
    (10 - (SELECT SUM(CASE WHEN t.v * t.w > 9 THEN t.v * t.w - 9 ELSE t.v * t.w END)
           FROM (VALUES
             (2, CAST(SUBSTRING(cedula, 1, 1) AS INT)),
             (1, CAST(SUBSTRING(cedula, 2, 1) AS INT)),
             (2, CAST(SUBSTRING(cedula, 3, 1) AS INT)),
             (1, CAST(SUBSTRING(cedula, 4, 1) AS INT)),
             (2, CAST(SUBSTRING(cedula, 5, 1) AS INT)),
             (1, CAST(SUBSTRING(cedula, 6, 1) AS INT)),
             (2, CAST(SUBSTRING(cedula, 7, 1) AS INT)),
             (1, CAST(SUBSTRING(cedula, 8, 1) AS INT)),
             (2, CAST(SUBSTRING(cedula, 9, 1) AS INT))
           ) t(w, v)) % 10) % 10 AS VARCHAR(1))
WHERE LEN(cedula) = 10
  AND (correo_institucional LIKE '%@seguraep.gob.ec'
       OR correo_institucional LIKE '%@gcam.gob.ec'
       OR correo_institucional LIKE '%@seguridad.gob.ec');
PRINT '  OK (filas actualizadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ')';

PRINT '=== 3/3 Fecha de ingreso del seed id=2648 (17 años al ingreso) ===';
UPDATE dbo.personal
SET fecha_ingreso = DATEADD(DAY, 1, DATEADD(YEAR, 18, fecha_nacimiento))
WHERE id = 2648
  AND DATEADD(YEAR, 18, fecha_nacimiento) > fecha_ingreso;
PRINT '  OK (filas actualizadas: ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ')';
GO
