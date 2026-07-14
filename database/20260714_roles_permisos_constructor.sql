USE BITSAC;
GO

-- ===================================================================
-- MIGRACIÓN: Constructor visual de roles, menús y permisos
-- FASE 3: Creación de tablas, migración de datos y seed inicial
-- Rollback al final del archivo
-- ===================================================================

SET XACT_ABORT ON;
BEGIN TRANSACTION;

PRINT '=== INICIO MIGRACION: Constructor roles y permisos ===';

-- ===================================================================
-- 1. MODIFICAR TABLAS EXISTENTES
-- ===================================================================

-- 1.1 roles: agregar columnas faltantes
IF COL_LENGTH('dbo.roles', 'codigo') IS NULL
    ALTER TABLE dbo.roles ADD codigo NVARCHAR(80) NULL;
GO

IF COL_LENGTH('dbo.roles', 'rol_padre_id') IS NULL
    ALTER TABLE dbo.roles ADD rol_padre_id INT NULL;
GO

IF COL_LENGTH('dbo.roles', 'pagina_inicial') IS NULL
    ALTER TABLE dbo.roles ADD pagina_inicial NVARCHAR(200) NULL;
GO

IF COL_LENGTH('dbo.roles', 'nivel_jerarquico') IS NULL
    ALTER TABLE dbo.roles ADD nivel_jerarquico INT NOT NULL CONSTRAINT DF_roles_nivel DEFAULT (0);
GO

IF COL_LENGTH('dbo.roles', 'color_identificativo') IS NULL
    ALTER TABLE dbo.roles ADD color_identificativo NVARCHAR(20) NULL;
GO

-- Establecer codigo basado en nombre (solo para roles existentes)
UPDATE dbo.roles SET codigo = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(nombre, ' ', '_'), 'Á', 'A'), 'É', 'E'), 'Ó', 'O')) WHERE codigo IS NULL;
GO

-- Hacer codigo NOT NULL después de poblarlo
IF EXISTS (SELECT 1 FROM dbo.roles WHERE codigo IS NULL)
    THROW 50200, 'No se pudieron generar codigos para todos los roles.', 1;
GO

ALTER TABLE dbo.roles ALTER COLUMN codigo NVARCHAR(80) NOT NULL;
GO

-- Agregar UNIQUE en codigo si no existe
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_roles_codigo' AND object_id = OBJECT_ID('dbo.roles'))
    CREATE UNIQUE INDEX UQ_roles_codigo ON dbo.roles (codigo) WHERE codigo IS NOT NULL;
GO

-- FK a rol_padre_id
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_roles_rol_padre')
    ALTER TABLE dbo.roles ADD CONSTRAINT FK_roles_rol_padre FOREIGN KEY (rol_padre_id) REFERENCES dbo.roles(id);
GO

-- 1.2 permisos: agregar recurso y accion
IF COL_LENGTH('dbo.permisos', 'recurso') IS NULL
    ALTER TABLE dbo.permisos ADD recurso NVARCHAR(80) NULL;
GO

IF COL_LENGTH('dbo.permisos', 'accion') IS NULL
    ALTER TABLE dbo.permisos ADD accion NVARCHAR(80) NULL;
GO

-- Poblar recurso y accion desde codigo (formato: modulo.accion)
UPDATE dbo.permisos
SET recurso = LEFT(codigo, CHARINDEX('.', codigo) - 1),
    accion = SUBSTRING(codigo, CHARINDEX('.', codigo) + 1, LEN(codigo))
WHERE CHARINDEX('.', codigo) > 0
  AND (recurso IS NULL OR accion IS NULL);
GO

-- Para permisos sin punto en el codigo, usar el modulo como recurso
UPDATE dbo.permisos
SET recurso = modulo, accion = codigo
WHERE recurso IS NULL OR accion IS NULL;
GO

-- 1.3 rol_permiso: agregar columnas permitido, heredado
IF COL_LENGTH('dbo.rol_permiso', 'permitido') IS NULL
    ALTER TABLE dbo.rol_permiso ADD permitido BIT NOT NULL CONSTRAINT DF_rol_permiso_permitido DEFAULT (1);
GO

IF COL_LENGTH('dbo.rol_permiso', 'heredado') IS NULL
    ALTER TABLE dbo.rol_permiso ADD heredado BIT NOT NULL CONSTRAINT DF_rol_permiso_heredado DEFAULT (0);
GO

IF COL_LENGTH('dbo.rol_permiso', 'fecha_actualizacion') IS NULL
    ALTER TABLE dbo.rol_permiso ADD fecha_actualizacion DATETIME2 NULL;
GO

PRINT 'OK - Tablas existentes modificadas.';

-- ===================================================================
-- 2. CREAR NUEVAS TABLAS
-- ===================================================================

