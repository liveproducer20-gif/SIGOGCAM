/*
 * ============================================================
 * Indice para optimizar paginacion y busqueda de personal
 * Fecha: 2026-07-12
 * ============================================================
 *
 * La vista vw_personal_detalle ya incluye los campos filtrados
 * (nombres, apellidos, cedula, correo_institucional) y el ORDER
 * BY se hace sobre apellidos, nombres.  Este indice cubierto
 * evita acceso a la tabla cuando se filtra por activo y se
 * buscan esos campos.
 *
 * Uso: Paginacion con search en GET /api/personal?page=N&search=S
 * ============================================================
 */

USE BITSAC;
GO

PRINT '=== INICIANDO OPTIMIZACION PERSONAL ===';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_personal_busqueda_paginada')
BEGIN
    PRINT 'Creando IX_personal_busqueda_paginada...';
    CREATE NONCLUSTERED INDEX IX_personal_busqueda_paginada
        ON dbo.personal (activo, apellidos, nombres)
        INCLUDE (cedula, correo_institucional, rol_id, estado_personal_id,
                 cargo_id, grado_id, area_id, funcion_operativa_id,
                 jornada_id, grupo_id, tipo_rotacion_id, telefono,
                 fecha_nacimiento, fecha_ingreso);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_personal_busqueda_paginada ya existe';
GO

PRINT '';
PRINT '=== OPTIMIZACION PERSONAL COMPLETADA ===';
GO
