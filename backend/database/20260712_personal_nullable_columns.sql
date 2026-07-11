-- Migración: Hacer opcionales columnas de personal que ahora son configurables desde admin
-- Motivo: El formulario de creación de personal en administración permite dejar
--         área, rol y estado como opcionales (sin seleccionar).

ALTER TABLE dbo.personal ALTER COLUMN area_id int NULL;
GO

ALTER TABLE dbo.personal ALTER COLUMN estado_personal_id int NULL;
GO

ALTER TABLE dbo.personal ALTER COLUMN rol_id int NULL;
GO

PRINT 'Columnas area_id, estado_personal_id, rol_id modificadas a NULL correctamente.';
GO