-- 2.1 modulos_sistema
IF OBJECT_ID('dbo.modulos_sistema', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.modulos_sistema (
        id INT IDENTITY(1,1) PRIMARY KEY,
        codigo NVARCHAR(80) NOT NULL UNIQUE,
        nombre NVARCHAR(120) NOT NULL,
        ruta NVARCHAR(200) NULL,
        icono NVARCHAR(80) NULL,
        plataforma NVARCHAR(20) NOT NULL CONSTRAINT DF_modulos_plataforma DEFAULT ('ambos'),
        orden_global INT NOT NULL CONSTRAINT DF_modulos_orden DEFAULT (0),
        tiene_submenus BIT NOT NULL CONSTRAINT DF_modulos_submenus DEFAULT (0),
        estado BIT NOT NULL CONSTRAINT DF_modulos_estado DEFAULT (1),
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_modulos_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_modulos_plataforma CHECK (plataforma IN ('web', 'movil', 'ambos'))
    );
    PRINT 'OK - Tabla modulos_sistema creada.';
END
ELSE
    PRINT 'OK - Tabla modulos_sistema ya existe.';
GO

-- 2.2 rol_menu_configuracion
IF OBJECT_ID('dbo.rol_menu_configuracion', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_menu_configuracion (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        modulo_id INT NOT NULL,
        modulo_padre_id INT NULL,
        grupo NVARCHAR(80) NULL,
        nombre_visual NVARCHAR(120) NULL,
        icono_visual NVARCHAR(80) NULL,
        orden INT NOT NULL CONSTRAINT DF_rol_menu_orden DEFAULT (0),
        visible BIT NOT NULL CONSTRAINT DF_rol_menu_visible DEFAULT (1),
        habilitado BIT NOT NULL CONSTRAINT DF_rol_menu_habilitado DEFAULT (1),
        expandido BIT NOT NULL CONSTRAINT DF_rol_menu_expandido DEFAULT (0),
        pagina_inicial BIT NOT NULL CONSTRAINT DF_rol_menu_inicio DEFAULT (0),
        primera_opcion BIT NOT NULL CONSTRAINT DF_rol_menu_primera DEFAULT (0),
        mostrar_badge BIT NOT NULL CONSTRAINT DF_rol_menu_badge DEFAULT (0),
        color_badge NVARCHAR(20) NULL,
        mostrar_vacio BIT NOT NULL CONSTRAINT DF_rol_menu_vacio DEFAULT (1),
        fecha_actualizacion DATETIME2 NULL,
        CONSTRAINT FK_rol_menu_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_menu_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
        CONSTRAINT FK_rol_menu_modulo_padre FOREIGN KEY (modulo_padre_id) REFERENCES dbo.modulos_sistema(id),
        CONSTRAINT UQ_rol_menu UNIQUE (rol_id, modulo_id)
    );
    PRINT 'OK - Tabla rol_menu_configuracion creada.';
END
ELSE
    PRINT 'OK - Tabla rol_menu_configuracion ya existe.';
GO

-- 2.3 campos_sistema
IF OBJECT_ID('dbo.campos_sistema', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.campos_sistema (
        id INT IDENTITY(1,1) PRIMARY KEY,
        modulo_id INT NOT NULL,
        codigo NVARCHAR(120) NOT NULL,
        nombre NVARCHAR(200) NOT NULL,
        tipo_dato NVARCHAR(40) NOT NULL CONSTRAINT DF_campos_tipo DEFAULT ('texto'),
        clasificacion NVARCHAR(40) NOT NULL CONSTRAINT DF_campos_clasificacion DEFAULT ('general'),
        estado BIT NOT NULL CONSTRAINT DF_campos_estado DEFAULT (1),
        CONSTRAINT FK_campos_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
        CONSTRAINT UQ_campos_modulo_codigo UNIQUE (modulo_id, codigo),
        CONSTRAINT CK_campos_tipo CHECK (tipo_dato IN ('texto','numero','fecha','email','telefono')),
        CONSTRAINT CK_campos_clasificacion CHECK (clasificacion IN ('general','sensible','medica','disciplinaria'))
    );
    PRINT 'OK - Tabla campos_sistema creada.';
END
ELSE
    PRINT 'OK - Tabla campos_sistema ya existe.';
GO

-- 2.4 rol_campos_permisos
IF OBJECT_ID('dbo.rol_campos_permisos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_campos_permisos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        campo_id INT NOT NULL,
        nivel_acceso NVARCHAR(20) NOT NULL CONSTRAINT DF_rol_campos_acceso DEFAULT ('oculto'),
        enmascarado BIT NOT NULL CONSTRAINT DF_rol_campos_mascara DEFAULT (0),
        CONSTRAINT FK_rol_campos_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_campos_campo FOREIGN KEY (campo_id) REFERENCES dbo.campos_sistema(id),
        CONSTRAINT UQ_rol_campos UNIQUE (rol_id, campo_id),
        CONSTRAINT CK_rol_campos_acceso CHECK (nivel_acceso IN ('oculto','lectura','editable','obligatorio'))
    );
    PRINT 'OK - Tabla rol_campos_permisos creada.';
END
ELSE
    PRINT 'OK - Tabla rol_campos_permisos ya existe.';
GO

-- 2.5 rol_alcance_datos
IF OBJECT_ID('dbo.rol_alcance_datos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_alcance_datos (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        modulo_id INT NOT NULL,
        tipo_alcance NVARCHAR(40) NOT NULL,
        configuracion_json NVARCHAR(MAX) NULL,
        CONSTRAINT FK_rol_alcance_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_alcance_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
        CONSTRAINT UQ_rol_alcance UNIQUE (rol_id, modulo_id),
        CONSTRAINT CK_rol_alcance_tipo CHECK (tipo_alcance IN (
            'propio','area','equipo','turno','distrito',
            'creado_por_usuario','asignado_usuario','global','personalizado'
        ))
    );
    PRINT 'OK - Tabla rol_alcance_datos creada.';
END
ELSE
    PRINT 'OK - Tabla rol_alcance_datos ya existe.';
GO

-- 2.6 rol_condiciones
IF OBJECT_ID('dbo.rol_condiciones', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.rol_condiciones (
        id INT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        modulo_id INT NULL,
        campo NVARCHAR(120) NOT NULL,
        operador NVARCHAR(20) NOT NULL,
        valor NVARCHAR(500) NULL,
        agrupador NVARCHAR(10) NULL,
        estado BIT NOT NULL CONSTRAINT DF_rol_cond_estado DEFAULT (1),
        CONSTRAINT FK_rol_cond_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT FK_rol_cond_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
        CONSTRAINT CK_rol_cond_operador CHECK (operador IN (
            'igual','diferente','contiene','en','mayor','menor','verdadero','falso','vacio','no_vacio'
        )),
        CONSTRAINT CK_rol_cond_agrupador CHECK (agrupador IS NULL OR agrupador IN ('AND','OR'))
    );
    PRINT 'OK - Tabla rol_condiciones creada.';
END
ELSE
    PRINT 'OK - Tabla rol_condiciones ya existe.';
GO

-- 2.7 versiones_configuracion_roles
IF OBJECT_ID('dbo.versiones_configuracion_roles', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.versiones_configuracion_roles (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        rol_id INT NOT NULL,
        version INT NOT NULL,
        estado NVARCHAR(20) NOT NULL CONSTRAINT DF_versiones_estado DEFAULT ('borrador'),
        configuracion_json NVARCHAR(MAX) NOT NULL,
        comentario NVARCHAR(500) NULL,
        creado_por INT NOT NULL,
        fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_versiones_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_versiones_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
        CONSTRAINT UQ_versiones_rol_version UNIQUE (rol_id, version),
        CONSTRAINT CK_versiones_estado CHECK (estado IN ('borrador','publicado','restaurado'))
    );
    PRINT 'OK - Tabla versiones_configuracion_roles creada.';
END
ELSE
    PRINT 'OK - Tabla versiones_configuracion_roles ya existe.';
GO

-- 2.8 auditoria_roles_permisos
IF OBJECT_ID('dbo.auditoria_roles_permisos', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.auditoria_roles_permisos (
        id BIGINT IDENTITY(1,1) PRIMARY KEY,
        usuario_id INT NOT NULL,
        accion NVARCHAR(40) NOT NULL,
        rol_afectado_id INT NULL,
        valor_anterior NVARCHAR(MAX) NULL,
        valor_nuevo NVARCHAR(MAX) NULL,
        ip NVARCHAR(80) NULL,
        dispositivo NVARCHAR(200) NULL,
        fecha DATETIME2 NOT NULL CONSTRAINT DF_aud_roles_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_aud_roles_rol FOREIGN KEY (rol_afectado_id) REFERENCES dbo.roles(id),
        CONSTRAINT CK_aud_roles_accion CHECK (accion IN (
            'crear_rol','editar_rol','desactivar_rol','eliminar_rol',
            'asignar_permiso','quitar_permiso',
            'publicar_config','guardar_borrador','restaurar_version',
            'asignar_usuario','quitar_usuario'
        ))
    );
    PRINT 'OK - Tabla auditoria_roles_permisos creada.';
END
ELSE
    PRINT 'OK - Tabla auditoria_roles_permisos ya existe.';
GO

-- ===================================================================
-- 3. SEED: modulos_sistema
-- ===================================================================

PRINT 'Poblando modulos_sistema...';

DECLARE @modulos TABLE (
    codigo NVARCHAR(80),
    nombre NVARCHAR(120),
    ruta NVARCHAR(200),
    icono NVARCHAR(80),
    plataforma NVARCHAR(20),
    orden_global INT,
    tiene_submenus BIT
);

INSERT INTO @modulos (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus)
VALUES
-- Menú principal (grupo MENU_PRINCIPAL en Flutter actual)
('dashboard',         'Dashboard',         '/dashboard',         'dashboard',              'ambos', 0,  0),
('eventos_anuncios',  'Eventos y anuncios','/eventos',           'event_outlined',         'ambos', 1,  1),
('cartillas',         'Cartillas',         '/cartillas',         'description_outlined',   'ambos', 2,  0),
('insignias',         'Mis insignias',     '/insignias',         'workspace_premium_outlined','ambos',3,  0),

-- Grupo OPERATIVO
('servicios',         'Servicios',         '/servicios',         'local_police_outlined',  'ambos', 4,  0),
('operaciones',       'Operaciones',       '/operaciones',       'security_outlined',      'ambos', 5,  0),

-- Admin (actualmente en ADMINISTRACION)
('personal',          'Personal',          '/admin/personal',    'people_outlined',        'web',   10, 0),
('moviles',           'Móviles',           '/admin/moviles',     'directions_car_outlined','web',   11, 0),
('asignaciones',      'Asignaciones',      '/admin/asignaciones','assignment_outlined',    'web',   12, 0),
('lugares_servicio',  'Lugares de servicio','/admin/lugares',    'location_city_outlined', 'web',   13, 0),
('eas',               'EAS',               '/admin/eas',         'cell_tower_outlined',    'web',   14, 0),
('rutas',             'Rutas',             '/admin/rutas',       'route_outlined',         'web',   15, 0),
('grados',            'Grados',            '/admin/grados',      'military_tech_outlined', 'web',   16, 0),
('catalogos',         'Catálogos',         '/admin/catalogos',   'list_alt_outlined',      'web',   17, 0),

-- Reportes / Estadisticas
('reportes',          'Reportes',          '/reportes',          'bar_chart_outlined',     'ambos', 20, 0),
('estadisticas',      'Estadísticas',      '/estadisticas',      'insights_outlined',      'ambos', 21, 0),

-- Administracion (grupo ADMINISTRACION)
('administracion',    'Administración',    '/admin',             'admin_panel_settings_outlined','web', 30, 1),

-- Configuracion
('configuracion',     'Configuración',     '/config',            'settings_outlined',      'ambos', 40, 1),

-- Soporte
('soporte',           'Alertas / Soporte', '/soporte',           'notifications_active_outlined','ambos', 50, 0);

MERGE dbo.modulos_sistema AS target
USING @modulos AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET
        nombre = source.nombre,
        ruta = source.ruta,
        icono = source.icono,
        plataforma = source.plataforma,
        orden_global = source.orden_global,
        tiene_submenus = source.tiene_submenus,
        estado = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus)
    VALUES (source.codigo, source.nombre, source.ruta, source.icono, source.plataforma, source.orden_global, source.tiene_submenus);

PRINT 'OK - modulos_sistema poblado.';

-- ===================================================================
-- 4. NUEVOS PERMISOS GRANULARES
-- ===================================================================

PRINT 'Agregando nuevos permisos granulares...';

DECLARE @nuevosPermisos TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255), modulo NVARCHAR(80), recurso NVARCHAR(80), accion NVARCHAR(80));
INSERT INTO @nuevosPermisos (codigo, descripcion, modulo, recurso, accion)
VALUES
-- Modulo configuracion
('configuracion.roles.gestionar', N'Acceso al editor de roles, menús y permisos', 'configuracion', 'configuracion', 'roles.gestionar'),
('configuracion.roles.ver', N'Ver configuración de roles', 'configuracion', 'configuracion', 'roles.ver'),
('configuracion.general.ver', N'Ver configuración general', 'configuracion', 'configuracion', 'general.ver'),
('configuracion.general.editar', N'Editar configuración general', 'configuracion', 'configuracion', 'general.editar'),

-- Permisos granulares para Eventos
('eventos.visualizar', N'Ver módulo eventos en el menú', 'eventos', 'eventos', 'visualizar'),
('eventos.listar', N'Listar eventos', 'eventos', 'eventos', 'listar'),
('eventos.consultar_detalle', N'Ver detalle de evento', 'eventos', 'eventos', 'consultar_detalle'),
('eventos.confirmar_asistencia', N'Confirmar asistencia a evento', 'eventos', 'eventos', 'confirmar_asistencia'),
('eventos.gestionar_asistentes', N'Gestionar asistentes a evento', 'eventos', 'eventos', 'gestionar_asistentes'),
('eventos.descargar_archivos', N'Descargar archivos de evento', 'eventos', 'eventos', 'descargar_archivos'),
('eventos.abrir_ubicacion', N'Abrir ubicación de evento en mapa', 'eventos', 'eventos', 'abrir_ubicacion'),

-- Permisos granulares para Anuncios
('anuncios.visualizar', N'Ver módulo anuncios en el menú', 'anuncios', 'anuncios', 'visualizar'),
('anuncios.listar', N'Listar anuncios', 'anuncios', 'anuncios', 'listar'),
('anuncios.consultar_detalle', N'Ver detalle de anuncio', 'anuncios', 'anuncios', 'consultar_detalle'),
('anuncios.publicar', N'Publicar anuncios', 'anuncios', 'anuncios', 'publicar'),
('anuncios.archivar', N'Archivar anuncios', 'anuncios', 'anuncios', 'archivar'),
('anuncios.compartir', N'Compartir anuncios', 'anuncios', 'anuncios', 'compartir'),

-- Permisos granulares para Personal
('personal.visualizar', N'Ver módulo personal en el menú', 'personal', 'personal', 'visualizar'),
('personal.ver_sensible', N'Ver información sensible (cédula, teléfono)', 'personal', 'personal', 'ver_sensible'),
('personal.exportar', N'Exportar personal', 'personal', 'personal', 'exportar'),

-- Permisos granulares para Soporte
('soporte.visualizar', N'Ver módulo soporte en el menú', 'soporte', 'soporte', 'visualizar'),
('soporte.listar', N'Listar alertas', 'soporte', 'soporte', 'listar'),
('soporte.consultar_detalle', N'Ver detalle de alerta', 'soporte', 'soporte', 'consultar_detalle'),
('soporte.crear', N'Crear alertas', 'soporte', 'soporte', 'crear'),
('soporte.comentar', N'Comentar alertas', 'soporte', 'soporte', 'comentar'),
('soporte.exportar', N'Exportar alertas', 'soporte', 'soporte', 'exportar'),

-- Permisos granulares para Cartillas
('cartillas.visualizar', N'Ver módulo cartillas en el menú', 'cartillas', 'cartillas', 'visualizar'),
('cartillas.listar', N'Listar cartillas', 'cartillas', 'cartillas', 'listar'),
('cartillas.exportar', N'Exportar cartillas', 'cartillas', 'cartillas', 'exportar'),

-- Permisos granulares para Insignias
('insignias.visualizar', N'Ver módulo insignias en el menú', 'insignias', 'insignias', 'visualizar'),
('insignias.listar', N'Listar insignias', 'insignias', 'insignias', 'listar'),

-- Permisos granulares para Moviles
('moviles.exportar', N'Exportar móviles', 'moviles', 'moviles', 'exportar'),

-- Permisos para Dashboard
('dashboard.ver', N'Ver dashboard', 'dashboard', 'dashboard', 'ver');

-- Insertar solo los que no existen
MERGE dbo.permisos AS target
USING @nuevosPermisos AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET descripcion = source.descripcion, modulo = source.modulo, recurso = source.recurso, accion = source.accion, activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, descripcion, modulo, recurso, accion, activo)
    VALUES (source.codigo, source.descripcion, source.modulo, source.recurso, source.accion, 1);

PRINT 'OK - Nuevos permisos agregados.';

-- ===================================================================
-- 5. ASIGNAR PERMISO configuracion.roles.gestionar AL ADMIN
-- ===================================================================

DECLARE @permConfigId INT = (SELECT id FROM dbo.permisos WHERE codigo = 'configuracion.roles.gestionar');
DECLARE @adminRolId INT = (SELECT id FROM dbo.roles WHERE codigo = 'ADMINISTRADOR');

IF @permConfigId IS NOT NULL AND @adminRolId IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM dbo.rol_permiso WHERE rol_id = @adminRolId AND permiso_id = @permConfigId)
BEGIN
    INSERT INTO dbo.rol_permiso (rol_id, permiso_id) VALUES (@adminRolId, @permConfigId);
    PRINT 'OK - configuracion.roles.gestionar asignado a Administrador.';
END
ELSE
    PRINT 'OK - configuracion.roles.gestionar ya estaba asignado a Administrador.';
GO

-- ===================================================================
-- 6. GENERAR CONFIGURACIÓN INICIAL DE MENÚ PARA CADA ROL
-- ===================================================================

PRINT 'Generando configuración inicial de menú para roles existentes...';

-- Esta configuración replica la estructura actual del menú Flutter:
-- Grupo MENU_PRINCIPAL: Eventos, Cartillas, Mis insignias
-- Grupo OPERATIVO: Servicios, Operaciones
-- Grupo ADMINISTRACION: Administracion (condicional)
-- Suelto: Alertas / Soporte

DECLARE @rolId INT, @rolCodigo NVARCHAR(80), @rolNombre NVARCHAR(80);
DECLARE @moduloId INT, @moduloCodigo NVARCHAR(80);

-- Cursor por cada rol activo
DECLARE rol_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT id, codigo, nombre FROM dbo.roles WHERE activo = 1;

OPEN rol_cursor;
FETCH NEXT FROM rol_cursor INTO @rolId, @rolCodigo, @rolNombre;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT '  Configurando rol: ' + @rolNombre;

    -- Eventos y anuncios (orden 1, grupo MENU_PRINCIPAL)
    SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'eventos_anuncios';
    IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
        INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden, pagina_inicial)
        VALUES (@rolId, @moduloId, 'MENU_PRINCIPAL', 1, 1);

    -- Cartillas (orden 2, grupo MENU_PRINCIPAL)
    SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'cartillas';
    IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
        INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
        VALUES (@rolId, @moduloId, 'MENU_PRINCIPAL', 2);

    -- Mis insignias (orden 3, grupo MENU_PRINCIPAL)
    SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'insignias';
    IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
        INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
        VALUES (@rolId, @moduloId, 'MENU_PRINCIPAL', 3);

    -- Servicios (orden 1, grupo OPERATIVO) — SOLO para roles que tienen servicios.ver
    IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'servicios.ver')
    BEGIN
        SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'servicios';
        IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
            INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
            VALUES (@rolId, @moduloId, 'OPERATIVO', 1);
    END;

    -- Operaciones (orden 2, grupo OPERATIVO) — Solo para roles que tienen dashboard.mantenimiento o similar
    IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo IN ('dashboard.mantenimiento','novedades.ver'))
    BEGIN
        SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'operaciones';
        IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
            INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
            VALUES (@rolId, @moduloId, 'OPERATIVO', 2);
    END;

    -- Administración (grupo ADMINISTRACION) — Solo si tiene administracion.ver
    IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'administracion.ver')
    BEGIN
        SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'administracion';
        IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
            INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
            VALUES (@rolId, @moduloId, 'ADMINISTRACION', 1);

        -- Submódulos de administración
        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'personal.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'personal';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 2);
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'moviles.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'moviles';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 3);

            IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'moviles.asignar')
            BEGIN
                SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'asignaciones';
                IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                    INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                    VALUES (@rolId, @moduloId, 'ADMINISTRACION', 4);
            END;
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'lugares_servicio.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'lugares_servicio';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 5);
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'eas.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'eas';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 6);
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'rutas.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'rutas';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 7);
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'personal.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'grados';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 8);
        END;

        IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'catalogos.ver')
        BEGIN
            SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'catalogos';
            IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
                INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
                VALUES (@rolId, @moduloId, 'ADMINISTRACION', 9);
        END;
    END;

    -- Configuración (solo roles con configuracion.roles.gestionar)
    IF EXISTS (SELECT 1 FROM dbo.rol_permiso rp INNER JOIN dbo.permisos p ON p.id = rp.permiso_id WHERE rp.rol_id = @rolId AND p.codigo = 'configuracion.roles.gestionar')
    BEGIN
        SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'configuracion';
        IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
            INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, grupo, orden)
            VALUES (@rolId, @moduloId, 'ADMINISTRACION', 10);
    END;

    -- Soporte (siempre visible para todos los roles autenticados)
    SELECT @moduloId = id FROM dbo.modulos_sistema WHERE codigo = 'soporte';
    IF NOT EXISTS (SELECT 1 FROM dbo.rol_menu_configuracion WHERE rol_id = @rolId AND modulo_id = @moduloId)
        INSERT INTO dbo.rol_menu_configuracion (rol_id, modulo_id, orden, mostrar_badge)
        VALUES (@rolId, @moduloId, 50, 1);

    FETCH NEXT FROM rol_cursor INTO @rolId, @rolCodigo, @rolNombre;
