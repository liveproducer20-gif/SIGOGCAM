USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== 1/4: CREANDO dbo.grados ===';

IF OBJECT_ID('dbo.grados', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.grados (
        id INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(160) NOT NULL,
        activo BIT NOT NULL CONSTRAINT DF_grados_activo DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_grados_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL
    );
    PRINT '  Tabla dbo.grados creada.';
END
ELSE
    PRINT '  dbo.grados ya existe.';
GO

PRINT '=== 2/4: MIGRANDO DATOS DESDE catalogo_detalles ===';

DECLARE @gradoCatalogoId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'GRADOS');

SET IDENTITY_INSERT dbo.grados ON;

INSERT INTO dbo.grados (id, nombre, activo, fecha_creacion, fecha_actualizacion)
SELECT d.id, d.nombre, d.estado, d.fecha_creacion, d.fecha_actualizacion
FROM dbo.catalogo_detalles d
WHERE d.catalogo_id = @gradoCatalogoId
  AND NOT EXISTS (SELECT 1 FROM dbo.grados g WHERE g.id = d.id);

SET IDENTITY_INSERT dbo.grados OFF;

PRINT '  Datos migrados a dbo.grados.';
GO

PRINT '=== 3/4: ELIMINANDO GRADOS DE catalogo_detalles ===';

DECLARE @gradoCatalogoId INT = (SELECT id FROM dbo.catalogos WHERE codigo = 'GRADOS');

DELETE FROM dbo.catalogo_detalles WHERE catalogo_id = @gradoCatalogoId;
PRINT '  Detalles de GRADOS eliminados de catalogo_detalles.';

DELETE FROM dbo.catalogos WHERE codigo = 'GRADOS';
PRINT '  Catalogo GRADOS eliminado de catalogos.';
GO

PRINT '=== 4/4: VERIFICACION ===';

SELECT COUNT(*) AS grados_en_tabla FROM dbo.grados;
SELECT COUNT(*) AS grados_en_catalogo FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'GRADOS';
GO

COMMIT TRANSACTION;
GO

PRINT 'Migracion completada.';
GO
