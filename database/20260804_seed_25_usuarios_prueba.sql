USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- ============================================================
-- LIMPIAR PERSONAL EXISTENTE
-- ============================================================
IF OBJECT_ID('dbo.usuario_insignias', 'U') IS NOT NULL DELETE FROM dbo.usuario_insignias;
IF OBJECT_ID('dbo.cartillas_generadas', 'U') IS NOT NULL DELETE FROM dbo.cartillas_generadas;
IF OBJECT_ID('dbo.cartilla_temp_cp', 'U') IS NOT NULL DELETE FROM dbo.cartilla_temp_cp;
IF OBJECT_ID('dbo.cartilla_temp_policia', 'U') IS NOT NULL DELETE FROM dbo.cartilla_temp_policia;
IF OBJECT_ID('dbo.evento_personal', 'U') IS NOT NULL DELETE FROM dbo.evento_personal;
IF OBJECT_ID('dbo.anuncio_personal', 'U') IS NOT NULL DELETE FROM dbo.anuncio_personal;
IF OBJECT_ID('dbo.asignaciones_punto', 'U') IS NOT NULL DELETE FROM dbo.asignaciones_punto;
IF OBJECT_ID('dbo.asignaciones_ruta', 'U') IS NOT NULL DELETE FROM dbo.asignaciones_ruta;
IF OBJECT_ID('dbo.auditoria', 'U') IS NOT NULL DELETE FROM dbo.auditoria;
IF OBJECT_ID('dbo.sorteos_historial', 'U') IS NOT NULL DELETE FROM dbo.sorteos_historial;
IF OBJECT_ID('dbo.eventos', 'U') IS NOT NULL DELETE FROM dbo.eventos;
IF OBJECT_ID('dbo.anuncios', 'U') IS NOT NULL DELETE FROM dbo.anuncios;
DELETE FROM dbo.personal;

-- ============================================================
-- OBTENER IDs REALES DE LA BASE
-- ============================================================
DECLARE @rolAdmin INT, @rolOper INT, @rolSup INT, @rolInsp INT;
DECLARE @rolAgente INT, @rolComunic INT, @rolAuditoria INT, @rolEncargado INT;
DECLARE @areaOperativa INT, @areaAdmin INT, @areaComunic INT;
DECLARE @jornadaDiurna INT, @jornadaNocturna INT, @jornadaRotativa INT;
DECLARE @grupoA INT, @grupoB INT;
DECLARE @estadoActivo INT, @estadoFranco INT, @estadoVacaciones INT;
DECLARE @estadoNoOp INT, @estadoPermiso INT, @estadoLicencia INT;
DECLARE @gradoAg1 INT, @gradoAg2 INT, @gradoAg3 INT, @gradoAg4 INT;
DECLARE @gradoSubInsp INT, @gradoInsp INT, @gradoJefe INT;
DECLARE @funcEncargado INT, @funcSupervision INT, @funcFila INT, @funcAdmin INT, @funcAux INT;
DECLARE @tipoRotFija INT, @tipoRotRotativa INT;

-- Roles
SELECT @rolAdmin = id FROM dbo.roles WHERE nombre = 'Administrador';
SELECT @rolOper = id FROM dbo.roles WHERE nombre = 'Operaciones';
SELECT @rolSup = id FROM dbo.roles WHERE nombre = 'Supervisor';
SELECT @rolInsp = id FROM dbo.roles WHERE nombre = 'Inspector';
SELECT @rolAgente = id FROM dbo.roles WHERE nombre = 'Agente';
SELECT @rolComunic = id FROM dbo.roles WHERE nombre = 'Comunicaciones';
SELECT @rolAuditoria = id FROM dbo.roles WHERE nombre = 'Auditoria';
SELECT @rolEncargado = id FROM dbo.roles WHERE nombre = 'Encargado';