END;

CLOSE rol_cursor;
DEALLOCATE rol_cursor;

PRINT 'OK - Configuración inicial de menú generada.';

-- ===================================================================
-- 7. ALCANCE DE DATOS INICIAL
-- ===================================================================

PRINT 'Generando alcance de datos inicial...';

-- Por cada rol y cada modulo que tenga configurado, crear alcance global para admin y propio para el resto
DECLARE @adminId INT = (SELECT id FROM dbo.roles WHERE codigo = 'ADMINISTRADOR');

DECLARE alcance_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT DISTINCT rmc.rol_id, rmc.modulo_id
    FROM dbo.rol_menu_configuracion rmc
    WHERE NOT EXISTS (SELECT 1 FROM dbo.rol_alcance_datos rad WHERE rad.rol_id = rmc.rol_id AND rad.modulo_id = rmc.modulo_id);

DECLARE @alcRolId INT, @alcModuloId INT;

OPEN alcance_cursor;
FETCH NEXT FROM alcance_cursor INTO @alcRolId, @alcModuloId;

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO dbo.rol_alcance_datos (rol_id, modulo_id, tipo_alcance)
    VALUES (@alcRolId, @alcModuloId, CASE WHEN @alcRolId = @adminId THEN 'global' ELSE 'propio' END);

    FETCH NEXT FROM alcance_cursor INTO @alcRolId, @alcModuloId;
