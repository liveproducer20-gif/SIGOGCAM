-- ============================================================================
-- 20260817_limpiar_tipo_rotacion_id.sql
-- Pone en NULL dbo.personal.tipo_rotacion_id (29 registros de residuo de seed).
--
-- Análisis (2026-08-17):
--   - Los 29 registros con valor son exactamente el bloque contiguo de ids
--     1388-1416 (las primeras filas de la tabla, insertadas el 2026-08-04);
--     el resto del personal (lote 2026-08-11) no tiene el campo.
--   - Ninguno tiene los parámetros de rotación (plantilla_rotacion_id,
--     intervalo_rotacion_id, fecha_inicio_rotacion, orden_inicio_rotacion,
--     tipo_franco_id): un "Rotación" sin intervalo/plantilla no es dato
--     accionable.
--   - La mezcla 20 Fija / 9 Rotación repartida uniformemente en TODOS los
--     roles (incluidos Administración y Comunicaciones) no sigue lógica de
--     dominio; es asignación masiva del script de carga.
--   - La columna no tiene FK ni consumidores (0 referencias en la app y en
--     objetos de BD).
--
-- Decisión: NULL (estado "sin dato") hasta que se implemente la funcionalidad
-- de rotación y se asigne desde un flujo real. Los únicos valores posibles
-- eran 122 (Fija) / 123 (Rotación), así que es trivialmente recuperable.
--
-- Idempotente: la segunda ejecución no encuentra filas que actualizar.
-- ============================================================================

DECLARE @n INT;

SELECT @n = COUNT(*) FROM dbo.personal WHERE tipo_rotacion_id IS NOT NULL;

IF @n > 0
BEGIN
    PRINT 'Limpiando tipo_rotacion_id en ' + CAST(@n AS VARCHAR(10)) + ' registros...';
    UPDATE dbo.personal SET tipo_rotacion_id = NULL WHERE tipo_rotacion_id IS NOT NULL;
    PRINT 'Registros limpiados.';
END
ELSE
BEGIN
    PRINT 'No hay registros con tipo_rotacion_id; sin cambios.';
END
GO
