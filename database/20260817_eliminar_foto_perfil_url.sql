-- ============================================================================
-- 20260817_eliminar_foto_perfil_url.sql
-- Elimina dbo.personal.foto_perfil_url (columna 100% NULL y sin uso).
--
-- Verificación previa (2026-08-17):
--   - 329/329 filas con NULL (nunca se ha guardado un valor).
--   - Sin referencias en el código de la aplicación (Python/PHP/JS).
--   - Sin referencias en objetos de BD (SPs, vistas, triggers, FKs, defaults).
--   - No existe feature de fotos de perfil en la plataforma.
--   - Tipo NVARCHAR(MAX): la columna muerta más costosa de la tabla.
--
-- Las columnas de horario/rotación (horario_id, intervalo_rotacion_id,
-- tipo_franco_id, plantilla_rotacion_id, fecha_inicio_rotacion,
-- orden_inicio_rotacion, observacion) se CONSERVAN: son el esquema de la
-- funcionalidad de turnos/rotación (catálogos con datos, FKs definidas),
-- pendiente de implementar. NULL es el estado correcto para ellas.
--
-- Idempotente: no hace nada si la columna ya no existe.
-- ============================================================================

IF COL_LENGTH('dbo.personal', 'foto_perfil_url') IS NOT NULL
BEGIN
    PRINT 'Eliminando dbo.personal.foto_perfil_url...';
    ALTER TABLE dbo.personal DROP COLUMN foto_perfil_url;
    PRINT 'Columna foto_perfil_url eliminada.';
END
ELSE
BEGIN
    PRINT 'dbo.personal.foto_perfil_url ya no existe; sin cambios.';
END
GO
