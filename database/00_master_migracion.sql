/*
============================================================================
  SCRIPT MAESTRO - BITSAC (Base de datos SQL Server)
  Ejecuta todos los scripts de migracion en orden cronologico.
----------------------------------------------------------------------------
  INSTRUCCIONES:
  - Ejecutar con sqlcmd o en SSMS activando "SQLCMD Mode" (Query -> SQLCMD Mode).
  - Asegurarse de estar conectado a la base BITSAC (o crearla antes).
  - ON_ERROR_STOP hace que el proceso se detenga si un script falla.
============================================================================
*/

:setvar BITSACDB "BITSAC"
:on error exit

PRINT '============================================================';
PRINT 'INICIANDO MIGRACION BITSAC - ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '============================================================';

-- 20260705 --------------------------------------------------------------
PRINT '>> 20260705_eventos_publicacion_media.sql';
:r "20260705_eventos_publicacion_media.sql"

PRINT '>> 20260705_perfil_usuario.sql';
:r "20260705_perfil_usuario.sql"

PRINT '>> 20260705_rbac_auditoria_seed.sql';
:r "20260705_rbac_auditoria_seed.sql"

-- 20260706 --------------------------------------------------------------
PRINT '>> 20260706_anuncios_eas.sql';
:r "20260706_anuncios_eas.sql"

PRINT '>> 20260706_insignias_cartillas.sql';
:r "20260706_insignias_cartillas.sql"

PRINT '>> 20260706_personal_password_hash.sql';
:r "20260706_personal_password_hash.sql"

PRINT '>> 20260706_reset_usuarios_seed.sql';
:r "20260706_reset_usuarios_seed.sql"

-- 20260707 --------------------------------------------------------------
PRINT '>> 20260707_administracion_modulo.sql';
:r "20260707_administracion_modulo.sql"

PRINT '>> 20260707_comprehensive_fix.sql';
:r "20260707_comprehensive_fix.sql"

PRINT '>> 20260707_fix_catalogos_y_tildes.sql';
:r "20260707_fix_catalogos_y_tildes.sql"

PRINT '>> 20260707_fix_estados_movil.sql';
:r "20260707_fix_estados_movil.sql"

PRINT '>> 20260707_fix_utf8_catalogos_eventos.sql';
:r "20260707_fix_utf8_catalogos_eventos.sql"

PRINT '>> 20260707_load_moviles.sql';
:r "20260707_load_moviles.sql"

PRINT '>> 20260707_reset_admin_only.sql';
:r "20260707_reset_admin_only.sql"

PRINT '>> 20260707_utf8_comprehensive_fix.sql';
:r "20260707_utf8_comprehensive_fix.sql"

-- 20260708 --------------------------------------------------------------
PRINT '>> 20260708_cleanup_duplicates.sql';
:r "20260708_cleanup_duplicates.sql"

PRINT '>> 20260708_fix_admin_schemas.sql';
:r "20260708_fix_admin_schemas.sql"

PRINT '>> 20260708_fix_desalojo_tables.sql';
:r "20260708_fix_desalojo_tables.sql"

-- 20260709 --------------------------------------------------------------
PRINT '>> 20260709_lugares_servicio_rutas.sql';
:r "20260709_lugares_servicio_rutas.sql"

PRINT '>> 20260709_rutas_tabla_propia.sql';
:r "20260709_rutas_tabla_propia.sql"

-- 20260710 --------------------------------------------------------------
PRINT '>> 20260710_grados_tabla_propia.sql';
:r "20260710_grados_tabla_propia.sql"

PRINT '>> 20260710_indices_fk.sql';
:r "20260710_indices_fk.sql"

PRINT '>> 20260710_permiso_rutas.sql';
:r "20260710_permiso_rutas.sql"

PRINT '============================================================';
PRINT 'MIGRACION COMPLETADA - ' + CONVERT(NVARCHAR, GETDATE(), 120);
PRINT '============================================================';
GO
