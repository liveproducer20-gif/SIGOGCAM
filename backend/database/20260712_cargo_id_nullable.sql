-- Hacer cargo_id nullable: se llena solo si el formulario envía cargoId explícitamente
-- grado_id ya es la referencia al grado/denominación
ALTER TABLE dbo.personal ALTER COLUMN cargo_id INT NULL;