END;

CLOSE alcance_cursor;
DEALLOCATE alcance_cursor;

PRINT 'OK - Alcance de datos inicial generado.';

-- ===================================================================
-- 8. VERSIÓN INICIAL (v1 publicada)
-- ===================================================================

PRINT 'Creando version 1 inicial para cada rol...';

DECLARE ver_cursor CURSOR LOCAL FAST_FORWARD FOR
    SELECT r.id, r.nombre
    FROM dbo.roles r
    WHERE r.activo = 1
      AND NOT EXISTS (SELECT 1 FROM dbo.versiones_configuracion_roles v WHERE v.rol_id = r.id);

DECLARE @verRolId INT, @verRolNombre NVARCHAR(80);

OPEN ver_cursor;
FETCH NEXT FROM ver_cursor INTO @verRolId, @verRolNombre;

WHILE @@FETCH_STATUS = 0
BEGIN
    DECLARE @snapshotJson NVARCHAR(MAX) = (
        SELECT
            r.codigo AS rol_codigo,
            r.nombre AS rol_nombre,
            (
                SELECT
                    m.codigo AS modulo_codigo,
                    m.nombre AS modulo_nombre,
                    rmc.grupo,
                    rmc.orden,
                    rmc.visible,
                    rmc.habilitado,
                    rmc.pagina_inicial,
                    rmc.mostrar_badge,
                    (
                        SELECT p.codigo
                        FROM dbo.rol_permiso rp
                        INNER JOIN dbo.permisos p ON p.id = rp.permiso_id
                        WHERE rp.rol_id = rmc.rol_id AND rp.permitido = 1
                        FOR JSON PATH
                    ) AS permisos_json
                FROM dbo.rol_menu_configuracion rmc
                INNER JOIN dbo.modulos_sistema m ON m.id = rmc.modulo_id
                WHERE rmc.rol_id = @verRolId
                ORDER BY rmc.orden
                FOR JSON PATH
            ) AS menus_json,
            (
                SELECT tipo_alcance, modulo_id
                FROM dbo.rol_alcance_datos rad
                WHERE rad.rol_id = @verRolId
                FOR JSON PATH
            ) AS alcance_json
        FROM dbo.roles r
        WHERE r.id = @verRolId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    );

    INSERT INTO dbo.versiones_configuracion_roles (rol_id, version, estado, configuracion_json, comentario, creado_por)
    VALUES (@verRolId, 1, 'publicado', @snapshotJson, N'Configuración inicial migrada desde sistema anterior', 1);

    PRINT '  Version 1 creada para: ' + @verRolNombre;

    FETCH NEXT FROM ver_cursor INTO @verRolId, @verRolNombre;
