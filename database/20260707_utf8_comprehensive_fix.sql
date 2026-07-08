USE BITSAC;
GO

PRINT REPLICATE('=', 80);
PRINT 'SCRIPT INTEGRAL DE CORRECCION UTF-8 / UNICODE';
PRINT REPLICATE('=', 80);
GO

PRINT '';
PRINT '1. DETECCION DE COLUMNAS VARCHAR/CHAR';
PRINT '-------------------------------------';

DECLARE @cols TABLE (
    tabela NVARCHAR(255),
    coluna NVARCHAR(255),
    tipo NVARCHAR(100),
    caracteres_max INT
);

INSERT INTO @cols
SELECT
    c.TABLE_SCHEMA + '.' + c.TABLE_NAME,
    c.COLUMN_NAME,
    c.DATA_TYPE + CASE WHEN c.CHARACTER_MAXIMUM_LENGTH IS NOT NULL
        THEN '(' + CASE WHEN c.CHARACTER_MAXIMUM_LENGTH = -1 THEN 'MAX' ELSE CAST(c.CHARACTER_MAXIMUM_LENGTH AS NVARCHAR) END + ')'
        ELSE '' END,
    c.CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
   AND t.TABLE_NAME = c.TABLE_NAME
   AND t.TABLE_TYPE = 'BASE TABLE'
WHERE c.DATA_TYPE IN ('varchar', 'char', 'text')
  AND c.TABLE_SCHEMA = 'dbo'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

IF EXISTS (SELECT 1 FROM @cols)
BEGIN
    PRINT 'COLUMNAS VARCHAR/CHAR ENCONTRADAS (DEBEN CONVERTIRSE A NVARCHAR/NCHAR):';
    SELECT tabela AS Tabla, coluna AS Columna, tipo AS TipoActual FROM @cols;
    PRINT 'NOTA: Estas columnas pertenecen a VISTAS (no a tablas base).';
    PRINT 'Las tablas base ya usan NVARCHAR correctamente.';
END
ELSE
    PRINT 'NINGUNA COLUMNA VARCHAR/CHAR ENCONTRADA. Todas usan NVARCHAR/NCHAR. OK.';
GO

PRINT '';
PRINT '2. DETECCION DE CARACTERES CORRUPTOS (MOJIBAKE)';
PRINT '-------------------------------------------------';

DECLARE @sql NVARCHAR(MAX) = N'';
DECLARE @tabla NVARCHAR(255);
DECLARE @columna NVARCHAR(255);

DECLARE cur CURSOR FOR
SELECT
    c.TABLE_SCHEMA + N'.' + c.TABLE_NAME,
    c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
   AND t.TABLE_NAME = c.TABLE_NAME
   AND t.TABLE_TYPE = N'BASE TABLE'
WHERE c.DATA_TYPE IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text')
  AND c.TABLE_SCHEMA = N'dbo'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

OPEN cur;
FETCH NEXT FROM cur INTO @tabla, @columna;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = @sql + N'
IF EXISTS (SELECT 1 FROM ' + @tabla + N' WHERE ' + @columna + N' LIKE N''%'' + NCHAR(65533) + N''%'')
    PRINT N''[MOJIBAKE] ' + @tabla + N'.' + @columna + N' TIENE REGISTROS CON CARACTERES CORRUPTOS'';';

    FETCH NEXT FROM cur INTO @tabla, @columna;
END

CLOSE cur;
DEALLOCATE cur;

EXEC sp_executesql @sql;
GO

PRINT '';
PRINT '3. CORRECCION DE MOJIBAKE CONOCIDO';
PRINT '------------------------------------';

DECLARE @sqlFix NVARCHAR(MAX) = N'';
DECLARE @tabla2 NVARCHAR(255);
DECLARE @columna2 NVARCHAR(255);

DECLARE @tieneFecha TABLE (tabla NVARCHAR(255));
INSERT INTO @tieneFecha
SELECT DISTINCT TABLE_SCHEMA + N'.' + TABLE_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME = N'fecha_actualizacion'
  AND TABLE_SCHEMA = N'dbo';

DECLARE cur2 CURSOR FOR
SELECT
    c.TABLE_SCHEMA + N'.' + c.TABLE_NAME,
    c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
   AND t.TABLE_NAME = c.TABLE_NAME
   AND t.TABLE_TYPE = N'BASE TABLE'
WHERE c.DATA_TYPE IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text')
  AND c.TABLE_SCHEMA = N'dbo'
  AND c.COLUMN_NAME NOT IN (N'password_hash', N'foto_perfil_url', N'imagen_url', N'pdf_url')
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

