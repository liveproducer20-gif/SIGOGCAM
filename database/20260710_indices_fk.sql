USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== AGREGANDO INDICES EN FK MAS USADAS ===';

-- moviles
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_moviles_tipo_movil_id' AND object_id = OBJECT_ID('dbo.moviles'))
BEGIN
    CREATE INDEX IX_moviles_tipo_movil_id ON dbo.moviles(tipo_movil_id);
    PRINT '  IX_moviles_tipo_movil_id creado.';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_moviles_estado_movil_id' AND object_id = OBJECT_ID('dbo.moviles'))
BEGIN
    CREATE INDEX IX_moviles_estado_movil_id ON dbo.moviles(estado_movil_id);
    PRINT '  IX_moviles_estado_movil_id creado.';
END

-- eas_estaciones
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_eas_estaciones_distrito_id' AND object_id = OBJECT_ID('dbo.eas_estaciones'))
BEGIN
    CREATE INDEX IX_eas_estaciones_distrito_id ON dbo.eas_estaciones(distrito_id);
    PRINT '  IX_eas_estaciones_distrito_id creado.';
END

-- lugares_servicio
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lugares_servicio_distrito_id' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
BEGIN
    CREATE INDEX IX_lugares_servicio_distrito_id ON dbo.lugares_servicio(distrito_id);
    PRINT '  IX_lugares_servicio_distrito_id creado.';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lugares_servicio_ruta_id' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
BEGIN
    CREATE INDEX IX_lugares_servicio_ruta_id ON dbo.lugares_servicio(ruta_id);
    PRINT '  IX_lugares_servicio_ruta_id creado.';
END

-- movil_eas_asignaciones
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_movil_eas_asignaciones_eas_id' AND object_id = OBJECT_ID('dbo.movil_eas_asignaciones'))
BEGIN
    CREATE INDEX IX_movil_eas_asignaciones_eas_id ON dbo.movil_eas_asignaciones(eas_id);
    PRINT '  IX_movil_eas_asignaciones_eas_id creado.';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_movil_eas_asignaciones_movil_id' AND object_id = OBJECT_ID('dbo.movil_eas_asignaciones'))
BEGIN
    CREATE INDEX IX_movil_eas_asignaciones_movil_id ON dbo.movil_eas_asignaciones(movil_id);
    PRINT '  IX_movil_eas_asignaciones_movil_id creado.';
END

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_movil_eas_asignaciones_estado_asignacion_id' AND object_id = OBJECT_ID('dbo.movil_eas_asignaciones'))
BEGIN
    CREATE INDEX IX_movil_eas_asignaciones_estado_asignacion_id ON dbo.movil_eas_asignaciones(estado_asignacion_id);
    PRINT '  IX_movil_eas_asignaciones_estado_asignacion_id creado.';
END

-- catalogo_detalles (para queries que buscan por catalogo_id + codigo)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_catalogo_detalles_catalogo_id_codigo' AND object_id = OBJECT_ID('dbo.catalogo_detalles'))
BEGIN
    CREATE INDEX IX_catalogo_detalles_catalogo_id_codigo ON dbo.catalogo_detalles(catalogo_id, codigo);
    PRINT '  IX_catalogo_detalles_catalogo_id_codigo creado.';
END

PRINT '=== VERIFICACION ===';
SELECT name, type_desc FROM sys.indexes
WHERE object_id IN (OBJECT_ID('dbo.moviles'), OBJECT_ID('dbo.eas_estaciones'), OBJECT_ID('dbo.lugares_servicio'), OBJECT_ID('dbo.movil_eas_asignaciones'), OBJECT_ID('dbo.catalogo_detalles'))
AND is_primary_key = 0 AND is_unique_constraint = 0
ORDER BY OBJECT_NAME(object_id), name;

COMMIT TRANSACTION;
GO

PRINT 'Migracion completada.';
GO