END;

CLOSE ver_cursor;
DEALLOCATE ver_cursor;

PRINT 'OK - Versiones iniciales creadas.';

-- ===================================================================
-- 9. CAMPOS DEL SISTEMA (seed inicial)
-- ===================================================================

PRINT 'Poblando campos del sistema...';

-- Personal
DECLARE @modPersonalId INT = (SELECT id FROM dbo.modulos_sistema WHERE codigo = 'personal');

IF @modPersonalId IS NOT NULL
BEGIN
    DECLARE @camposPersonal TABLE (codigo NVARCHAR(120), nombre NVARCHAR(200), tipo_dato NVARCHAR(40), clasificacion NVARCHAR(40));
    INSERT INTO @camposPersonal (codigo, nombre, tipo_dato, clasificacion)
    VALUES
    ('personal.nombres', N'Nombres', 'texto', 'general'),
    ('personal.apellidos', N'Apellidos', 'texto', 'general'),
    ('personal.cedula', N'Cédula', 'texto', 'sensible'),
    ('personal.correo', N'Correo', 'email', 'general'),
    ('personal.telefono', N'Teléfono', 'telefono', 'sensible'),
    ('personal.fecha_nacimiento', N'Fecha de nacimiento', 'fecha', 'sensible'),
    ('personal.cargo', N'Cargo', 'texto', 'general'),
    ('personal.area', N'Área', 'texto', 'general'),
    ('personal.rol', N'Rol', 'texto', 'general'),
    ('personal.grupo', N'Grupo', 'texto', 'general'),
    ('personal.jornada', N'Jornada', 'texto', 'general'),
    ('personal.estado', N'Estado', 'texto', 'general');

    MERGE dbo.campos_sistema AS target
    USING @camposPersonal AS source
    ON target.modulo_id = @modPersonalId AND target.codigo = source.codigo
    WHEN MATCHED THEN
        UPDATE SET nombre = source.nombre, tipo_dato = source.tipo_dato, clasificacion = source.clasificacion, estado = 1
    WHEN NOT MATCHED THEN
        INSERT (modulo_id, codigo, nombre, tipo_dato, clasificacion)
        VALUES (@modPersonalId, source.codigo, source.nombre, source.tipo_dato, source.clasificacion);