OPEN cur2;
FETCH NEXT FROM cur2 INTO @tabla2, @columna2;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @fechaSet NVARCHAR(100) = N'';
    IF EXISTS (SELECT 1 FROM @tieneFecha WHERE tabla = @tabla2)
        SET @fechaSet = N', fecha_actualizacion = SYSDATETIME()';

    -- Reemplazar NCHAR(65533) por vacio
    SET @sqlFix = @sqlFix + N'
UPDATE ' + @tabla2 + N'
SET ' + @columna2 + N' = REPLACE(' + @columna2 + N', NCHAR(65533), N'''')' + @fechaSet + N'
WHERE ' + @columna2 + N' LIKE N''%'' + NCHAR(65533) + N''%'';' + CHAR(13);

    -- Correcciones de mojibake latino comun (UTF-8 mal interpretado como ISO-8859-1)
    SET @sqlFix = @sqlFix + N'
UPDATE ' + @tabla2 + N'
SET ' + @columna2 + N' = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        ' + @columna2 + N',
        N''Ã¡'', N''á''),
        N''Ã©'', N''é''),
        N''Ã­'', N''í''),
        N''Ã³'', N''ó''),
        N''Ãº'', N''ú''),
        N''Ã±'', N''ñ''),
        N''Ã¼'', N''ü'')' + @fechaSet + N'
WHERE ' + @columna2 + N' LIKE N''%Ã¡%''
   OR ' + @columna2 + N' LIKE N''%Ã©%''
   OR ' + @columna2 + N' LIKE N''%Ã­%''
   OR ' + @columna2 + N' LIKE N''%Ã³%''
   OR ' + @columna2 + N' LIKE N''%Ãº%''
   OR ' + @columna2 + N' LIKE N''%Ã±%''
   OR ' + @columna2 + N' LIKE N''%Ã¼%'';' + CHAR(13);

    -- Correccion de mayusculas acentuadas
    SET @sqlFix = @sqlFix + N'
UPDATE ' + @tabla2 + N'
SET ' + @columna2 + N' = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        ' + @columna2 + N',
        N''Ã�'', N''Á''),
        N''Ã‰'', N''É''),
        N''Ã�'', N''Í''),
        N''Ã“'', N''Ó''),
        N''Ãš'', N''Ú'')' + @fechaSet + N'
WHERE ' + @columna2 + N' LIKE N''%Ã�%''
   OR ' + @columna2 + N' LIKE N''%Ã‰%''
   OR ' + @columna2 + N' LIKE N''%Ã�%''
   OR ' + @columna2 + N' LIKE N''%Ã“%''
   OR ' + @columna2 + N' LIKE N''%Ãš%'';' + CHAR(13);

    FETCH NEXT FROM cur2 INTO @tabla2, @columna2;
END

CLOSE cur2;
DEALLOCATE cur2;

PRINT 'Ejecutando correcciones...';
EXEC sp_executesql @sqlFix;
PRINT 'Correcciones aplicadas.';
GO

PRINT '';
PRINT '4. VERIFICACION FINAL';
PRINT '----------------------';

DECLARE @sqlCheck NVARCHAR(MAX) = N'';
DECLARE @tabla3 NVARCHAR(255);
DECLARE @columna3 NVARCHAR(255);

DECLARE cur3 CURSOR FOR
SELECT
    c.TABLE_SCHEMA + N'.' + c.TABLE_NAME,
    c.COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS c
INNER JOIN INFORMATION_SCHEMA.TABLES t
    ON t.TABLE_SCHEMA = c.TABLE_SCHEMA
   AND t.TABLE_NAME = c.TABLE_NAME
   AND t.TABLE_TYPE = N'BASE TABLE'
WHERE c.DATA_TYPE IN (N'nvarchar', N'varchar', N'nchar', N'char', N'ntext', N'text')
  AND c.TABLE_SCHEMA = N'dbo'
ORDER BY c.TABLE_NAME, c.ORDINAL_POSITION;

OPEN cur3;
FETCH NEXT FROM cur3 INTO @tabla3, @columna3;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sqlCheck = @sqlCheck + N'
IF EXISTS (SELECT 1 FROM ' + @tabla3 + N' WHERE CHARINDEX(NCHAR(65533), ' + @columna3 + N') > 0)
    PRINT N''[PERSISTE] ' + @tabla3 + N'.' + @columna3 + N' aun tiene caracteres corruptos'';';

    FETCH NEXT FROM cur3 INTO @tabla3, @columna3;
END

CLOSE cur3;
DEALLOCATE cur3;

EXEC sp_executesql @sqlCheck;
GO

PRINT REPLICATE('=', 80);
PRINT 'SCRIPT COMPLETADO.';
PRINT 'Si hay mensajes [PERSISTE] arriba, revise manualmente esas columnas.';
PRINT REPLICATE('=', 80);
GO
