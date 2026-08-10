-- Migration: Add forced assignment support columns
-- Date: 2026-08-09

-- Add columns to track forced assignments
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.asignaciones_ruta') AND name = 'asignacion_forzada')
BEGIN
    ALTER TABLE dbo.asignaciones_ruta ADD asignacion_forzada BIT DEFAULT 0;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.asignaciones_ruta') AND name = 'motivo_forzado')
BEGIN
    ALTER TABLE dbo.asignaciones_ruta ADD motivo_forzado NVARCHAR(500) NULL;
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.asignaciones_ruta') AND name = 'estado_original_agente')
BEGIN
    ALTER TABLE dbo.asignaciones_ruta ADD estado_original_agente NVARCHAR(80) NULL;
END
GO

-- Create permission for forced assignment
IF NOT EXISTS (SELECT 1 FROM dbo.permisos WHERE codigo = 'distribucion.forzar_asignacion')
BEGIN
    INSERT INTO dbo.permisos (codigo, descripcion, modulo, recurso, accion, activo)
    VALUES ('distribucion.forzar_asignacion', 'Permite forzar asignacion de personal en estado no disponible', 'distribucion', 'asignacion', 'forzar', 1);

    -- Grant to ADMINISTRADOR role
    DECLARE @permisoId INT = SCOPE_IDENTITY();
    DECLARE @adminRoleId INT;
    SELECT @adminRoleId = id FROM dbo.roles WHERE codigo = 'ADMINISTRADOR';
    IF @adminRoleId IS NOT NULL
    BEGIN
        INSERT INTO dbo.rol_permiso (rol_id, permiso_id, permitido, heredado)
        VALUES (@adminRoleId, @permisoId, 1, 0);
    END
END
GO
