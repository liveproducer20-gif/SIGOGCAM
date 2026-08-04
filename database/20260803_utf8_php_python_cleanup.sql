USE BITSAC;
GO

SET NOCOUNT ON;

DECLARE @updates TABLE (
    bad NVARCHAR(20) NOT NULL,
    good NVARCHAR(20) NOT NULL
);

INSERT INTO @updates (bad, good)
VALUES
    (N'Ã¡', N'á'),
    (N'Ã©', N'é'),
    (N'Ã­', N'í'),
    (N'Ã³', N'ó'),
    (N'Ãº', N'ú'),
    (N'Ã±', N'ñ'),
    (N'Ã¼', N'ü'),
    (N'Ã�', N'Á'),
    (N'Ã‰', N'É'),
    (N'Ã“', N'Ó'),
    (N'Ãš', N'Ú'),
    (N'Â¿', N'¿'),
    (N'Â¡', N'¡');

DECLARE @schema SYSNAME;
DECLARE @table SYSNAME;
DECLARE @column SYSNAME;
DECLARE @sql NVARCHAR(MAX);
DECLARE @set NVARCHAR(MAX);
DECLARE @where NVARCHAR(MAX);

DECLARE text_columns CURSOR LOCAL FAST_FORWARD FOR
SELECT s.name, t.name, c.name
FROM sys.columns c
INNER JOIN sys.tables t ON t.object_id = c.object_id
INNER JOIN sys.schemas s ON s.schema_id = t.schema_id
INNER JOIN sys.types ty ON ty.user_type_id = c.user_type_id
WHERE s.name = N'dbo'
  AND ty.name IN (N'nvarchar', N'varchar', N'nchar', N'char', N'text', N'ntext')
  AND t.is_ms_shipped = 0;

OPEN text_columns;
FETCH NEXT FROM text_columns INTO @schema, @table, @column;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @set = QUOTENAME(@column);
    SET @where = N'';

    SELECT
        @set = N'REPLACE(' + @set + N', N''' + REPLACE(bad, N'''', N'''''') + N''', N''' + REPLACE(good, N'''', N'''''') + N''')',
        @where = @where + CASE WHEN @where = N'' THEN N'' ELSE N' OR ' END
               + QUOTENAME(@column) + N' LIKE N''%' + REPLACE(bad, N'''', N'''''') + N'%'''
    FROM @updates;

    SET @sql = N'UPDATE ' + QUOTENAME(@schema) + N'.' + QUOTENAME(@table)
             + N' SET ' + QUOTENAME(@column) + N' = ' + @set
             + N' WHERE ' + @where + N';';

    EXEC sp_executesql @sql;

    FETCH NEXT FROM text_columns INTO @schema, @table, @column;
END;

CLOSE text_columns;
DEALLOCATE text_columns;

IF OBJECT_ID(N'dbo.alertas_soporte', N'U') IS NOT NULL
BEGIN
    IF EXISTS (
        SELECT 1
        FROM sys.check_constraints
        WHERE name = N'CK_alertas_prioridad'
          AND parent_object_id = OBJECT_ID(N'dbo.alertas_soporte')
    )
    BEGIN
        ALTER TABLE dbo.alertas_soporte DROP CONSTRAINT CK_alertas_prioridad;
    END;

    UPDATE dbo.alertas_soporte
    SET prioridad = N'Crítica'
    WHERE prioridad IN (N'CrÃ­tica', N'Critica');

    ALTER TABLE dbo.alertas_soporte
        ADD CONSTRAINT CK_alertas_prioridad
        CHECK (prioridad IN (N'Crítica', N'Alta', N'Media', N'Baja'));
END;
GO
