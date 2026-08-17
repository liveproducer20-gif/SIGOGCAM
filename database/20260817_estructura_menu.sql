-- ============================================================================
-- 20260817_estructura_menu.sql
-- Reestructura el menú dinámico (mi-menu / build_tree) para que coincida con
-- el diseño del sidebar:
--
--   1. Corrige dbo.modulos_sistema: rutas reales de la app, iconos con los
--      glifos del sidebar, orden global, y desactiva módulos sin página
--      (servicios, operaciones, reportes, estadisticas).
--   2. Inserta los módulos que faltaban (distribucion y sus vistas, panel de
--      asistencia, eventos, anuncios, perfil, mantenimiento).
--   3. Reconstruye dbo.rol_menu_configuracion desde los PERMISOS del rol:
--      cada rol ve exactamente lo que su permiso habilita, agrupado igual que
--      el sidebar (grupos Administración, Distribución y Eventos y anuncios
--      con sus hijos; los módulos sueltos como hojas).
--
-- La reconstrucción es determinista: re-ejecutarla devuelve el mismo estado
-- (la configuración manual previa era plana, con rutas/iconos incorrectos).
-- Tras esta migración, el Constructor visual de menú sigue funcionando para
-- renombrar/ocultar/reordenar por rol.
--
-- Idempotente: todos los UPDATE/INSERT usan WHERE/IF NOT EXISTS.
-- ============================================================================

PRINT '=== 1/4 Corrigiendo dbo.modulos_sistema ===';
-- Iconos con NCHAR(punto de código): SQL puro ASCII para evitar que el
-- driver ODBC convierta los glifos segun la pagina de codigos del cliente.
UPDATE dbo.modulos_sistema SET ruta='/dashboard',            icono=NCHAR(0x25A3), orden_global=0  WHERE codigo='dashboard';      -- ▣
UPDATE dbo.modulos_sistema SET ruta='/eventos',              icono=NCHAR(0x25A7), orden_global=1  WHERE codigo='eventos_anuncios'; -- ▧
UPDATE dbo.modulos_sistema SET ruta='/cartillas',            icono=NCHAR(0x25A4), orden_global=2  WHERE codigo='cartillas';      -- ▤
UPDATE dbo.modulos_sistema SET ruta='/insignias',            icono=NCHAR(0x265C), orden_global=3  WHERE codigo='insignias';      -- ♜
UPDATE dbo.modulos_sistema SET ruta='/soporte',              icono=NCHAR(0x2667), orden_global=5  WHERE codigo='soporte';        -- ♧
UPDATE dbo.modulos_sistema SET ruta='/personal',             icono=NCHAR(0x2659), orden_global=10 WHERE codigo='personal';       -- ♙
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=catalogos',  icono=NCHAR(0x25A4), orden_global=11 WHERE codigo='catalogos';      -- ▤
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=lugares',    icono=NCHAR(0x2316), orden_global=12 WHERE codigo='lugares_servicio'; -- ⌖
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=rutas',      icono=NCHAR(0x219D), orden_global=13 WHERE codigo='rutas';          -- ↝
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=circuitos',  icono=NCHAR(0x232C), orden_global=14 WHERE codigo='circuitos';      -- ⌬
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=grados',     icono=NCHAR(0x2605), orden_global=15 WHERE codigo='grados';         -- ★
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=eas',        icono=NCHAR(0x2302), orden_global=16 WHERE codigo='eas';            -- ⌂
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=moviles',    icono=NCHAR(0x25A3), orden_global=17 WHERE codigo='moviles';        -- ▣
UPDATE dbo.modulos_sistema SET ruta='/admin?tab=asignaciones', icono=NCHAR(0x21C4), orden_global=18 WHERE codigo='asignaciones';  -- ⇄
UPDATE dbo.modulos_sistema SET ruta='/admin',                icono=NCHAR(0x2659), orden_global=30 WHERE codigo='administracion'; -- ♙
UPDATE dbo.modulos_sistema SET ruta='/configuracion',        icono=NCHAR(0x2699), orden_global=40 WHERE codigo='configuracion';  -- ⚙
-- Módulos sin página en la app: se desactivan (mi-menu los filtra por estado).
UPDATE dbo.modulos_sistema SET estado=0
WHERE codigo IN ('servicios', 'operaciones', 'reportes', 'estadisticas');
PRINT '  OK';

