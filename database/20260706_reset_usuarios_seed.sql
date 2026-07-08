USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.personal', 'U') IS NULL
BEGIN
    THROW 50100, 'No existe dbo.personal. Verifique la base de datos BITSAC.', 1;
END;

IF OBJECT_ID('dbo.roles', 'U') IS NULL
BEGIN
    THROW 50101, 'No existe dbo.roles. Ejecute primero database/20260705_rbac_auditoria_seed.sql.', 1;
END;

IF OBJECT_ID('dbo.evento_personal', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.evento_personal;
END;

IF OBJECT_ID('dbo.anuncio_personal', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.anuncio_personal;
END;

IF OBJECT_ID('dbo.auditoria', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.auditoria;
END;

IF OBJECT_ID('dbo.eventos', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.eventos;
END;

IF OBJECT_ID('dbo.anuncios', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.anuncios;
END;

-- Limpiar tablas hijas que referencian a personal antes del DELETE.
IF OBJECT_ID('dbo.cartilla_temp_policia', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.cartilla_temp_policia;
END;

IF OBJECT_ID('dbo.cartilla_temp_cp', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.cartilla_temp_cp;
END;

IF OBJECT_ID('dbo.cartillas_generadas', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.cartillas_generadas;
END;

IF OBJECT_ID('dbo.usuario_insignias', 'U') IS NOT NULL
BEGIN
    DELETE FROM dbo.usuario_insignias;
END;

DELETE FROM dbo.personal;

DECLARE @cargoId INT;
DECLARE @areaId INT;
DECLARE @jornadaId INT;
DECLARE @grupoId INT;
DECLARE @estadoPersonalId INT;

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

IF @cargoId IS NULL OR @areaId IS NULL OR @jornadaId IS NULL OR @grupoId IS NULL OR @estadoPersonalId IS NULL
BEGIN
    THROW 50102, 'Faltan catalogos base: CARGOS, AREAS, JORNADAS, GRUPOS o ESTADOS_PERSONAL.', 1;
END;

DECLARE @usuarios TABLE (
    cedula NVARCHAR(20) NOT NULL,
    nombres NVARCHAR(120) NOT NULL,
    apellidos NVARCHAR(120) NOT NULL,
    correo NVARCHAR(160) NOT NULL,
    rol NVARCHAR(80) NOT NULL
);

DECLARE @semillas TABLE (
    rol NVARCHAR(80) NOT NULL,
    nombreBase NVARCHAR(120) NOT NULL,
    prefijoCorreo NVARCHAR(80) NOT NULL,
    cedulaBase BIGINT NOT NULL,
    cantidad INT NOT NULL
);

INSERT INTO @semillas (rol, nombreBase, prefijoCorreo, cedulaBase, cantidad)
VALUES
('Administrador', 'Administrador', 'admin', 910000000, 2),
('Operaciones', 'Operaciones', 'operaciones', 910000100, 8),
('Supervisor', 'Supervisor', 'supervisor', 910000200, 8),
('Inspector', 'Inspector', 'inspector', 910000300, 8),
('Agente', 'Agente', 'agente', 910000400, 8),
('Comunicaciones', 'Comunicaciones', 'comunicaciones', 910000500, 8),
('Consulta', 'Consulta', 'consulta', 910000600, 8),
('Auditoria', 'Auditoria', 'auditoria', 910000700, 8);

DECLARE
    @rol NVARCHAR(80),
    @nombreBase NVARCHAR(120),
    @prefijoCorreo NVARCHAR(80),
    @cedulaBase BIGINT,
    @cantidad INT,
    @i INT;

DECLARE seed_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT rol, nombreBase, prefijoCorreo, cedulaBase, cantidad
    FROM @semillas
    ORDER BY cedulaBase;

OPEN seed_cursor;
FETCH NEXT FROM seed_cursor INTO @rol, @nombreBase, @prefijoCorreo, @cedulaBase, @cantidad;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @i = 1;

    WHILE @i <= @cantidad
    BEGIN
        INSERT INTO @usuarios (cedula, nombres, apellidos, correo, rol)
        VALUES (
            RIGHT('0000000000' + CONVERT(NVARCHAR(20), @cedulaBase + @i), 10),
            @nombreBase,
            RIGHT('00' + CONVERT(NVARCHAR(2), @i), 2),
            @prefijoCorreo + CONVERT(NVARCHAR(2), @i) + '@bitsac.local',
            @rol
        );

        SET @i += 1;
    END;

    FETCH NEXT FROM seed_cursor INTO @rol, @nombreBase, @prefijoCorreo, @cedulaBase, @cantidad;
END;

CLOSE seed_cursor;
DEALLOCATE seed_cursor;

IF EXISTS (
    SELECT 1
    FROM @usuarios u
    LEFT JOIN dbo.roles r ON r.nombre = u.rol
    WHERE r.id IS NULL
)
BEGIN
    THROW 50103, 'Falta uno o mas roles requeridos. Ejecute primero el seed RBAC.', 1;
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
SELECT
    u.cedula,
    u.nombres,
    u.apellidos,
    u.correo,
    '0999999999',
    '1990-01-01',
    CAST(GETDATE() AS DATE),
    @cargoId,
    @areaId,
    @jornadaId,
    @grupoId,
    r.id,
    @estadoPersonalId,
    GETDATE()
FROM @usuarios u
INNER JOIN dbo.roles r ON r.nombre = u.rol;

IF COL_LENGTH('dbo.personal', 'password_hash') IS NOT NULL
BEGIN
    UPDATE dbo.personal SET password_hash = NULL;
END;

COMMIT TRANSACTION;

SELECT
    r.nombre AS rol,
    COUNT(*) AS total_usuarios
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
GROUP BY r.nombre
ORDER BY r.nombre;

SELECT
    correo_institucional AS usuario,
    cedula AS contrasena,
    r.nombre AS rol
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
ORDER BY r.nombre, p.correo_institucional;
GO
