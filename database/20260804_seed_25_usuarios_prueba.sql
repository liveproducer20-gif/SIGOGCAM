USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- ============================================================
-- 1. AGREGAR ESTADOS DE PERSONALES ADICIONALES
-- ============================================================
DECLARE @estadosCatalogId INT;
SELECT @estadosCatalogId = id FROM dbo.catalogos WHERE codigo = 'ESTADOS_PERSONAL';

IF @estadosCatalogId IS NOT NULL
BEGIN
    MERGE dbo.catalogo_detalles AS target
    USING (VALUES
        ('FRANCO',          N'Franco',          15),
        ('VACACIONES',      N'Vacaciones',      25),
        ('NO_OPERATIVO',    N'No Operativo',    30),
        ('LICENCIA_MEDICA', N'Licencia Medica', 35),
        ('PERMISO',         N'Permiso',         40),
        ('SANCIONADO',      N'Sancionado',      45)
    ) AS source(codigo, nombre, orden)
    ON target.catalogo_id = @estadosCatalogId AND target.codigo = source.codigo
    WHEN MATCHED THEN UPDATE SET nombre = source.nombre, orden = source.orden, estado = 1
    WHEN NOT MATCHED THEN INSERT (catalogo_id, codigo, nombre, orden, estado)
        VALUES (@estadosCatalogId, source.codigo, source.nombre, source.orden, 1);
END;

-- ============================================================
-- 2. AGREGAR CARGOS ADICIONALES SI NO EXISTEN
-- ============================================================
DECLARE @cargosCatalogId INT;
SELECT @cargosCatalogId = id FROM dbo.catalogos WHERE codigo = 'CARGOS';

IF @cargosCatalogId IS NULL
BEGIN
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion, estado)
    VALUES ('CARGOS', N'Cargos', N'Cargos institucionales', 1);
    SET @cargosCatalogId = SCOPE_IDENTITY();
END;

MERGE dbo.catalogo_detalles AS target
USING (VALUES
    ('AGENTE_SEGURIDAD',     N'Agente de Seguridad',      10),
    ('SUPERVISOR_SEGURIDAD', N'Supervisor de Seguridad',   20),
    ('ENCARGADO_TURNO',      N'Encargado de Turno',        30),
    ('RADIOPERADOR',         N'Radioperador',              40),
    ('INSPECTOR_OPERATIVO',  N'Inspector Operativo',       50),
    ('COORDINADOR',          N'Coordinador',               60),
    ('ANALISTA',             N'Analista',                  70),
    ('ASISTENTE_ADMIN',      N'Asistente Administrativo',  80)
) AS source(codigo, nombre, orden)
ON target.catalogo_id = @cargosCatalogId AND target.codigo = source.codigo
WHEN MATCHED THEN UPDATE SET nombre = source.nombre, orden = source.orden, estado = 1
WHEN NOT MATCHED THEN INSERT (catalogo_id, codigo, nombre, orden, estado)
    VALUES (@cargosCatalogId, source.codigo, source.nombre, source.orden, 1);

-- ============================================================
-- 3. ELIMINAR PERSONAL EXISTENTE Y RELACIONES
-- ============================================================
IF OBJECT_ID('dbo.evento_personal', 'U') IS NOT NULL
    DELETE FROM dbo.evento_personal;
IF OBJECT_ID('dbo.anuncio_personal', 'U') IS NOT NULL
    DELETE FROM dbo.anuncio_personal;
IF OBJECT_ID('dbo.asignaciones_punto', 'U') IS NOT NULL
    DELETE FROM dbo.asignaciones_punto;
IF OBJECT_ID('dbo.asignaciones_ruta', 'U') IS NOT NULL
    DELETE FROM dbo.asignaciones_ruta;
IF OBJECT_ID('dbo.auditoria', 'U') IS NOT NULL
    DELETE FROM dbo.auditoria;
IF OBJECT_ID('dbo.eventos', 'U') IS NOT NULL
    DELETE FROM dbo.eventos;
IF OBJECT_ID('dbo.anuncios', 'U') IS NOT NULL
    DELETE FROM dbo.anuncios;

DELETE FROM dbo.personal;

