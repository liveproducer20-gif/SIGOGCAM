SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_ID(N'$(DatabaseName)') IS NULL
BEGIN
    PRINT N'Restaurando $(DatabaseName) desde $(BackupPath)...';

    RESTORE DATABASE [$(DatabaseName)]
    FROM DISK = N'$(BackupPath)'
    WITH
        MOVE N'BITSAC' TO N'/var/opt/mssql/data/BITSAC.mdf',
        MOVE N'BITSAC_log' TO N'/var/opt/mssql/data/BITSAC_log.ldf',
        RECOVERY,
        CHECKSUM,
        STATS = 5;
END
ELSE
BEGIN
    PRINT N'La base $(DatabaseName) ya existe; no se vuelve a restaurar.';
END;
GO

DBCC CHECKDB ([$(DatabaseName)]) WITH NO_INFOMSGS;
GO