-- Areas
SELECT @areaOperativa = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'OPERATIVA';
SELECT @areaAdmin = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'ADMINISTRACION';
SELECT @areaComunic = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'AREAS' AND d.codigo = 'COMUNICACIONES';

-- Jornadas
SELECT @jornadaDiurna = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'DIURNA';
SELECT @jornadaNocturna = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'NOCTURNA';
SELECT @jornadaRotativa = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'JORNADAS' AND d.codigo = 'ROTATIVA';

-- Grupos
SELECT @grupoA = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'GRUPOS' AND d.codigo = 'GRUPO_A';
SELECT @grupoB = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'GRUPOS' AND d.codigo = 'GRUPO_B';

-- Estados personal
SELECT @estadoActivo = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'ACTIVO';
SELECT @estadoFranco = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'FRANCO';
SELECT @estadoVacaciones = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'VACACIONES';
SELECT @estadoNoOp = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'SUSPENDIDO';
SELECT @estadoPermiso = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'PERMISO';
SELECT @estadoLicencia = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'ESTADOS_PERSONAL' AND d.codigo = 'REPOSO_MEDICO';

-- Grados
SELECT @gradoAg1 = id FROM dbo.grados WHERE nombre = N'Agente 1';
SELECT @gradoAg2 = id FROM dbo.grados WHERE nombre = N'Agente 2';
SELECT @gradoAg3 = id FROM dbo.grados WHERE nombre = N'Agente 3';
SELECT @gradoAg4 = id FROM dbo.grados WHERE nombre = N'Agente 4';
SELECT @gradoSubInsp = id FROM dbo.grados WHERE nombre = N'Sub-Inspector';
SELECT @gradoInsp = id FROM dbo.grados WHERE nombre = N'Inspector';
SELECT @gradoJefe = id FROM dbo.grados WHERE nombre = N'Jefe de Control Municipal';

-- Funciones operativas
SELECT @funcEncargado = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'ENCARGADO';
SELECT @funcSupervision = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'SUPERVISION';
SELECT @funcFila = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'FILA_PEDESTRE';
SELECT @funcAdmin = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'ADMINISTRATIVO';
SELECT @funcAux = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'FUNCIONES_OPERATIVAS' AND d.codigo = 'AUXILIAR';

-- Tipos rotacion
SELECT @tipoRotFija = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'TIPOS_ROTACION' AND d.codigo = 'FIJA';
SELECT @tipoRotRotativa = d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id = d.catalogo_id WHERE c.codigo = 'TIPOS_ROTACION' AND d.codigo = 'ROTATIVA';

-- Fallbacks
IF @areaOperativa IS NULL SET @areaOperativa = 1;
IF @areaAdmin IS NULL SET @areaAdmin = @areaOperativa;
IF @areaComunic IS NULL SET @areaComunic = @areaOperativa;
IF @jornadaDiurna IS NULL SET @jornadaDiurna = 1;
IF @jornadaNocturna IS NULL SET @jornadaNocturna = @jornadaDiurna;
IF @jornadaRotativa IS NULL SET @jornadaRotativa = @jornadaDiurna;
IF @grupoA IS NULL SET @grupoA = 1;
IF @grupoB IS NULL SET @grupoB = @grupoA;
IF @estadoActivo IS NULL SET @estadoActivo = 1;
IF @estadoFranco IS NULL SET @estadoFranco = @estadoActivo;
IF @estadoVacaciones IS NULL SET @estadoVacaciones = @estadoActivo;
IF @estadoNoOp IS NULL SET @estadoNoOp = @estadoActivo;
IF @estadoPermiso IS NULL SET @estadoPermiso = @estadoActivo;
IF @estadoLicencia IS NULL SET @estadoLicencia = @estadoActivo;
IF @gradoAg1 IS NULL SET @gradoAg1 = 1;
IF @gradoAg2 IS NULL SET @gradoAg2 = @gradoAg1;
IF @gradoAg3 IS NULL SET @gradoAg3 = @gradoAg1;
IF @gradoAg4 IS NULL SET @gradoAg4 = @gradoAg1;
IF @gradoSubInsp IS NULL SET @gradoSubInsp = @gradoAg1;
IF @gradoInsp IS NULL SET @gradoInsp = @gradoAg1;
IF @gradoJefe IS NULL SET @gradoJefe = @gradoAg1;
IF @funcEncargado IS NULL SET @funcEncargado = 1;
IF @funcSupervision IS NULL SET @funcSupervision = @funcEncargado;
IF @funcFila IS NULL SET @funcFila = @funcEncargado;
IF @funcAdmin IS NULL SET @funcAdmin = @funcEncargado;
IF @funcAux IS NULL SET @funcAux = @funcEncargado;
IF @tipoRotFija IS NULL SET @tipoRotFija = 1;
IF @tipoRotRotativa IS NULL SET @tipoRotRotativa = @tipoRotFija;

