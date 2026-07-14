USE BITSAC;
GO

-- Corrige textos que fueron guardados como UTF-8 interpretado como Latin-1.
UPDATE dbo.modulos_sistema SET nombre = N'Administración' WHERE codigo = N'administracion';
UPDATE dbo.modulos_sistema SET nombre = N'Catálogos' WHERE codigo = N'catalogos';
UPDATE dbo.modulos_sistema SET nombre = N'Configuración' WHERE codigo = N'configuracion';
UPDATE dbo.modulos_sistema SET nombre = N'Estadísticas' WHERE codigo = N'estadisticas';
UPDATE dbo.modulos_sistema SET nombre = N'Móviles' WHERE codigo = N'moviles';

UPDATE dbo.campos_sistema SET nombre = N'Área' WHERE codigo = N'personal.area';
UPDATE dbo.campos_sistema SET nombre = N'Cédula' WHERE codigo = N'personal.cedula';
UPDATE dbo.campos_sistema SET nombre = N'Teléfono' WHERE codigo = N'personal.telefono';
GO
