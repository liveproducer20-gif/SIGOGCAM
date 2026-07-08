USE BITSAC;
GO

-- Eliminar duplicados solo si la tabla existe
IF OBJECT_ID(N'dbo.eas_direcciones', N'U') IS NOT NULL
BEGIN
    DELETE d
    FROM dbo.eas_direcciones d
    INNER JOIN (
        SELECT eas_id, direccion, MIN(id) AS min_id
        FROM dbo.eas_direcciones
        WHERE activo = 1
        GROUP BY eas_id, direccion
        HAVING COUNT(*) > 1
    ) dupe ON d.eas_id = dupe.eas_id AND d.direccion = dupe.direccion
    WHERE d.id > dupe.min_id;
    PRINT 'Duplicados eliminados de eas_direcciones.';
END
GO

IF OBJECT_ID(N'dbo.servidores_policiales', N'U') IS NOT NULL
BEGIN
    DELETE d
    FROM dbo.servidores_policiales d
    INNER JOIN (
        SELECT eas_id, nombre, MIN(id) AS min_id
        FROM dbo.servidores_policiales
        WHERE activo = 1
        GROUP BY eas_id, nombre
        HAVING COUNT(*) > 1
    ) dupe ON d.eas_id = dupe.eas_id AND d.nombre = dupe.nombre
    WHERE d.id > dupe.min_id;
    PRINT 'Duplicados eliminados de servidores_policiales.';
END
GO

PRINT 'Cleanup finalizado.';
GO
