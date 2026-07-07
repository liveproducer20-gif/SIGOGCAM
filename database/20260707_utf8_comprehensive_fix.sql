USE BITSAC;
GO

PRINT REPLICATE('=', 80);
PRINT 'SCRIPT INTEGRAL DE CORRECCION UTF-8 / UNICODE';
PRINT REPLICATE('=', 80);
GO

PRINT '
1. DETECCION DE COLUMNAS VARCHAR/CHAR
-------------------------------------';

DECLARE @cols TABLE (
    tabela NVARCHAR(255),
    coluna NVARCHAR(255),
    tipo NVARCHAR(100),
    caracteres_max INT
);

INSERT INTO @cols
SELECT
    TABLE_SCHEMA + '.' + TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE + CASE WHEN CHARACTER_MAXIMUM_LENGTH IS NOT NULL
        THEN '(' + CASE WHEN CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END + ')'
        ELSE '' END,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('varchar', 'char', 'text')
  AND TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

IF EXISTS (SELECT 1 FROM @cols)
BEGIN
    PRINT 'COLUMNAS VARCHAR/CHAR ENCONTRADAS (DEBEN CONVERTIRSE A NVARCHAR/NCHAR):';
    SELECT tabela AS Tabla, coluna AS Columna, tipo AS TipoActual FROM @cols;
    PRINT 'ADVERTENCIA: Estas columnas no almacenan Unicode correctamente.';
    PRINT 'Ejecute ALTER TABLE para convertirlas a NVARCHAR.';
END
ELSE
    PRINT 'NINGUNA COLUMNA VARCHAR/CHAR ENCONTRADA. Todas usan NVARCHAR/NCHAR. OK.';
GO

PRINT '
2. DETECCION DE CARACTERES CORRUPTOS (MOJIBAKE)
-------------------------------------------------';

-- Buscar caracter de reemplazo Unicode (�) en todas las columnas de tipo texto
DECLARE @sql NVARCHAR(MAX) = '';
DECLARE @tabla NVARCHAR(255);
DECLARE @columna NVARCHAR(255);

DECLARE cur CURSOR FOR
SELECT
    TABLE_SCHEMA + '.' + TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

OPEN cur;
FETCH NEXT FROM cur INTO @tabla, @columna;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + '
IF EXISTS (SELECT 1 FROM ' + @tabla + ' WHERE ' + @columna + ' LIKE ''%'' + NCHAR(65533) + ''%'')
    PRINT ''''> ' + @tabla + '.' + @columna + ' TIENE REGISTROS CON CARACTERES CORRUPTOS (�)'';';

    FETCH NEXT FROM cur INTO @tabla, @columna;
END

CLOSE cur;
DEALLOCATE cur;

EXEC sp_executesql @sql;
GO

PRINT '
3. CORRECCION DE MOJIBAKE CONOCIDO
------------------------------------';

-- � -> '' (reemplazo por vacio cuando no se puede determinar el caracter original)
DECLARE @sqlFix NVARCHAR(MAX) = '';
DECLARE @tabla2 NVARCHAR(255);
DECLARE @columna2 NVARCHAR(255);

DECLARE cur2 CURSOR FOR
SELECT
    TABLE_SCHEMA + '.' + TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND TABLE_SCHEMA = 'dbo'
  AND COLUMN_NAME NOT IN ('password_hash', 'foto_perfil_url', 'imagen_url', 'pdf_url')
ORDER BY TABLE_NAME, ORDINAL_POSITION;

OPEN cur2;
FETCH NEXT FROM cur2 INTO @tabla2, @columna2;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Reemplazar NCHAR(65533) por vacio
    SET @sqlFix = @sqlFix + '
UPDATE ' + @tabla2 + '
SET ' + @columna2 + ' = REPLACE(' + @columna2 + ', NCHAR(65533), N''''),
    fecha_actualizacion = SYSDATETIME()