PRINT '=== 2/4 Insertando módulos faltantes ===';
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='distribucion')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('distribucion', 'Distribución', '/distribucion-geografica', NCHAR(0x2316), 'ambos', 4, 1, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='distribucion_geografica')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('distribucion_geografica', 'Distribución geográfica', '/distribucion-geografica', NCHAR(0x2316), 'ambos', 4, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='distribucion_tablero')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('distribucion_tablero', 'Tablero de distribución', '/distribucion-tablero', NCHAR(0x25A7), 'ambos', 4, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='distribucion_dashboard')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('distribucion_dashboard', 'Dashboard de distribución', '/distribucion-dashboard', NCHAR(0x25C8), 'ambos', 4, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='panel_asistencia')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('panel_asistencia', 'Panel de Asistencia', '/panel-asistencia', NCHAR(0x2610), 'ambos', 6, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='eventos')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('eventos', 'Eventos', '/eventos', NCHAR(0x25A7), 'ambos', 1, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='anuncios')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('anuncios', 'Anuncios', '/anuncios', NCHAR(0x25A7), 'ambos', 1, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='perfil')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('perfil', 'Mi perfil', '/perfil', NCHAR(0x25C9), 'ambos', 60, 0, 1);
IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo='mantenimiento')
    INSERT INTO dbo.modulos_sistema (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado)
    VALUES ('mantenimiento', 'Mantenimiento', '/admin?tab=mantenimiento', NCHAR(0x2692), 'web', 19, 0, 1);
PRINT '  OK';

PRINT '=== 3/4 Reconstruyendo dbo.rol_menu_configuracion desde permisos ===';
DELETE FROM dbo.rol_menu_configuracion;

DECLARE @menu_perm TABLE (codigo VARCHAR(60) NOT NULL, permiso VARCHAR(60) NOT NULL, grupo VARCHAR(40) NOT NULL, orden INT NOT NULL);

-- Grupo Administración (se muestra si el rol tiene cualquier hijo)
INSERT @menu_perm VALUES
 ('administracion','personal.ver','PRINCIPAL',1),
 ('administracion','catalogos.ver','PRINCIPAL',1),
 ('administracion','lugares_servicio.ver','PRINCIPAL',1),
 ('administracion','rutas.ver','PRINCIPAL',1),
 ('administracion','circuitos.ver','PRINCIPAL',1),
 ('administracion','eas.ver','PRINCIPAL',1),
 ('administracion','moviles.ver','PRINCIPAL',1),
 ('administracion','moviles.asignar','PRINCIPAL',1);
-- Hijos de Administración
INSERT @menu_perm VALUES
 ('personal','personal.ver','ADMINISTRACION',10),
 ('catalogos','catalogos.ver','ADMINISTRACION',11),
 ('lugares_servicio','lugares_servicio.ver','ADMINISTRACION',12),
 ('rutas','rutas.ver','ADMINISTRACION',13),
 ('circuitos','circuitos.ver','ADMINISTRACION',14),
 ('grados','personal.ver','ADMINISTRACION',15),
 ('eas','eas.ver','ADMINISTRACION',16),
 ('moviles','moviles.ver','ADMINISTRACION',17),
 ('asignaciones','moviles.asignar','ADMINISTRACION',18),
 ('mantenimiento','moviles.ver','ADMINISTRACION',19);
-- Grupo Distribución
INSERT @menu_perm VALUES
 ('distribucion','distribucion.ver','PRINCIPAL',2),
 ('distribucion','tablero_distribucion.ver','PRINCIPAL',2),
 ('distribucion_geografica','distribucion.ver','DISTRIBUCION',20),
 ('distribucion_tablero','tablero_distribucion.ver','DISTRIBUCION',21),
 ('distribucion_dashboard','distribucion.ver','DISTRIBUCION',22);
-- Grupo Eventos y anuncios
INSERT @menu_perm VALUES
 ('eventos_anuncios','eventos.ver','PRINCIPAL',3),
 ('eventos_anuncios','eventos.crear','PRINCIPAL',3),
 ('eventos_anuncios','anuncios.ver','PRINCIPAL',3),
 ('eventos','eventos.ver','EVENTOS_ANUNCIOS',30),
 ('eventos','eventos.crear','EVENTOS_ANUNCIOS',30),
 ('anuncios','anuncios.ver','EVENTOS_ANUNCIOS',31);