END;

PRINT 'OK - Campos del sistema poblados.';

-- ===================================================================
-- 10. ACTUALIZAR ROLES ADMIN CON CODIGOS
-- ===================================================================

-- Asegurar que roles del seed tengan codigos correctos
UPDATE dbo.roles SET codigo = 'ADMINISTRADOR' WHERE codigo = 'ADMINISTRADOR' AND id > 0;
UPDATE dbo.roles SET codigo = 'OPERACIONES' WHERE nombre = 'Operaciones' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'SUPERVISOR' WHERE nombre = 'Supervisor' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'INSPECTOR' WHERE nombre = 'Inspector' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'AGENTE' WHERE nombre IN ('Agente','Agente municipal') AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'COMUNICACIONES' WHERE nombre = 'Comunicaciones' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'CONSULTA' WHERE nombre = 'Consulta' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'AUDITORIA' WHERE nombre IN ('Auditoria','Auditor') AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'RADIOPERADOR_SEGURA_EP' WHERE nombre = 'Radioperador SEGURA EP' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'ENCARGADO' WHERE nombre = 'Encargado' AND codigo IS NULL;
UPDATE dbo.roles SET codigo = 'PERSONAL_OPERATIVO' WHERE nombre = 'Personal Operativo' AND codigo IS NULL;
GO

