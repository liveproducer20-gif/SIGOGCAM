SET NOCOUNT ON;
USE [BITSAC];
GO

-- ROL 1: Administrador (3)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1804567890', 'carlos.mendoza@seguraep.gob.ec', 'Carlos', 'Mendoza Rivera', 1, 1, NULL, SYSDATETIME()),
('1804567891', 'maria.torres@seguraep.gob.ec', 'Maria', 'Torres Paz', 1, 1, NULL, SYSDATETIME()),
('1804567892', 'luis.herrera@seguraep.gob.ec', 'Luis', 'Herrera Campos', 1, 1, NULL, SYSDATETIME());
GO

-- ROL 2: Agente (4)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1712345678', 'diego.paredes@seguraep.gob.ec', 'Diego', 'Paredes Ortiz', 2, 1, NULL, SYSDATETIME()),
('1712345679', 'ana.suarez@seguraep.gob.ec', 'Ana', 'Suarez Lopez', 2, 1, NULL, SYSDATETIME()),
('1712345680', 'jose.ruiz@seguraep.gob.ec', 'Jose', 'Ruiz Mena', 2, 1, NULL, SYSDATETIME()),
('1712345681', 'lucia.vasquez@seguraep.gob.ec', 'Lucia', 'Vasquez Rea', 2, 1, NULL, SYSDATETIME());
GO

-- ROL 7: Operaciones (3)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1754321098', 'roberto.diaz@seguraep.gob.ec', 'Roberto', 'Diaz Salazar', 7, 1, NULL, SYSDATETIME()),
('1754321099', 'patricia.morales@seguraep.gob.ec', 'Patricia', 'Morales Vega', 7, 1, NULL, SYSDATETIME()),
('1754321100', 'andres.castillo@seguraep.gob.ec', 'Andres', 'Castillo Luna', 7, 1, NULL, SYSDATETIME());
GO

-- ROL 8: Supervisor (3)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1765432109', 'marcos.guerrero@seguraep.gob.ec', 'Marcos', 'Guerrero Pinto', 8, 1, NULL, SYSDATETIME()),
('1765432110', 'elena.rios@seguraep.gob.ec', 'Elena', 'Rios Cuesta', 8, 1, NULL, SYSDATETIME()),
('1765432111', 'fernando.vega@seguraep.gob.ec', 'Fernando', 'Vega Solorzano', 8, 1, NULL, SYSDATETIME());
GO

-- ROL 6: Inspector (3)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1776543210', 'gabriela.torres@seguraep.gob.ec', 'Gabriela', 'Torres Benitez', 6, 1, NULL, SYSDATETIME()),
('1776543211', 'rafael.castro@seguraep.gob.ec', 'Rafael', 'Castro Paredes', 6, 1, NULL, SYSDATETIME()),
('1776543212', 'sofia.mendez@seguraep.gob.ec', 'Sofia', 'Mendez Alvarado', 6, 1, NULL, SYSDATETIME());
GO

-- ROL 3: Auditoria (2)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1787654321', 'daniel.salazar@seguraep.gob.ec', 'Daniel', 'Salazar Montoya', 3, 1, NULL, SYSDATETIME()),
('1787654322', 'valeria.flores@seguraep.gob.ec', 'Valeria', 'Flores Apolo', 3, 1, NULL, SYSDATETIME());
GO

-- ROL 4: Comunicaciones (2)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1798765432', 'camila.vega@seguraep.gob.ec', 'Camila', 'Vega Cevallos', 4, 1, NULL, SYSDATETIME()),
('1798765433', 'oscar.reyes@seguraep.gob.ec', 'Oscar', 'Reyes Jaramillo', 4, 1, NULL, SYSDATETIME());
GO

-- ROL 10: Encargado (2)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1709876543', 'isabel.acosta@seguraep.gob.ec', 'Isabel', 'Acosta Narvaez', 10, 1, NULL, SYSDATETIME()),
('1709876544', 'hector.miranda@seguraep.gob.ec', 'Hector', 'Miranda Perez', 10, 1, NULL, SYSDATETIME());
GO

-- ROL 9: Auditor (1)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1710987654', 'teresa.aguirre@seguraep.gob.ec', 'Teresa', 'Aguirre Cordero', 9, 1, NULL, SYSDATETIME());
GO

-- ROL 12: Radioperador (1)
INSERT INTO dbo.personal (cedula, correo_institucional, nombres, apellidos, rol_id, activo, password_hash, fecha_creacion) VALUES
('1721098765', 'pablo.naranjo@seguraep.gob.ec', 'Pablo', 'Naranjo Delgado', 12, 1, NULL, SYSDATETIME());
GO

PRINT 'Usuarios creados.';
SELECT COUNT(*) AS total_usuarios FROM dbo.personal;
GO