-- Hojas (permisos reales del catálogo)
INSERT @menu_perm VALUES
 ('panel_asistencia','asistencia.registrar','PRINCIPAL',4),
 ('panel_asistencia','asistencia.confirmar','PRINCIPAL',4),
 ('cartillas','cartillas.ver','PRINCIPAL',5),
 ('cartillas','cartillas.generar','PRINCIPAL',5),
 ('insignias','insignias.ver','PRINCIPAL',6),
 ('insignias','cartillas.ver','PRINCIPAL',6),
 ('soporte','soporte.listar','PRINCIPAL',7),
 ('soporte','soporte.crear','PRINCIPAL',7),
 ('soporte','soporte.visualizar','PRINCIPAL',7),
 ('soporte','soporte.consultar_detalle','PRINCIPAL',7),
 ('configuracion','configuracion.ver','PRINCIPAL',8),
 ('configuracion','roles.ver','PRINCIPAL',8),
 ('configuracion','permisos.ver','PRINCIPAL',8);

-- Módulos universales (dashboard = página de inicio; perfil = datos propios)
INSERT INTO dbo.rol_menu_configuracion
    (rol_id, modulo_id, grupo, orden, visible, habilitado, expandido, pagina_inicial, primera_opcion, mostrar_badge, mostrar_vacio)
SELECT r.id, ms.id, 'PRINCIPAL',
       CASE WHEN ms.codigo='dashboard' THEN 0 ELSE 9 END,
       1, 1, 0, CASE WHEN ms.codigo='dashboard' THEN 1 ELSE 0 END, 0, 0, 0
FROM dbo.roles r
CROSS JOIN dbo.modulos_sistema ms
WHERE ms.codigo IN ('dashboard','perfil') AND ms.estado=1;

-- Módulos habilitados por permiso (o por rol administrador, que los tiene todos)
INSERT INTO dbo.rol_menu_configuracion
    (rol_id, modulo_id, grupo, orden, visible, habilitado, expandido, pagina_inicial, primera_opcion, mostrar_badge, mostrar_vacio)
SELECT DISTINCT r.id, ms.id, mp.grupo, mp.orden, 1, 1, 0, 0, 0, 0, 0
FROM dbo.roles r
JOIN @menu_perm mp ON 1=1
JOIN dbo.modulos_sistema ms ON ms.codigo=mp.codigo AND ms.estado=1
LEFT JOIN dbo.rol_permiso rp ON rp.rol_id = r.id
LEFT JOIN dbo.permisos p ON p.id = rp.permiso_id AND p.codigo = mp.permiso
LEFT JOIN dbo.roles radm ON radm.id = r.id AND UPPER(ISNULL(radm.codigo,'')) LIKE '%ADMINISTRADOR%'
WHERE p.codigo IS NOT NULL OR radm.id IS NOT NULL;

-- Jerarquía: los hijos apuntan a su grupo (modulo_padre_id)
UPDATE rmc
SET modulo_padre_id = padre.id
FROM dbo.rol_menu_configuracion rmc
JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
JOIN dbo.modulos_sistema padre ON padre.codigo = CASE
    WHEN ms.codigo IN ('personal','catalogos','lugares_servicio','rutas','circuitos','grados','eas','moviles','asignaciones','mantenimiento') THEN 'administracion'
    WHEN ms.codigo IN ('distribucion_geografica','distribucion_tablero','distribucion_dashboard') THEN 'distribucion'
    WHEN ms.codigo IN ('eventos','anuncios') THEN 'eventos_anuncios'
    ELSE NULL
END AND padre.estado=1
WHERE ms.codigo IN ('personal','catalogos','lugares_servicio','rutas','circuitos','grados','eas','moviles','asignaciones','mantenimiento',
                    'distribucion_geografica','distribucion_tablero','distribucion_dashboard','eventos','anuncios');
PRINT '  OK';

PRINT '=== 4/4 Verificación ===';
SELECT r.nombre AS rol, COUNT(*) AS items, SUM(CASE WHEN visible=1 THEN 1 ELSE 0 END) AS visibles
FROM dbo.rol_menu_configuracion rmc
JOIN dbo.roles r ON r.id = rmc.rol_id
GROUP BY r.nombre ORDER BY r.nombre;
GO
