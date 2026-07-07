USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.personal', 'U') IS NULL
BEGIN
    THROW 50300, 'No existe dbo.personal. Verifique la base de datos BITSAC.', 1;
END;

IF OBJECT_ID('dbo.roles', 'U') IS NULL
BEGIN
    THROW 50301, 'No existe dbo.roles. Ejecute primero el seed RBAC.', 1;
END;

IF NOT EXISTS (SELECT 1 FROM dbo.roles WHERE nombre = 'Administrador')
BEGIN
    THROW 50302, 'No existe el rol Administrador.', 1;
END;

IF OBJECT_ID('dbo.evento_personal', 'U') IS NOT NULL
    DELETE FROM dbo.evento_personal;

IF OBJECT_ID('dbo.anuncio_personal', 'U') IS NOT NULL
    DELETE FROM dbo.anuncio_personal;

IF OBJECT_ID('dbo.usuario_insignias', 'U') IS NOT NULL
    DELETE FROM dbo.usuario_insignias;

IF OBJECT_ID('dbo.cartillas_generadas', 'U') IS NOT NULL
    DELETE FROM dbo.cartillas_generadas;

IF OBJECT_ID('dbo.auditoria', 'U') IS NOT NULL
    DELETE FROM dbo.auditoria;

IF OBJECT_ID('dbo.eventos', 'U') IS NOT NULL
    DELETE FROM dbo.eventos;

IF OBJECT_ID('dbo.anuncios', 'U') IS NOT NULL
    DELETE FROM dbo.anuncios;

DELETE FROM dbo.personal;

DECLARE @cargoId INT;
DECLARE @areaId INT;
DECLARE @jornadaId INT;
DECLARE @grupoId INT;
DECLARE @estadoPersonalId INT;
DECLARE @rolId INT;

SELECT TOP 1 @cargoId = d.id
FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'CARGOS' AND d.estado = 1
ORDER BY d.id;

SELECT TOP 1 @areaId = d.id
FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'AREAS' AND d.estado = 1
ORDER BY d.id;

SELECT TOP 1 @jornadaId = d.id
FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'JORNADAS' AND d.estado = 1
ORDER BY d.id;

SELECT TOP 1 @grupoId = d.id
FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'GRUPOS' AND d.estado = 1
ORDER BY d.id;

SELECT TOP 1 @estadoPersonalId = d.id
FROM dbo.catalogo_detalles d
INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
WHERE c.codigo = 'ESTADOS_PERSONAL'
  AND d.estado = 1
  AND (
      UPPER(d.codigo) IN ('ACTIVO', 'DISPONIBLE')
      OR UPPER(d.nombre) IN ('ACTIVO', 'DISPONIBLE')
  )
ORDER BY d.id;

IF @estadoPersonalId IS NULL
BEGIN
    SELECT TOP 1 @estadoPersonalId = d.id
    FROM dbo.catalogo_detalles d
    INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
    WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.estado = 1
    ORDER BY d.id;
END;

SELECT TOP 1 @rolId = id
FROM dbo.roles
WHERE nombre = 'Administrador';

IF @cargoId IS NULL OR @areaId IS NULL OR @jornadaId IS NULL OR @grupoId IS NULL OR @estadoPersonalId IS NULL OR @rolId IS NULL
BEGIN
    THROW 50303, 'Faltan catalogos base o rol Administrador.', 1;
END;

INSERT INTO dbo.personal (
    cedula,
    nombres,
    apellidos,
    correo_institucional,
    telefono,
    fecha_nacimiento,
    fecha_ingreso,
    cargo_id,
    area_id,
    jornada_id,
    grupo_id,
    rol_id,
    estado_personal_id,
    fecha_creacion
)
VALUES (
    '0910000001',
    'Administrador',
    'Principal',
    'admin@bitsac.local',
    '0999999999',
    '1990-01-01',
    CAST(GETDATE() AS DATE),
    @cargoId,
    @areaId,
    @jornadaId,
    @grupoId,
    @rolId,
    @estadoPersonalId,
    GETDATE()
);

IF COL_LENGTH('dbo.personal', 'password_hash') IS NOT NULL
BEGIN
    UPDATE dbo.personal SET password_hash = NULL;
END;

IF COL_LENGTH('dbo.personal', 'total_cartillas_generadas') IS NOT NULL
BEGIN
    UPDATE dbo.personal SET total_cartillas_generadas = 0;
END;

COMMIT TRANSACTION;

SELECT
    p.id,
    p.correo_institucional AS usuario,
    p.cedula AS contrasena,
    r.nombre AS rol
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
ORDER BY p.id;
GO