-- ============================================================
-- 4. OBTENER IDs DE CATALOGOS
-- ============================================================
DECLARE @areaOperativa INT, @areaAdmin INT, @areaComunic INT;
DECLARE @jornadaDiurna INT, @jornadaNocturna INT, @jornadaRotativa INT;
DECLARE @grupoA INT, @grupoB INT;
DECLARE @estadoActivo INT, @estadoInactivo INT, @estadoFranco INT;
DECLARE @estadoVacaciones INT, @estadoNoOp INT, @estadoLicencia INT, @estadoPermiso INT;
DECLARE @gradoAgente1 INT, @gradoAgente2 INT, @gradoAgente3 INT, @gradoAgente4 INT;
DECLARE @gradoSubInsp INT, @gradoInsp INT, @gradoJefe INT;
DECLARE @funcEncargado INT, @funcSupervision INT, @funcFila INT, @funcAdmin INT, @funcAux INT;
DECLARE @tipoRotFija INT, @tipoRotRotativa INT;

SELECT @areaOperativa = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'OPERATIVA';
SELECT @areaAdmin = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'ADMINISTRATIVA';
SELECT @areaComunic = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'COMUNICACIONES';

SELECT @jornadaDiurna = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'DIURNA';
SELECT @jornadaNocturna = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'NOCTURNA';
SELECT @jornadaRotativa = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'ROTATIVA';

SELECT @grupoA = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'GRUPOS' AND d.codigo = 'GRUPO_A';
SELECT @grupoB = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'GRUPOS' AND d.codigo = 'GRUPO_B';

SELECT @estadoActivo = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'ACTIVO';
SELECT @estadoInactivo = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'INACTIVO';
SELECT @estadoFranco = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'FRANCO';
SELECT @estadoVacaciones = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'VACACIONES';
SELECT @estadoNoOp = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'NO_OPERATIVO';
SELECT @estadoLicencia = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'LICENCIA_MEDICA';
SELECT @estadoPermiso = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'PERMISO';

SELECT @gradoAgente1 = id FROM dbo.grados WHERE nombre = N'Agente 1';
SELECT @gradoAgente2 = id FROM dbo.grados WHERE nombre = N'Agente 2';
SELECT @gradoAgente3 = id FROM dbo.grados WHERE nombre = N'Agente 3';
SELECT @gradoAgente4 = id FROM dbo.grados WHERE nombre = N'Agente 4';
SELECT @gradoSubInsp = id FROM dbo.grados WHERE nombre = N'Sub-Inspector';
SELECT @gradoInsp = id FROM dbo.grados WHERE nombre = N'Inspector';
SELECT @gradoJefe = id FROM dbo.grados WHERE nombre = N'Jefe de Control Municipal';

SELECT @funcEncargado = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'ENCARGADO';
SELECT @funcSupervision = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'SUPERVISION';
SELECT @funcFila = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'FILA_PEDESTRE';
SELECT @funcAdmin = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'ADMINISTRATIVO';
SELECT @funcAux = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'AUXILIAR';

SELECT @tipoRotFija = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'TIPOS_ROTACION' AND d.codigo = 'FIJA';
SELECT @tipoRotRotativa = d.id FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'TIPOS_ROTACION' AND d.codigo = 'ROTATIVA';

-- Validar IDs criticos
IF @estadoActivo IS NULL SET @estadoActivo = 1;
IF @areaOperativa IS NULL SET @areaOperativa = 1;
IF @jornadaDiurna IS NULL SET @jornadaDiurna = 1;
IF @grupoA IS NULL SET @grupoA = 1;
IF @gradoAgente1 IS NULL SET @gradoAgente1 = 1;
IF @estadoFranco IS NULL SET @estadoFranco = @estadoActivo;
IF @estadoVacaciones IS NULL SET @estadoVacaciones = @estadoActivo;
IF @estadoNoOp IS NULL SET @estadoNoOp = @estadoActivo;
IF @estadoLicencia IS NULL SET @estadoLicencia = @estadoActivo;
IF @estadoPermiso IS NULL SET @estadoPermiso = @estadoActivo;
IF @gradoAgente2 IS NULL SET @gradoAgente2 = @gradoAgente1;
IF @gradoAgente3 IS NULL SET @gradoAgente3 = @gradoAgente1;
IF @gradoAgente4 IS NULL SET @gradoAgente4 = @gradoAgente1;
IF @gradoSubInsp IS NULL SET @gradoSubInsp = @gradoAgente1;
IF @gradoInsp IS NULL SET @gradoInsp = @gradoAgente1;
IF @gradoJefe IS NULL SET @gradoJefe = @gradoAgente1;
IF @funcFila IS NULL SET @funcFila = 1;
IF @funcEncargado IS NULL SET @funcEncargado = @funcFila;
IF @funcSupervision IS NULL SET @funcSupervision = @funcFila;
IF @funcAdmin IS NULL SET @funcAdmin = @funcFila;
IF @funcAux IS NULL SET @funcAux = @funcFila;
IF @tipoRotFija IS NULL SET @tipoRotFija = 1;
IF @tipoRotRotativa IS NULL SET @tipoRotRotativa = 1;