WHERE ' + @columna2 + ' LIKE ''%'' + NCHAR(65533) + ''%'';' + CHAR(13);

    -- Correcciones de mojibake latino comun (UTF-8 mal interpretado como ISO-8859-1)
    SET @sqlFix = @sqlFix + '
UPDATE ' + @tabla2 + '
SET ' + @columna2 + ' = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        ' + @columna2 + ',
        N''Ã¡'', N''á''),
        N''Ã©'', N''é''),
        N''Ã­'', N''í''),
        N''Ã³'', N''ó''),
        N''Ãº'', N''ú''),
        N''Ã±'', N''ñ''),
        N''Ã¼'', N''ü''),
    fecha_actualizacion = SYSDATETIME()
WHERE ' + @columna2 + ' LIKE N''%Ã¡%''
   OR ' + @columna2 + ' LIKE N''%Ã©%''
   OR ' + @columna2 + ' LIKE N''%Ã­%''
   OR ' + @columna2 + ' LIKE N''%Ã³%''
   OR ' + @columna2 + ' LIKE N''%Ãº%''
   OR ' + @columna2 + ' LIKE N''%Ã±%''
   OR ' + @columna2 + ' LIKE N''%Ã¼%'';' + CHAR(13);

    -- Correccion de mayusculas acentuadas
    SET @sqlFix = @sqlFix + '
UPDATE ' + @tabla2 + '
SET ' + @columna2 + ' = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        ' + @columna2 + ',
        N''Ã�'', N''Á''),
        N''Ã‰'', N''É''),
        N''Ã�'', N''Í''),
        N''Ã“'', N''Ó''),
        N''Ãš'', N''Ú''),
    fecha_actualizacion = SYSDATETIME()
WHERE ' + @columna2 + ' LIKE N''%Ã�%''
   OR ' + @columna2 + ' LIKE N''%Ã‰%''
   OR ' + @columna2 + ' LIKE N''%Ã�%''
   OR ' + @columna2 + ' LIKE N''%Ã“%''
   OR ' + @columna2 + ' LIKE N''%Ãš%'';' + CHAR(13);

    FETCH NEXT FROM cur2 INTO @tabla2, @columna2;
END

CLOSE cur2;
DEALLOCATE cur2;

PRINT 'Ejecutando correcciones...';
EXEC sp_executesql @sqlFix;
PRINT 'Correcciones aplicadas.';
GO

PRINT '
4. VERIFICACION FINAL
----------------------';

DECLARE @sqlCheck NVARCHAR(MAX) = '';
DECLARE @tabla3 NVARCHAR(255);
DECLARE @columna3 NVARCHAR(255);

DECLARE cur3 CURSOR FOR
SELECT
    TABLE_SCHEMA + '.' + TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE DATA_TYPE IN ('nvarchar', 'varchar', 'nchar', 'char', 'ntext', 'text')
  AND TABLE_SCHEMA = 'dbo'
ORDER BY TABLE_NAME, ORDINAL_POSITION;

OPEN cur3;
FETCH NEXT FROM cur3 INTO @tabla3, @columna3;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sqlCheck = @sqlCheck + '
IF EXISTS (SELECT 1 FROM ' + @tabla3 + ' WHERE ' + @columna3 + ' LIKE ''%'' + NCHAR(65533) + ''%'')
    PRINT ''AUN PERSISTE: ' + @tabla3 + '.' + @columna3 + ' tiene �'';';

    FETCH NEXT FROM cur3 INTO @tabla3, @columna3;
END

CLOSE cur3;
DEALLOCATE cur3;

EXEC sp_executesql @sqlCheck;
GO

PRINT REPLICATE('=', 80);
PRINT 'SCRIPT COMPLETADO.';
PRINT 'Si hay mensajes "AUN PERSISTE" arriba, revise manualmente esas columnas.';
PRINT REPLICATE('=', 80);
GO
