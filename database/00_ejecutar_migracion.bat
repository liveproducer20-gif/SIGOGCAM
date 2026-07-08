@ECHO OFF
REM ============================================================================
REM  MIGRACION BITSAC - Ejecutor por lotes (sqlcmd, Windows Auth)
REM  Las rutas con espacios se manejan entre comillas.
REM ============================================================================

SET "SERVER=LAPTOP-JC\SQLEXPRESS"
SET "DB=BITSAC"
SET "SCRIPT_DIR=%~dp0"

REM Crear la base de datos si no existe
sqlcmd -E -S "%SERVER%" -Q "IF DB_ID('%DB%') IS NULL CREATE DATABASE [%DB%];"
IF ERRORLEVEL 1 (
    ECHO ERROR: No se pudo conectar a %SERVER% o crear la base %DB%.
    PAUSE
    EXIT /B 1
)

ECHO ============================================================
ECHO  MIGRACION BITSAC -^> %SERVER%\%DB%
ECHO ============================================================

FOR %%F IN (
    20260705_eventos_publicacion_media.sql
    20260705_perfil_usuario.sql
    20260705_rbac_auditoria_seed.sql
    20260706_anuncios_eas.sql
    20260706_insignias_cartillas.sql
    20260706_personal_password_hash.sql
    20260706_reset_usuarios_seed.sql
    20260707_administracion_modulo.sql
    20260707_comprehensive_fix.sql
    20260707_fix_catalogos_y_tildes.sql
    20260707_fix_estados_movil.sql
    20260707_fix_utf8_catalogos_eventos.sql
    20260707_load_moviles.sql
    20260707_reset_admin_only.sql
    20260707_utf8_comprehensive_fix.sql
    20260708_cleanup_duplicates.sql
    20260708_fix_admin_schemas.sql
    20260708_fix_desalojo_tables.sql
    20260709_lugares_servicio_rutas.sql
    20260709_rutas_tabla_propia.sql
    20260710_grados_tabla_propia.sql
    20260710_indices_fk.sql
    20260710_permiso_rutas.sql
) DO (
    IF NOT EXIST "%SCRIPT_DIR%%%F" (
        ECHO ****** NO SE ENCONTRO: %%F ******
        PAUSE
        EXIT /B 1
    )
    ECHO ------------------------------------------------------------
    ECHO  ^>^> %%F
    ECHO ------------------------------------------------------------
    sqlcmd -E -S "%SERVER%" -d "%DB%" -i "%SCRIPT_DIR%%%F" -b -I
    IF ERRORLEVEL 1 (
        ECHO.
        ECHO ****** FALLO en %%F. Migracion detenida. ******
        PAUSE
        EXIT /B 1
    )
)

ECHO.
ECHO ============================================================
ECHO  MIGRACION COMPLETADA CORRECTAMENTE.
ECHO ============================================================
PAUSE