-- ============================================================
-- 5. CREAR 25 USUARIOS DE PRUEBA
-- ============================================================
-- Distribucion de roles:
--   2 Administradores (1 activo, 1 activo)
--   3 Operaciones (3 activos)
--   3 Supervisores (2 activos, 1 franco)
--   3 Inspectores (3 activos)
--   8 Agentes (5 activos, 1 franco, 1 vacaciones, 1 no operativo)
--   2 Comunicaciones (2 activos)
--   2 Consulta (1 activo, 1 permiso)
--   2 Auditoria (1 activo, 1 licencia medica)
-- Total: 19 activos + 6 no activos = 25

DECLARE @rolAdmin INT, @rolOper INT, @rolSup INT, @rolInsp INT;
DECLARE @rolAgente INT, @rolComunic INT, @rolConsulta INT, @rolAuditoria INT;

SELECT @rolAdmin = id FROM dbo.roles WHERE nombre = 'Administrador';
SELECT @rolOper = id FROM dbo.roles WHERE nombre = 'Operaciones';
SELECT @rolSup = id FROM dbo.roles WHERE nombre = 'Supervisor';
SELECT @rolInsp = id FROM dbo.roles WHERE nombre = 'Inspector';
SELECT @rolAgente = id FROM dbo.roles WHERE nombre = 'Agente';
SELECT @rolComunic = id FROM dbo.roles WHERE nombre = 'Comunicaciones';
SELECT @rolConsulta = id FROM dbo.roles WHERE nombre = 'Consulta';
SELECT @rolAuditoria = id FROM dbo.roles WHERE nombre = 'Auditoria';

-- Si falta alguno, usar el primero disponible
IF @rolAdmin IS NULL SELECT TOP 1 @rolAdmin = id FROM dbo.roles;
IF @rolOper IS NULL SET @rolOper = @rolAdmin;
IF @rolSup IS NULL SET @rolSup = @rolAdmin;
IF @rolInsp IS NULL SET @rolInsp = @rolAdmin;
IF @rolAgente IS NULL SET @rolAgente = @rolAdmin;
IF @rolComunic IS NULL SET @rolComunic = @rolAdmin;
IF @rolConsulta IS NULL SET @rolConsulta = @rolAdmin;
IF @rolAuditoria IS NULL SET @rolAuditoria = @rolAdmin;

INSERT INTO dbo.personal (
    cedula, nombres, apellidos, correo_institucional, telefono,
    fecha_nacimiento, fecha_ingreso, cargo_id, area_id, jornada_id,
    grupo_id, rol_id, estado_personal_id, grado_id, funcion_operativa_id,
    tipo_rotacion_id, activo, fecha_creacion
)
VALUES
-- 1. Administrador Principal (activo)
('0923456789', 'Carlos', 'Mendoza Rivera', 'cmendoza@bitsac.local', '0991234567',
 '1985-03-15', '2020-01-10', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAdmin, @estadoActivo, @gradoJefe, @funcEncargado,
 @tipoRotFija, 1, GETDATE()),