-- ===================================================================
-- COMMIT
-- ===================================================================

COMMIT TRANSACTION;

PRINT '=== MIGRACION COMPLETADA EXITOSAMENTE ===';
GO

-- ===================================================================
-- ROLLBACK
-- ===================================================================
-- Ejecutar las siguientes instrucciones para revertir la migración:
--
-- BEGIN TRANSACTION;
--
-- DROP TABLE IF EXISTS dbo.auditoria_roles_permisos;
-- DROP TABLE IF EXISTS dbo.versiones_configuracion_roles;
-- DROP TABLE IF EXISTS dbo.rol_condiciones;
-- DROP TABLE IF EXISTS dbo.rol_alcance_datos;
-- DROP TABLE IF EXISTS dbo.rol_campos_permisos;
-- DROP TABLE IF EXISTS dbo.campos_sistema;
-- DROP TABLE IF EXISTS dbo.rol_menu_configuracion;
-- DROP TABLE IF EXISTS dbo.modulos_sistema;
--
-- -- Restaurar columnas originales de rol_permiso
-- ALTER TABLE dbo.rol_permiso DROP CONSTRAINT DF_rol_permiso_permitido;
-- ALTER TABLE dbo.rol_permiso DROP COLUMN permitido;
-- ALTER TABLE dbo.rol_permiso DROP CONSTRAINT DF_rol_permiso_heredado;
-- ALTER TABLE dbo.rol_permiso DROP COLUMN heredado;
-- ALTER TABLE dbo.rol_permiso DROP COLUMN fecha_actualizacion;
--
-- -- Restaurar columnas originales de permisos
-- ALTER TABLE dbo.permisos DROP COLUMN recurso;
-- ALTER TABLE dbo.permisos DROP COLUMN accion;
--
-- -- Restaurar columnas originales de roles
-- ALTER TABLE dbo.roles DROP CONSTRAINT FK_roles_rol_padre;
-- DROP INDEX IF EXISTS UQ_roles_codigo ON dbo.roles;
-- ALTER TABLE dbo.roles DROP CONSTRAINT DF_roles_nivel;
-- ALTER TABLE dbo.roles DROP COLUMN codigo;
-- ALTER TABLE dbo.roles DROP COLUMN rol_padre_id;
-- ALTER TABLE dbo.roles DROP COLUMN pagina_inicial;
-- ALTER TABLE dbo.roles DROP COLUMN nivel_jerarquico;
-- ALTER TABLE dbo.roles DROP COLUMN color_identificativo;
--
-- -- Eliminar permisos nuevos
-- DELETE FROM dbo.rol_permiso WHERE permiso_id IN (SELECT id FROM dbo.permisos WHERE codigo LIKE 'configuracion.%');
-- DELETE FROM dbo.rol_permiso WHERE permiso_id IN (SELECT id FROM dbo.permisos WHERE codigo LIKE 'eventos.visualizar' OR codigo LIKE 'eventos.listar%');
-- DELETE FROM dbo.rol_permiso WHERE permiso_id IN (SELECT id FROM dbo.permisos WHERE codigo LIKE 'anuncios.visualizar' OR codigo LIKE 'anuncios.listar%');
-- DELETE FROM dbo.permisos WHERE codigo LIKE 'configuracion.%';
-- DELETE FROM dbo.permisos WHERE codigo IN (
--     'eventos.visualizar','eventos.listar','eventos.consultar_detalle',
--     'eventos.confirmar_asistencia','eventos.gestionar_asistentes',
--     'eventos.descargar_archivos','eventos.abrir_ubicacion',
--     'anuncios.visualizar','anuncios.listar','anuncios.consultar_detalle',
--     'anuncios.publicar','anuncios.archivar','anuncios.compartir',
--     'personal.visualizar','personal.ver_sensible','personal.exportar',
--     'soporte.visualizar','soporte.listar','soporte.consultar_detalle',
--     'soporte.crear','soporte.comentar','soporte.exportar',
--     'cartillas.visualizar','cartillas.listar','cartillas.exportar',
--     'insignias.visualizar','insignias.listar',
--     'moviles.exportar','dashboard.ver'
-- );
--
-- COMMIT TRANSACTION;
-- PRINT 'ROLLBACK COMPLETADO';
-- GO
