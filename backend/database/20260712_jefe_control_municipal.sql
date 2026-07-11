-- Agregar Jefe de Control Municipal al catálogo CARGOS
MERGE dbo.catalogo_detalles AS target
USING (
    SELECT c.id AS catalogo_id
    FROM dbo.catalogos c
    WHERE c.codigo = 'CARGOS'
) AS src ON target.catalogo_id = src.catalogo_id AND target.codigo = 'JEFE_CONTROL_MUNICIPAL'
WHEN NOT MATCHED THEN
    INSERT (catalogo_id, codigo, nombre, orden)
    VALUES (src.catalogo_id, 'JEFE_CONTROL_MUNICIPAL', N'Jefe de Control Municipal', 35);
GO