-- 2. Administrador Secundario (activo)
('0923456790', 'Ana', 'Torres Vera', 'atorres@bitsac.local', '0991234568',
 '1988-07-22', '2021-03-15', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAdmin, @estadoActivo, @gradoSubInsp, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 3. Operaciones 1 (activo)
('0923456791', 'Luis', 'Garcia Lopez', 'lgarcia@bitsac.local', '0991234569',
 '1990-01-08', '2021-06-01', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolOper, @estadoActivo, @gradoSubInsp, @funcEncargado,
 @tipoRotFija, 1, GETDATE()),

-- 4. Operaciones 2 (activo)
('0923456792', 'Maria', 'Paredes Castillo', 'mparedes@bitsac.local', '0991234570',
 '1992-05-14', '2022-01-10', @funcAdmin, @areaOperativa, @jornadaDiurna,
 @grupoB, @rolOper, @estadoActivo, @gradoAgente4, @funcSupervision,
 @tipoRotRotativa, 1, GETDATE()),

-- 5. Operaciones 3 (activo)
('0923456793', 'Roberto', 'Jimenez Vera', 'rjimenez@bitsac.local', '0991234571',
 '1987-11-30', '2022-05-20', @funcEncargado, @areaOperativa, @jornadaNocturna,
 @grupoA, @rolOper, @estadoActivo, @gradoAgente3, @funcEncargado,
 @tipoRotFija, 1, GETDATE()),

-- 6. Supervisor 1 (activo)
('0923456794', 'Pedro', 'Morales Diaz', 'pmorales@bitsac.local', '0991234572',
 '1986-09-12', '2021-08-15', @funcSupervision, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolSup, @estadoActivo, @gradoInsp, @funcSupervision,
 @tipoRotFija, 1, GETDATE()),

-- 7. Supervisor 2 (activo)
('0923456795', 'Carmen', 'Salazar Rojas', 'csalazar@bitsac.local', '0991234573',
 '1991-02-28', '2022-03-01', @funcSupervision, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolSup, @estadoActivo, @gradoSubInsp, @funcSupervision,
 @tipoRotRotativa, 1, GETDATE()),

-- 8. Supervisor 3 (FRANCO)
('0923456796', 'Diego', 'Herrera Mena', 'dherrera@bitsac.local', '0991234574',
 '1989-06-18', '2021-11-10', @funcSupervision, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolSup, @estadoFranco, @gradoSubInsp, @funcSupervision,
 @tipoRotFija, 1, GETDATE()),

-- 9. Inspector 1 (activo)
('0923456797', 'Sofia', 'Vargas Ponce', 'svargas@bitsac.local', '0991234575',
 '1993-04-05', '2022-07-01', @funcSupervision, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolInsp, @estadoActivo, @gradoAgente4, @funcSupervision,
 @tipoRotRotativa, 1, GETDATE()),

-- 10. Inspector 2 (activo)
('0923456798', 'Andres', 'Chavez Lara', 'achavez@bitsac.local', '0991234576',
 '1988-12-20', '2022-09-15', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolInsp, @estadoActivo, @gradoAgente3, @funcEncargado,
 @tipoRotFija, 1, GETDATE()),

-- 11. Inspector 3 (activo)
('0923456799', 'Valeria', 'Rios Delgado', 'vrios@bitsac.local', '0991234577',
 '1994-08-03', '2023-01-10', @funcSupervision, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolInsp, @estadoActivo, @gradoAgente2, @funcSupervision,
 @tipoRotRotativa, 1, GETDATE()),

-- 12. Agente 1 (activo)
('0923456800', 'Jorge', 'Calderon Aguirre', 'jcalderon@bitsac.local', '0991234578',
 '1995-01-25', '2023-02-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAgente2, @funcFila,
 @tipoRotFija, 1, GETDATE()),

-- 13. Agente 2 (activo)
('0923456801', 'Lopez', 'Mendoza Maria', 'lmendoza@bitsac.local', '0991234579',
 '1996-03-10', '2023-03-15', @funcFila, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolAgente, @estadoActivo, @gradoAgente1, @funcFila,
 @tipoRotRotativa, 1, GETDATE()),

-- 14. Agente 3 (activo)
('0923456802', 'Paredes', 'Ramirez Luis', 'lparedes@bitsac.local', '0991234580',
 '1991-07-14', '2023-04-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAgente1, @funcFila,
 @tipoRotFija, 1, GETDATE()),

-- 15. Agente 4 (activo)
('0923456803', 'Elena', 'Torres Guevara', 'etorres@bitsac.local', '0991234581',
 '1993-10-22', '2023-05-10', @funcAux, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolAgente, @estadoActivo, @gradoAgente2, @funcAux,
 @tipoRotRotativa, 1, GETDATE()),

-- 16. Agente 5 (activo)
('0923456804', 'Miguel', 'Reyes Cevallos', 'mreyes@bitsac.local', '0991234582',
 '1990-05-30', '2023-06-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAgente3, @funcFila,
 @tipoRotFija, 1, GETDATE()),

-- 17. Agente 6 (FRANCO)
('0923456805', 'Gabriela', 'Flores Jaramillo', 'gflores@bitsac.local', '0991234583',
 '1994-12-08', '2023-07-15', @funcFila, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolAgente, @estadoFranco, @gradoAgente1, @funcFila,
 @tipoRotRotativa, 1, GETDATE()),

-- 18. Agente 7 (VACACIONES)
('0923456806', 'Fernando', 'Bustamante Leon', 'fbustamante@bitsac.local', '0991234584',
 '1989-09-17', '2023-08-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoVacaciones, @gradoAgente2, @funcFila,
 @tipoRotFija, 1, GETDATE()),

-- 19. Agente 8 (NO OPERATIVO)
('0923456807', 'Patricia', 'Sandoval Mejia', 'psandoval@bitsac.local', '0991234585',
 '1992-04-25', '2023-09-10', @funcFila, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolAgente, @estadoNoOp, @gradoAgente1, @funcFila,
 @tipoRotRotativa, 1, GETDATE()),

-- 20. Comunicaciones 1 (activo)
('0923456808', 'Ricardo', 'Ponce Ortiz', 'rponce@bitsac.local', '0991234586',
 '1987-02-14', '2022-04-01', @funcAdmin, @areaComunic, @jornadaDiurna,
 @grupoA, @rolComunic, @estadoActivo, @gradoAgente3, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 21. Comunicaciones 2 (activo)
('0923456809', 'Claudia', 'Espinoza Vega', 'cespinoza@bitsac.local', '0991234587',
 '1991-08-09', '2022-08-15', @funcAdmin, @areaComunic, @jornadaDiurna,
 @grupoB, @rolComunic, @estadoActivo, @gradoAgente2, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 22. Consulta 1 (activo)
('0923456810', 'Teresa', 'Guerrero Paz', 'tguerrero@bitsac.local', '0991234588',
 '1990-11-03', '2022-10-01', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolConsulta, @estadoActivo, @gradoAgente2, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 23. Consulta 2 (PERMISO)
('0923456811', 'Hector', 'Cruz Viteri', 'hcruz@bitsac.local', '0991234589',
 '1986-06-21', '2022-11-15', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoB, @rolConsulta, @estadoPermiso, @gradoAgente1, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 24. Auditoria 1 (activo)
('0923456812', 'Nancy', 'Moreira Cevallos', 'nmoreira@bitsac.local', '0991234590',
 '1989-03-28', '2023-01-05', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAuditoria, @estadoActivo, @gradoSubInsp, @funcAdmin,
 @tipoRotFija, 1, GETDATE()),

-- 25. Auditoria 2 (LICENCIA MEDICA)
('0923456813', 'Oscar', 'Medina Acosta', 'omedina@bitsac.local', '0991234591',
 '1993-07-16', '2023-02-20', @funcAdmin, @areaAdmin, @jornadaRotativa,
 @grupoB, @rolAuditoria, @estadoLicencia, @gradoAgente3, @funcAdmin,
 @tipoRotRotativa, 1, GETDATE());

-- ============================================================
-- 6. LIMPIAR PASSWORD_HASH
-- ============================================================
IF COL_LENGTH('dbo.personal', 'password_hash') IS NOT NULL
BEGIN
    UPDATE dbo.personal SET password_hash = NULL;
END;

COMMIT TRANSACTION;
GO

-- ============================================================
-- 7. VERIFICACION
-- ============================================================
PRINT '=== RESUMEN DE USUARIOS CREADOS ===';

SELECT
    r.nombre AS rol,
    COUNT(*) AS total,
    SUM(CASE WHEN ep.codigo = 'ACTIVO' THEN 1 ELSE 0 END) AS activos,
    SUM(CASE WHEN ep.codigo IN ('FRANCO','VACACIONES','NO_OPERATIVO','LICENCIA_MEDICA','PERMISO','SANCIONADO') THEN 1 ELSE 0 END) AS no_activos
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
GROUP BY r.nombre
ORDER BY r.nombre;

PRINT '';
PRINT '=== LISTADO COMPLETO ===';

SELECT
    p.id,
    p.cedula,
    LTRIM(RTRIM(p.nombres + ' ' + p.apellidos)) AS nombre_completo,
    p.correo_institucional,
    r.nombre AS rol,
    ep.nombre AS estado,
    g.nombre AS grado,
    fo.nombre AS funcion,
    a.nombre AS area,
    j.nombre AS jornada,
    gr.nombre AS grupo
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
LEFT JOIN dbo.grados g ON g.id = p.grado_id
LEFT JOIN dbo.catalogo_detalles fo ON fo.id = p.funcion_operativa_id
LEFT JOIN dbo.catalogo_detalles a ON a.id = p.area_id
LEFT JOIN dbo.catalogo_detalles j ON j.id = p.jornada_id
LEFT JOIN dbo.catalogo_detalles gr ON gr.id = p.grupo_id
ORDER BY r.nombre, p.apellidos, p.nombres;

PRINT '';
PRINT '=== CREDENCIALES DE ACCESO (cedula = contrasena) ===';

SELECT
    p.cedula AS usuario,
    p.cedula AS contrasena,
    r.nombre AS rol,
    ep.nombre AS estado
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
ORDER BY r.nombre, p.cedula;
GO
