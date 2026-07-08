USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

DECLARE @permisoId INT;
SELECT @permisoId = id FROM dbo.permisos WHERE codigo = 'rutas.ver';

IF @permisoId IS NULL
BEGIN
    INSERT INTO dbo.permisos (codigo, descripcion, modulo) VALUES ('rutas.ver', 'Ver rutas', 'Administracion');
    SET @permisoId = SCOPE_IDENTITY();
    PRINT 'Permiso rutas.ver creado.';
END
ELSE
    PRINT 'Permiso rutas.ver ya existe.';

DECLARE @rolAdminId INT = (SELECT id FROM dbo.roles WHERE nombre = 'Administrador');
IF @rolAdminId IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM dbo.rol_permiso WHERE rol_id = @rolAdminId AND permiso_id = @permisoId
)
BEGIN
    INSERT INTO dbo.rol_permiso (rol_id, permiso_id) VALUES (@rolAdminId, @permisoId);
    PRINT 'Permiso asignado al rol Admin.';
END
ELSE
    PRINT 'Permiso ya asignado o rol Admin no encontrado.';

COMMIT TRANSACTION;
GO
