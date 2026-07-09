/*
 * ============================================================
 * Script de optimizacion SQL para modulo de administracion
 * Fecha: 2026-07-11
 * Descripcion: Indices y mejoras para consultas administrativas
 * ============================================================
 * 
 * Cambios:
 * 1. IX_rol_permiso_rol - Acelera busqueda de permisos por rol
 * 2. IX_rol_permiso_permiso - Acelera busqueda de permisos
 * 3. IX_catalogo_detalles_catalogo_orden - Mejora ordenamiento x catalogo
 * 4. IX_personal_activo_rol - Filtro rapido personal activo por rol
 * 5. IX_moviles_numero_activo - Filtro rapido moviles por num/activo
 * 
 * Todos los indices son NO-CLUSTER y NO destructivos.
 * Se usa IF NOT EXISTS (via index name check) para ser seguros.
 * ============================================================
 */

USE BITSAC;
GO

PRINT '=== INICIANDO OPTIMIZACION ADMIN ===';
GO

-- ============================================================
-- 1. Indice compuesto para busqueda de permisos de un rol
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rol_permiso_rol_permiso')
BEGIN
    PRINT 'Creando IX_rol_permiso_rol_permiso...';
    CREATE NONCLUSTERED INDEX IX_rol_permiso_rol_permiso
        ON dbo.rol_permiso (rol_id, permiso_id)
        INCLUDE (fecha_asignacion);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_rol_permiso_rol_permiso ya existe';
GO

-- ============================================================
-- 2. Indice para busqueda de rol_permiso por permiso
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_rol_permiso_permiso_id')
BEGIN
    PRINT 'Creando IX_rol_permiso_permiso_id...';
    CREATE NONCLUSTERED INDEX IX_rol_permiso_permiso_id
        ON dbo.rol_permiso (permiso_id)
        INCLUDE (rol_id);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_rol_permiso_permiso_id ya existe';
GO

-- ============================================================
-- 3. Indice para ordenar detalles de catalogo
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_catalogo_detalles_catalogo_orden')
BEGIN
    PRINT 'Creando IX_catalogo_detalles_catalogo_orden...';
    CREATE NONCLUSTERED INDEX IX_catalogo_detalles_catalogo_orden
        ON dbo.catalogo_detalles (catalogo_id, orden, nombre)
        INCLUDE (codigo, descripcion, estado);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_catalogo_detalles_catalogo_orden ya existe';
GO

-- ============================================================
-- 4. Indice para filtrar personal activo por rol
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_personal_activo_rol')
BEGIN
    PRINT 'Creando IX_personal_activo_rol...';
    CREATE NONCLUSTERED INDEX IX_personal_activo_rol
        ON dbo.personal (activo, rol_id)
        INCLUDE (cedula, nombres, apellidos, correo_institucional);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_personal_activo_rol ya existe';
GO

-- ============================================================
-- 5. Indice para filtrar y ordenar moviles
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_moviles_numero_activo')
BEGIN
    PRINT 'Creando IX_moviles_numero_activo...';
    CREATE NONCLUSTERED INDEX IX_moviles_numero_activo
        ON dbo.moviles (activo, numero_movil)
        INCLUDE (placa, tipo_movil_id, estado_movil_id, kilometraje_actual, proximo_mantenimiento);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_moviles_numero_activo ya existe';
GO

-- ============================================================
-- 6. Indice para busqueda de lugares por direccion
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lugares_servicio_activo_ruta')
BEGIN
    PRINT 'Creando IX_lugares_servicio_activo_ruta...';
    CREATE NONCLUSTERED INDEX IX_lugares_servicio_activo_ruta
        ON dbo.lugares_servicio (activo, ruta_id)
        INCLUDE (direccion, distrito_id, hora_entrada, hora_salida, consignas);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_lugares_servicio_activo_ruta ya existe';
GO

-- ============================================================
-- 7. Indice para busqueda de EAS por codigo/nombre
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_eas_estaciones_codigo_nombre')
BEGIN
    PRINT 'Creando IX_eas_estaciones_codigo_nombre...';
    CREATE NONCLUSTERED INDEX IX_eas_estaciones_codigo_nombre
        ON dbo.eas_estaciones (activo, codigo, nombre)
        INCLUDE (direccion, distrito_id);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_eas_estaciones_codigo_nombre ya existe';
GO

-- ============================================================
-- 8. Indice para busqueda de catalogos por codigo
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_catalogos_codigo')
BEGIN
    PRINT 'Creando IX_catalogos_codigo...';
    CREATE NONCLUSTERED INDEX IX_catalogos_codigo
        ON dbo.catalogos (codigo)
        INCLUDE (nombre, descripcion, estado);
    PRINT '  OK';
END
ELSE
    PRINT 'IX_catalogos_codigo ya existe';
GO

PRINT '';
PRINT '=== OPTIMIZACION ADMIN COMPLETADA ===';
GO