-- Usar roles fallback si faltan
IF @rolAdmin IS NULL SET @rolAdmin = 1;
IF @rolOper IS NULL SET @rolOper = @rolAdmin;
IF @rolSup IS NULL SET @rolSup = @rolAdmin;
IF @rolInsp IS NULL SET @rolInsp = @rolAdmin;
IF @rolAgente IS NULL SET @rolAgente = @rolAdmin;
IF @rolComunic IS NULL SET @rolComunic = @rolAdmin;
IF @rolAuditoria IS NULL SET @rolAuditoria = @rolAdmin;
IF @rolEncargado IS NULL SET @rolEncargado = @rolAdmin;

-- ============================================================
-- INSERTAR 25 USUARIOS
-- ============================================================
INSERT INTO dbo.personal (
    cedula, nombres, apellidos, correo_institucional, telefono,
    fecha_nacimiento, fecha_ingreso, cargo_id, area_id, jornada_id,
    grupo_id, rol_id, estado_personal_id, grado_id, funcion_operativa_id,
    tipo_rotacion_id, activo, fecha_creacion
)
VALUES
-- 1. Administrador (activo)
('0923456789', 'Carlos', 'Mendoza Rivera', 'cmendoza@bitsac.local', '0991234567',
 '1985-03-15', '2020-01-10', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAdmin, @estadoActivo, @gradoJefe, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 2. Administrador (activo)
('0923456790', 'Ana', 'Torres Vera', 'atorres@bitsac.local', '0991234568',
 '1988-07-22', '2021-03-15', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAdmin, @estadoActivo, @gradoSubInsp, @funcAdmin, @tipoRotFija, 1, GETDATE()),

-- 3. Operaciones (activo)
('0923456791', 'Luis', 'Garcia Lopez', 'lgarcia@bitsac.local', '0991234569',
 '1990-01-08', '2021-06-01', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolOper, @estadoActivo, @gradoSubInsp, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 4. Operaciones (activo)
('0923456792', 'Maria', 'Paredes Castillo', 'mparedes@bitsac.local', '0991234570',
 '1992-05-14', '2022-01-10', @funcAdmin, @areaOperativa, @jornadaDiurna,
 @grupoB, @rolOper, @estadoActivo, @gradoAg4, @funcSupervision, @tipoRotRotativa, 1, GETDATE()),

-- 5. Operaciones (activo)
('0923456793', 'Roberto', 'Jimenez Vera', 'rjimenez@bitsac.local', '0991234571',
 '1987-11-30', '2022-05-20', @funcEncargado, @areaOperativa, @jornadaNocturna,
 @grupoA, @rolOper, @estadoActivo, @gradoAg3, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 6. Supervisor (activo)
('0923456794', 'Pedro', 'Morales Diaz', 'pmorales@bitsac.local', '0991234572',
 '1986-09-12', '2021-08-15', @funcSupervision, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolSup, @estadoActivo, @gradoInsp, @funcSupervision, @tipoRotFija, 1, GETDATE()),

-- 7. Supervisor (activo)
('0923456795', 'Carmen', 'Salazar Rojas', 'csalazar@bitsac.local', '0991234573',
 '1991-02-28', '2022-03-01', @funcSupervision, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolSup, @estadoActivo, @gradoSubInsp, @funcSupervision, @tipoRotRotativa, 1, GETDATE()),

-- 8. Supervisor (FRANCO)
('0923456796', 'Diego', 'Herrera Mena', 'dherrera@bitsac.local', '0991234574',
 '1989-06-18', '2021-11-10', @funcSupervision, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolSup, @estadoFranco, @gradoSubInsp, @funcSupervision, @tipoRotFija, 1, GETDATE()),

-- 9. Inspector (activo)
('0923456797', 'Sofia', 'Vargas Ponce', 'svargas@bitsac.local', '0991234575',
 '1993-04-05', '2022-07-01', @funcSupervision, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolInsp, @estadoActivo, @gradoAg4, @funcSupervision, @tipoRotRotativa, 1, GETDATE()),

-- 10. Inspector (activo)
('0923456798', 'Andres', 'Chavez Lara', 'achavez@bitsac.local', '0991234576',
 '1988-12-20', '2022-09-15', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolInsp, @estadoActivo, @gradoAg3, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 11. Inspector (activo)
('0923456799', 'Valeria', 'Rios Delgado', 'vrios@bitsac.local', '0991234577',
 '1994-08-03', '2023-01-10', @funcSupervision, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolInsp, @estadoActivo, @gradoAg2, @funcSupervision, @tipoRotRotativa, 1, GETDATE()),

-- 12. Agente (activo)
('0923456800', 'Jorge', 'Calderon Aguirre', 'jcalderon@bitsac.local', '0991234578',
 '1995-01-25', '2023-02-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAg2, @funcFila, @tipoRotFija, 1, GETDATE()),

-- 13. Agente (activo)
('0923456801', 'Lopez', 'Mendoza Maria', 'lmendoza@bitsac.local', '0991234579',
 '1996-03-10', '2023-03-15', @funcFila, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolAgente, @estadoActivo, @gradoAg1, @funcFila, @tipoRotRotativa, 1, GETDATE()),

-- 14. Agente (activo)
('0923456802', 'Paredes', 'Ramirez Luis', 'lparedes@bitsac.local', '0991234580',
 '1991-07-14', '2023-04-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAg1, @funcFila, @tipoRotFija, 1, GETDATE()),

-- 15. Agente (activo)
('0923456803', 'Elena', 'Torres Guevara', 'etorres@bitsac.local', '0991234581',
 '1993-10-22', '2023-05-10', @funcAux, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolAgente, @estadoActivo, @gradoAg2, @funcAux, @tipoRotRotativa, 1, GETDATE()),

-- 16. Agente (activo)
('0923456804', 'Miguel', 'Reyes Cevallos', 'mreyes@bitsac.local', '0991234582',
 '1990-05-30', '2023-06-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoActivo, @gradoAg3, @funcFila, @tipoRotFija, 1, GETDATE()),

-- 17. Agente (FRANCO)
('0923456805', 'Gabriela', 'Flores Jaramillo', 'gflores@bitsac.local', '0991234583',
 '1994-12-08', '2023-07-15', @funcFila, @areaOperativa, @jornadaNocturna,
 @grupoB, @rolAgente, @estadoFranco, @gradoAg1, @funcFila, @tipoRotRotativa, 1, GETDATE()),

-- 18. Agente (VACACIONES)
('0923456806', 'Fernando', 'Bustamante Leon', 'fbustamante@bitsac.local', '0991234584',
 '1989-09-17', '2023-08-01', @funcFila, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolAgente, @estadoVacaciones, @gradoAg2, @funcFila, @tipoRotFija, 1, GETDATE()),

-- 19. Agente (SUSPENDIDO = no operativo)
('0923456807', 'Patricia', 'Sandoval Mejia', 'psandoval@bitsac.local', '0991234585',
 '1992-04-25', '2023-09-10', @funcFila, @areaOperativa, @jornadaRotativa,
 @grupoB, @rolAgente, @estadoNoOp, @gradoAg1, @funcFila, @tipoRotRotativa, 1, GETDATE()),

-- 20. Comunicaciones (activo)
('0923456808', 'Ricardo', 'Ponce Ortiz', 'rponce@bitsac.local', '0991234586',
 '1987-02-14', '2022-04-01', @funcAdmin, @areaComunic, @jornadaDiurna,
 @grupoA, @rolComunic, @estadoActivo, @gradoAg3, @funcAdmin, @tipoRotFija, 1, GETDATE()),

-- 21. Comunicaciones (activo)
('0923456809', 'Claudia', 'Espinoza Vega', 'cespinoza@bitsac.local', '0991234587',
 '1991-08-09', '2022-08-15', @funcAdmin, @areaComunic, @jornadaDiurna,
 @grupoB, @rolComunic, @estadoActivo, @gradoAg2, @funcAdmin, @tipoRotFija, 1, GETDATE()),

-- 22. Encargado (activo)
('0923456810', 'Teresa', 'Guerrero Paz', 'tguerrero@bitsac.local', '0991234588',
 '1990-11-03', '2022-10-01', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoA, @rolEncargado, @estadoActivo, @gradoAg2, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 23. Encargado (PERMISO)
('0923456811', 'Hector', 'Cruz Viteri', 'hcruz@bitsac.local', '0991234589',
 '1986-06-21', '2022-11-15', @funcEncargado, @areaOperativa, @jornadaDiurna,
 @grupoB, @rolEncargado, @estadoPermiso, @gradoAg1, @funcEncargado, @tipoRotFija, 1, GETDATE()),

-- 24. Auditoria (activo)
('0923456812', 'Nancy', 'Moreira Cevallos', 'nmoreira@bitsac.local', '0991234590',
 '1989-03-28', '2023-01-05', @funcAdmin, @areaAdmin, @jornadaDiurna,
 @grupoA, @rolAuditoria, @estadoActivo, @gradoSubInsp, @funcAdmin, @tipoRotFija, 1, GETDATE()),

-- 25. Auditoria (REPOSO MEDICO = licencia)
('0923456813', 'Oscar', 'Medina Acosta', 'omedina@bitsac.local', '0991234591',
 '1993-07-16', '2023-02-20', @funcAdmin, @areaAdmin, @jornadaRotativa,
 @grupoB, @rolAuditoria, @estadoLicencia, @gradoAg3, @funcAdmin, @tipoRotRotativa, 1, GETDATE());

-- Limpiar passwords
IF COL_LENGTH('dbo.personal', 'password_hash') IS NOT NULL
    UPDATE dbo.personal SET password_hash = NULL;

COMMIT TRANSACTION;
GO

-- ============================================================
-- VERIFICACION
-- ============================================================
SELECT
    r.nombre AS rol,
    COUNT(*) AS total,
    SUM(CASE WHEN ep.codigo = 'ACTIVO' THEN 1 ELSE 0 END) AS activos,
    SUM(CASE WHEN ep.codigo NOT IN ('ACTIVO','INACTIVO') THEN 1 ELSE 0 END) AS otros_estados
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
GROUP BY r.nombre
ORDER BY r.nombre;

SELECT
    p.cedula,
    LTRIM(RTRIM(p.nombres + ' ' + p.apellidos)) AS nombre_completo,
    r.nombre AS rol,
    ISNULL(ep.nombre,'?') AS estado,
    ISNULL(g.nombre,'-') AS grado
FROM dbo.personal p
INNER JOIN dbo.roles r ON r.id = p.rol_id
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
LEFT JOIN dbo.grados g ON g.id = p.grado_id
ORDER BY r.nombre, p.apellidos;
GO
