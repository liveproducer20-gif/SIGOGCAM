/*
 ============================================================================
  SCRIPT COMPLETO DE CREACIÓN DE BASE DE DATOS - BITSAC
  ----------------------------------------------------------------------------
  Este script consolida TODOS los archivos de migración realizados hasta la
  fecha (2026-08-07) en un único archivo ejecutable desde cero.

  ORDEN DE ESTRUCTURA:
    1. Creación de la base de datos
    2. Tablas de catálogos maestros
    3. Tablas de seguridad / RBAC (roles, permisos, módulos)
    4. Tablas base (personal, eventos, anuncios, movilidad, rutas)
    5. Tablas de distribución geográfica y tablero
    6. Vistas
    7. Índices
    8. Datos semilla (catálogos, roles, permisos, turnos, usuarios de prueba)

  Compatible con SQL Server (T-SQL).
 ============================================================================
*/

-- ============================================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ============================================================================
IF DB_ID(N'BITSAC') IS NULL
BEGIN
    CREATE DATABASE [BITSAC];
    PRINT 'Base de datos BITSAC creada.';
END
GO

USE [BITSAC];
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
GO

-- ============================================================================
-- 2. TABLAS DE CATÁLOGOS MAESTROS
-- ============================================================================

-- 2.1 dbo.catalogos
IF OBJECT_ID(N'dbo.catalogos', N'U') IS NULL
CREATE TABLE dbo.catalogos (
    id              INT IDENTITY(1,1) NOT NULL,
    codigo          NVARCHAR(80)  NOT NULL,
    nombre          NVARCHAR(120) NOT NULL,
    descripcion     NVARCHAR(255) NULL,
    estado          BIT NOT NULL CONSTRAINT DF_catalogos_estado DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_catalogos_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_catalogos PRIMARY KEY (id),
    CONSTRAINT UQ_catalogos_codigo UNIQUE (codigo)
);
GO

-- 2.2 dbo.catalogo_detalles
IF OBJECT_ID(N'dbo.catalogo_detalles', N'U') IS NULL
CREATE TABLE dbo.catalogo_detalles (
    id                  INT IDENTITY(1,1) NOT NULL,
    catalogo_id         INT NOT NULL,
    codigo              NVARCHAR(80)  NOT NULL,
    nombre              NVARCHAR(160) NOT NULL,
    descripcion         NVARCHAR(255) NULL,
    orden               INT NOT NULL CONSTRAINT DF_catalogo_detalles_orden DEFAULT (0),
    asignar_encargado   BIT NOT NULL CONSTRAINT DF_catalogo_detalles_asignar_encargado DEFAULT (0),
    estado              BIT NOT NULL CONSTRAINT DF_catalogo_detalles_estado DEFAULT (1),
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_catalogo_detalles_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_catalogo_detalles PRIMARY KEY (id),
    CONSTRAINT FK_catalogo_detalles_catalogos FOREIGN KEY (catalogo_id) REFERENCES dbo.catalogos(id),
    CONSTRAINT UQ_catalogo_detalles_codigo UNIQUE (catalogo_id, codigo)
);
GO

-- 2.3 dbo.grados
IF OBJECT_ID(N'dbo.grados', N'U') IS NULL
CREATE TABLE dbo.grados (
    id                  INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(160) NOT NULL,
    activo              BIT NOT NULL CONSTRAINT DF_grados_activo DEFAULT (1),
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_grados_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_grados PRIMARY KEY (id)
);
GO

-- 2.4 dbo.rutas
IF OBJECT_ID(N'dbo.rutas', N'U') IS NULL
CREATE TABLE dbo.rutas (
    id                  INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(180) NOT NULL,
    distrito_id         INT NULL,
    turno_id            INT NULL,
    hora_inicio         TIME(0) NULL,
    hora_fin            TIME(0) NULL,
    asignar_encargado   BIT NOT NULL CONSTRAINT DF_rutas_asignar_encargado DEFAULT (0),
    activo              BIT NOT NULL CONSTRAINT DF_rutas_activo DEFAULT (1),
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_rutas_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_rutas PRIMARY KEY (id),
    CONSTRAINT FK_rutas_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 2.5 dbo.turnos
IF OBJECT_ID(N'dbo.turnos', N'U') IS NULL
CREATE TABLE dbo.turnos (
    id                  INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(120) NOT NULL,
    hora_inicio         TIME(0) NOT NULL,
    hora_fin            TIME(0) NOT NULL,
    activo              BIT NOT NULL CONSTRAINT DF_turnos_activo DEFAULT (1),
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_turnos_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_turnos PRIMARY KEY (id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE name = 'FK_rutas_turno' AND parent_object_id = OBJECT_ID('dbo.rutas'))
    ALTER TABLE dbo.rutas
        ADD CONSTRAINT FK_rutas_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id);
GO

PRINT 'Tablas de catalogos creadas.';
GO


-- ============================================================================
-- 3. TABLAS DE SEGURIDAD / RBAC
-- ============================================================================

-- 3.1 dbo.roles
IF OBJECT_ID(N'dbo.roles', N'U') IS NULL
CREATE TABLE dbo.roles (
    id                  INT IDENTITY(1,1) NOT NULL,
    nombre              NVARCHAR(80) NOT NULL,
    descripcion         NVARCHAR(255) NULL,
    activo              BIT NOT NULL CONSTRAINT DF_roles_activo DEFAULT (1),
    codigo              NVARCHAR(80) NULL,
    rol_padre_id        INT NULL,
    pagina_inicial      NVARCHAR(200) NULL,
    nivel_jerarquico    INT NOT NULL CONSTRAINT DF_roles_nivel DEFAULT (0),
    color_identificativo NVARCHAR(20) NULL,
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_roles_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_roles PRIMARY KEY (id),
    CONSTRAINT UQ_roles_nombre UNIQUE (nombre),
    CONSTRAINT FK_roles_rol_padre FOREIGN KEY (rol_padre_id) REFERENCES dbo.roles(id)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_roles_codigo' AND object_id = OBJECT_ID('dbo.roles'))
    CREATE UNIQUE INDEX UQ_roles_codigo ON dbo.roles (codigo) WHERE codigo IS NOT NULL;
GO

-- 3.2 dbo.permisos
IF OBJECT_ID(N'dbo.permisos', N'U') IS NULL
CREATE TABLE dbo.permisos (
    id              INT IDENTITY(1,1) NOT NULL,
    codigo          NVARCHAR(120) NOT NULL,
    descripcion     NVARCHAR(255) NULL,
    modulo          NVARCHAR(80) NOT NULL,
    recurso         NVARCHAR(80) NULL,
    accion          NVARCHAR(80) NULL,
    activo          BIT NOT NULL CONSTRAINT DF_permisos_activo DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_permisos_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_permisos PRIMARY KEY (id),
    CONSTRAINT UQ_permisos_codigo UNIQUE (codigo)
);
GO

-- 3.3 dbo.rol_permiso
IF OBJECT_ID(N'dbo.rol_permiso', N'U') IS NULL
CREATE TABLE dbo.rol_permiso (
    id                  INT IDENTITY(1,1) NOT NULL,
    rol_id              INT NOT NULL,
    permiso_id          INT NOT NULL,
    permitido           BIT NOT NULL CONSTRAINT DF_rol_permiso_permitido DEFAULT (1),
    heredado            BIT NOT NULL CONSTRAINT DF_rol_permiso_heredado DEFAULT (0),
    fecha_asignacion    DATETIME2 NOT NULL CONSTRAINT DF_rol_permiso_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_rol_permiso PRIMARY KEY (id),
    CONSTRAINT FK_rol_permiso_roles FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_rol_permiso_permisos FOREIGN KEY (permiso_id) REFERENCES dbo.permisos(id),
    CONSTRAINT UQ_rol_permiso UNIQUE (rol_id, permiso_id)
);
GO

-- 3.4 dbo.modulos_sistema
IF OBJECT_ID(N'dbo.modulos_sistema', N'U') IS NULL
CREATE TABLE dbo.modulos_sistema (
    id              INT IDENTITY(1,1) NOT NULL,
    codigo          NVARCHAR(80) NOT NULL,
    nombre          NVARCHAR(120) NOT NULL,
    ruta            NVARCHAR(200) NULL,
    icono           NVARCHAR(80) NULL,
    plataforma      NVARCHAR(20) NOT NULL CONSTRAINT DF_modulos_plataforma DEFAULT ('ambos'),
    orden_global    INT NOT NULL CONSTRAINT DF_modulos_orden DEFAULT (0),
    tiene_submenus  BIT NOT NULL CONSTRAINT DF_modulos_submenus DEFAULT (0),
    estado          BIT NOT NULL CONSTRAINT DF_modulos_estado DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_modulos_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_modulos_sistema PRIMARY KEY (id),
    CONSTRAINT UQ_modulos_codigo UNIQUE (codigo),
    CONSTRAINT CK_modulos_plataforma CHECK (plataforma IN ('web','movil','ambos'))
);
GO

-- 3.5 dbo.rol_menu_configuracion
IF OBJECT_ID(N'dbo.rol_menu_configuracion', N'U') IS NULL
CREATE TABLE dbo.rol_menu_configuracion (
    id                  INT IDENTITY(1,1) NOT NULL,
    rol_id              INT NOT NULL,
    modulo_id           INT NOT NULL,
    modulo_padre_id     INT NULL,
    grupo               NVARCHAR(80) NULL,
    nombre_visual       NVARCHAR(120) NULL,
    icono_visual        NVARCHAR(80) NULL,
    orden               INT NOT NULL CONSTRAINT DF_rol_menu_orden DEFAULT (0),
    visible             BIT NOT NULL CONSTRAINT DF_rol_menu_visible DEFAULT (1),
    habilitado          BIT NOT NULL CONSTRAINT DF_rol_menu_habilitado DEFAULT (1),
    expandido           BIT NOT NULL CONSTRAINT DF_rol_menu_expandido DEFAULT (0),
    pagina_inicial      BIT NOT NULL CONSTRAINT DF_rol_menu_inicio DEFAULT (0),
    primera_opcion      BIT NOT NULL CONSTRAINT DF_rol_menu_primera DEFAULT (0),
    mostrar_badge       BIT NOT NULL CONSTRAINT DF_rol_menu_badge DEFAULT (0),
    color_badge         NVARCHAR(20) NULL,
    mostrar_vacio       BIT NOT NULL CONSTRAINT DF_rol_menu_vacio DEFAULT (1),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_rol_menu_configuracion PRIMARY KEY (id),
    CONSTRAINT FK_rol_menu_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_rol_menu_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
    CONSTRAINT FK_rol_menu_modulo_padre FOREIGN KEY (modulo_padre_id) REFERENCES dbo.modulos_sistema(id),
    CONSTRAINT UQ_rol_menu UNIQUE (rol_id, modulo_id)
);
GO

-- 3.6 dbo.campos_sistema
IF OBJECT_ID(N'dbo.campos_sistema', N'U') IS NULL
CREATE TABLE dbo.campos_sistema (
    id              INT IDENTITY(1,1) NOT NULL,
    modulo_id       INT NOT NULL,
    codigo          NVARCHAR(120) NOT NULL,
    nombre          NVARCHAR(200) NOT NULL,
    tipo_dato       NVARCHAR(40) NOT NULL CONSTRAINT DF_campos_tipo DEFAULT ('texto'),
    clasificacion   NVARCHAR(40) NOT NULL CONSTRAINT DF_campos_clasificacion DEFAULT ('general'),
    estado          BIT NOT NULL CONSTRAINT DF_campos_estado DEFAULT (1),
    CONSTRAINT PK_campos_sistema PRIMARY KEY (id),
    CONSTRAINT FK_campos_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
    CONSTRAINT UQ_campos_modulo_codigo UNIQUE (modulo_id, codigo),
    CONSTRAINT CK_campos_tipo CHECK (tipo_dato IN ('texto','numero','fecha','email','telefono')),
    CONSTRAINT CK_campos_clasificacion CHECK (clasificacion IN ('general','sensible','medica','disciplinaria'))
);
GO

-- 3.7 dbo.rol_campos_permisos
IF OBJECT_ID(N'dbo.rol_campos_permisos', N'U') IS NULL
CREATE TABLE dbo.rol_campos_permisos (
    id              INT IDENTITY(1,1) NOT NULL,
    rol_id          INT NOT NULL,
    campo_id        INT NOT NULL,
    nivel_acceso    NVARCHAR(20) NOT NULL CONSTRAINT DF_rol_campos_acceso DEFAULT ('oculto'),
    enmascarado     BIT NOT NULL CONSTRAINT DF_rol_campos_mascara DEFAULT (0),
    fecha_asignacion DATETIME2 NOT NULL CONSTRAINT DF_rol_campos_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_rol_campos_permisos PRIMARY KEY (id),
    CONSTRAINT FK_rol_campos_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_rol_campos_campo FOREIGN KEY (campo_id) REFERENCES dbo.campos_sistema(id),
    CONSTRAINT UQ_rol_campos UNIQUE (rol_id, campo_id),
    CONSTRAINT CK_rol_campos_acceso CHECK (nivel_acceso IN ('oculto','lectura','editable','obligatorio'))
);
GO

-- 3.8 dbo.rol_alcance_datos
IF OBJECT_ID(N'dbo.rol_alcance_datos', N'U') IS NULL
CREATE TABLE dbo.rol_alcance_datos (
    id              INT IDENTITY(1,1) NOT NULL,
    rol_id          INT NOT NULL,
    modulo_id       INT NOT NULL,
    tipo_alcance    NVARCHAR(40) NOT NULL,
    configuracion_json NVARCHAR(MAX) NULL,
    fecha_asignacion DATETIME2 NOT NULL CONSTRAINT DF_rol_alcance_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_rol_alcance_datos PRIMARY KEY (id),
    CONSTRAINT FK_rol_alcance_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_rol_alcance_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
    CONSTRAINT UQ_rol_alcance UNIQUE (rol_id, modulo_id),
    CONSTRAINT CK_rol_alcance_tipo CHECK (tipo_alcance IN ('propio','area','equipo','turno','distrito','creado_por_usuario','asignado_usuario','global','personalizado'))
);
GO

-- 3.9 dbo.rol_condiciones
IF OBJECT_ID(N'dbo.rol_condiciones', N'U') IS NULL
CREATE TABLE dbo.rol_condiciones (
    id              INT IDENTITY(1,1) NOT NULL,
    rol_id          INT NOT NULL,
    modulo_id       INT NULL,
    campo           NVARCHAR(120) NOT NULL,
    operador        NVARCHAR(20) NOT NULL,
    valor           NVARCHAR(500) NULL,
    agrupador       NVARCHAR(10) NULL,
    estado          BIT NOT NULL CONSTRAINT DF_rol_cond_estado DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_rol_cond_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_rol_condiciones PRIMARY KEY (id),
    CONSTRAINT FK_rol_cond_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_rol_cond_modulo FOREIGN KEY (modulo_id) REFERENCES dbo.modulos_sistema(id),
    CONSTRAINT CK_rol_cond_operador CHECK (operador IN ('igual','diferente','contiene','en','mayor','menor','verdadero','falso','vacio','no_vacio')),
    CONSTRAINT CK_rol_cond_agrupador CHECK (agrupador IS NULL OR agrupador IN ('AND','OR'))
);
GO

-- 3.10 dbo.versiones_configuracion_roles
IF OBJECT_ID(N'dbo.versiones_configuracion_roles', N'U') IS NULL
CREATE TABLE dbo.versiones_configuracion_roles (
    id                  BIGINT IDENTITY(1,1) NOT NULL,
    rol_id              INT NOT NULL,
    version             INT NOT NULL,
    estado              NVARCHAR(20) NOT NULL CONSTRAINT DF_versiones_estado DEFAULT ('borrador'),
    configuracion_json  NVARCHAR(MAX) NOT NULL,
    comentario          NVARCHAR(500) NULL,
    creado_por          INT NOT NULL,
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_versiones_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_versiones_configuracion_roles PRIMARY KEY (id),
    CONSTRAINT FK_versiones_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT UQ_versiones_rol_version UNIQUE (rol_id, version),
    CONSTRAINT CK_versiones_estado CHECK (estado IN ('borrador','publicado','restaurado'))
);
GO

-- 3.11 dbo.auditoria_roles_permisos
IF OBJECT_ID(N'dbo.auditoria_roles_permisos', N'U') IS NULL
CREATE TABLE dbo.auditoria_roles_permisos (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id      INT NOT NULL,
    accion          NVARCHAR(40) NOT NULL,
    rol_afectado_id INT NULL,
    valor_anterior  NVARCHAR(MAX) NULL,
    valor_nuevo     NVARCHAR(MAX) NULL,
    ip              NVARCHAR(80) NULL,
    dispositivo     NVARCHAR(200) NULL,
    fecha           DATETIME2 NOT NULL CONSTRAINT DF_aud_roles_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_auditoria_roles_permisos PRIMARY KEY (id),
    CONSTRAINT FK_aud_roles_rol FOREIGN KEY (rol_afectado_id) REFERENCES dbo.roles(id),
    CONSTRAINT CK_aud_roles_accion CHECK (accion IN ('crear_rol','editar_rol','desactivar_rol','eliminar_rol','asignar_permiso','quitar_permiso','publicar_config','guardar_borrador','restaurar_version','asignar_usuario','quitar_usuario'))
);
GO

-- 3.12 dbo.auditoria (general)
IF OBJECT_ID(N'dbo.auditoria', N'U') IS NULL
CREATE TABLE dbo.auditoria (
    id                BIGINT IDENTITY(1,1) NOT NULL,
    usuario_id        INT NULL,
    accion            NVARCHAR(80) NOT NULL,
    modulo            NVARCHAR(80) NOT NULL,
    tabla_afectada    NVARCHAR(120) NULL,
    registro_id       NVARCHAR(80) NULL,
    metodo            NVARCHAR(12) NOT NULL,
    endpoint          NVARCHAR(500) NOT NULL,
    ip                NVARCHAR(80) NULL,
    user_agent        NVARCHAR(500) NULL,
    datos_anteriores  NVARCHAR(MAX) NULL,
    datos_nuevos      NVARCHAR(MAX) NULL,
    fecha_creacion    DATETIME2 NOT NULL CONSTRAINT DF_auditoria_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_auditoria PRIMARY KEY (id)
);
GO

PRINT 'Tablas de seguridad creadas.';
GO


-- ============================================================================
-- 4. TABLAS BASE Y DE NEGOCIO
-- ============================================================================

-- 4.1 dbo.personal
IF OBJECT_ID(N'dbo.personal', N'U') IS NULL
CREATE TABLE dbo.personal (
    id                       INT IDENTITY(1,1) NOT NULL,
    cedula                   NVARCHAR(20)  NOT NULL,
    nombres                  NVARCHAR(120) NOT NULL,
    apellidos                NVARCHAR(120) NOT NULL,
    correo_institucional     NVARCHAR(180) NULL,
    telefono                 NVARCHAR(30)  NULL,
    fecha_nacimiento         DATE NULL,
    fecha_ingreso            DATE NULL,
    cargo_id                 INT NULL,
    area_id                  INT NULL,
    grupo_id                 INT NULL,
    jornada_id               INT NULL,
    rol_id                   INT NULL,
    grado_id                 INT NULL,
    estado_personal_id       INT NULL,
    funcion_operativa_id     INT NULL,
    tipo_rotacion_id         INT NULL,
    password_hash            NVARCHAR(255) NULL,
    foto_perfil_url          NVARCHAR(MAX) NULL,
    total_cartillas_generadas INT NOT NULL CONSTRAINT DF_personal_total_cartillas_generadas DEFAULT (0),
    activo                   BIT NOT NULL CONSTRAINT DF_personal_activo DEFAULT (1),
    fecha_creacion           DATETIME2 NOT NULL CONSTRAINT DF_personal_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion      DATETIME2 NULL,
    CONSTRAINT PK_personal PRIMARY KEY (id),
    CONSTRAINT UQ_personal_cedula UNIQUE (cedula),
    CONSTRAINT FK_personal_rol FOREIGN KEY (rol_id) REFERENCES dbo.roles(id),
    CONSTRAINT FK_personal_grado FOREIGN KEY (grado_id) REFERENCES dbo.grados(id),
    CONSTRAINT FK_personal_cargo FOREIGN KEY (cargo_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_area FOREIGN KEY (area_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_grupo FOREIGN KEY (grupo_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_jornada FOREIGN KEY (jornada_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_estado FOREIGN KEY (estado_personal_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_funcion FOREIGN KEY (funcion_operativa_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_personal_rotacion FOREIGN KEY (tipo_rotacion_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 4.2 dbo.eventos
IF OBJECT_ID(N'dbo.eventos', N'U') IS NULL
CREATE TABLE dbo.eventos (
    id               INT IDENTITY(1,1) NOT NULL,
    titulo           NVARCHAR(220) NOT NULL,
    tipo_evento_id   INT NULL,
    fecha_inicio     DATETIME NULL,
    fecha_fin        DATETIME NULL,
    fecha            DATE NULL,
    lugar            NVARCHAR(300) NULL,
    descripcion      NVARCHAR(MAX) NULL,
    estado_evento_id INT NULL,
    estado           NVARCHAR(30) NULL,
    prioridad        NVARCHAR(30) NULL,
    imagen_url       NVARCHAR(MAX) NULL,
    pdf_nombre       NVARCHAR(255) NULL,
    pdf_url          NVARCHAR(MAX) NULL,
    notificar        BIT NOT NULL CONSTRAINT DF_eventos_notificar DEFAULT (1),
    creado_por       INT NULL,
    fecha_creacion   DATETIME2 NOT NULL CONSTRAINT DF_eventos_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_eventos PRIMARY KEY (id),
    CONSTRAINT FK_eventos_tipo FOREIGN KEY (tipo_evento_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_eventos_estado FOREIGN KEY (estado_evento_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_eventos_creador FOREIGN KEY (creado_por) REFERENCES dbo.personal(id)
);
GO

-- 4.3 dbo.evento_personal
IF OBJECT_ID(N'dbo.evento_personal', N'U') IS NULL
CREATE TABLE dbo.evento_personal (
    id                      INT IDENTITY(1,1) NOT NULL,
    evento_id               INT NOT NULL,
    personal_id             INT NOT NULL,
    estado_convocatoria_id  INT NULL,
    fecha_convocatoria      DATETIME NULL,
    fecha_asignacion        DATETIME2 NULL,
    fecha_actualizacion     DATETIME2 NULL,
    CONSTRAINT PK_evento_personal PRIMARY KEY (id),
    CONSTRAINT FK_evento_personal_evento FOREIGN KEY (evento_id) REFERENCES dbo.eventos(id) ON DELETE CASCADE,
    CONSTRAINT FK_evento_personal_personal FOREIGN KEY (personal_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_evento_personal_estado FOREIGN KEY (estado_convocatoria_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 4.4 dbo.anuncios
IF OBJECT_ID(N'dbo.anuncios', N'U') IS NULL
CREATE TABLE dbo.anuncios (
    id                  INT IDENTITY(1,1) NOT NULL,
    titulo              NVARCHAR(180) NOT NULL,
    descripcion         NVARCHAR(MAX) NOT NULL,
    prioridad           NVARCHAR(30) NOT NULL CONSTRAINT DF_anuncios_prioridad DEFAULT ('Normal'),
    imagen_nombre       NVARCHAR(255) NULL,
    imagen_url          NVARCHAR(MAX) NULL,
    fecha_publicacion   DATETIME NOT NULL CONSTRAINT DF_anuncios_fecha_publicacion DEFAULT (GETDATE()),
    fecha_expiracion    DATETIME NULL,
    publicado           BIT NOT NULL CONSTRAINT DF_anuncios_publicado DEFAULT (1),
    notificar           BIT NOT NULL CONSTRAINT DF_anuncios_notificar DEFAULT (1),
    creado_por          INT NULL,
    fecha_creacion      DATETIME NOT NULL CONSTRAINT DF_anuncios_fecha_creacion DEFAULT (GETDATE()),
    fecha_actualizacion DATETIME NULL,
    CONSTRAINT PK_anuncios PRIMARY KEY (id)
);
GO

-- 4.5 dbo.anuncio_personal
IF OBJECT_ID(N'dbo.anuncio_personal', N'U') IS NULL
CREATE TABLE dbo.anuncio_personal (
    id               INT IDENTITY(1,1) NOT NULL,
    anuncio_id       INT NOT NULL,
    personal_id      INT NOT NULL,
    fecha_asignacion DATETIME NOT NULL CONSTRAINT DF_anuncio_personal_fecha DEFAULT (GETDATE()),
    fecha_visto      DATETIME NULL,
    CONSTRAINT PK_anuncio_personal PRIMARY KEY (id),
    CONSTRAINT FK_anuncio_personal_anuncio FOREIGN KEY (anuncio_id) REFERENCES dbo.anuncios(id) ON DELETE CASCADE
);
GO

-- 4.6 dbo.configuracion_institucional
IF OBJECT_ID(N'dbo.configuracion_institucional', N'U') IS NULL
CREATE TABLE dbo.configuracion_institucional (
    id            INT IDENTITY(1,1) NOT NULL,
    clave         NVARCHAR(120) NOT NULL,
    valor         NVARCHAR(MAX) NULL,
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_config_institucional_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_configuracion_institucional PRIMARY KEY (id),
    CONSTRAINT UQ_config_institucional_clave UNIQUE (clave)
);
GO

-- ============================================================================
-- 5. TABLAS DE MOVILIDAD (MÓVILES Y EAS ASIGNADAS)
-- ============================================================================

-- 5.1 dbo.moviles
IF OBJECT_ID(N'dbo.moviles', N'U') IS NULL
CREATE TABLE dbo.moviles (
    id                                  INT IDENTITY(1,1) NOT NULL,
    numero_movil                        NVARCHAR(40) NOT NULL,
    placa                               NVARCHAR(40) NULL,
    tipo_movil_id                       INT NOT NULL,
    estado_movil_id                     INT NOT NULL,
    kilometraje_actual                  INT NOT NULL CONSTRAINT DF_moviles_km_actual DEFAULT (0),
    kilometraje_ultimo_mantenimiento    INT NOT NULL CONSTRAINT DF_moviles_km_mant DEFAULT (0),
    proximo_mantenimiento               AS (kilometraje_ultimo_mantenimiento + 5000) PERSISTED,
    observacion                         NVARCHAR(500) NULL,
    observacion_estado                  NVARCHAR(500) NULL,
    activo                              BIT NOT NULL CONSTRAINT DF_moviles_activo DEFAULT (1),
    fecha_creacion                      DATETIME2 NOT NULL CONSTRAINT DF_moviles_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion                 DATETIME2 NULL,
    CONSTRAINT PK_moviles PRIMARY KEY (id),
    CONSTRAINT UQ_moviles_numero UNIQUE (numero_movil),
    CONSTRAINT CK_moviles_km CHECK (kilometraje_actual >= 0 AND kilometraje_ultimo_mantenimiento >= 0),
    CONSTRAINT FK_moviles_tipo FOREIGN KEY (tipo_movil_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_moviles_estado FOREIGN KEY (estado_movil_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 5.2 Circuitos: jerarquía Distrito -> Circuito -> Rutas
IF OBJECT_ID(N'dbo.circuitos', N'U') IS NULL
CREATE TABLE dbo.circuitos (
    id INT IDENTITY(1,1) NOT NULL,
    distrito_id INT NOT NULL,
    nombre NVARCHAR(180) NOT NULL,
    hora_inicio TIME(0) NULL,
    hora_fin TIME(0) NULL,
    lugar_formacion NVARCHAR(300) NULL,
    consignas NVARCHAR(MAX) NULL,
    observaciones NVARCHAR(MAX) NULL,
    perimetro NVARCHAR(MAX) NULL,
    activo BIT NOT NULL CONSTRAINT DF_circuitos_activo DEFAULT (1),
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_circuitos_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    deleted_at DATETIME2 NULL,
    CONSTRAINT PK_circuitos PRIMARY KEY (id),
    CONSTRAINT FK_circuitos_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_circuitos_distrito_nombre_activo' AND object_id=OBJECT_ID(N'dbo.circuitos'))
    CREATE UNIQUE INDEX UX_circuitos_distrito_nombre_activo ON dbo.circuitos(distrito_id,nombre) WHERE deleted_at IS NULL;
GO

IF OBJECT_ID(N'dbo.circuito_rutas', N'U') IS NULL
CREATE TABLE dbo.circuito_rutas (
    id BIGINT IDENTITY(1,1) NOT NULL,
    circuito_id INT NOT NULL,
    ruta_id INT NOT NULL,
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_circuito_rutas_fecha DEFAULT (SYSDATETIME()),
    deleted_at DATETIME2 NULL,
    CONSTRAINT PK_circuito_rutas PRIMARY KEY (id),
    CONSTRAINT FK_circuito_rutas_circuito FOREIGN KEY (circuito_id) REFERENCES dbo.circuitos(id),
    CONSTRAINT FK_circuito_rutas_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_circuito_rutas_circuito_ruta_activa' AND object_id=OBJECT_ID(N'dbo.circuito_rutas'))
    CREATE UNIQUE INDEX UX_circuito_rutas_circuito_ruta_activa ON dbo.circuito_rutas(circuito_id,ruta_id) WHERE deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_circuito_rutas_ruta_activa' AND object_id=OBJECT_ID(N'dbo.circuito_rutas'))
    CREATE UNIQUE INDEX UX_circuito_rutas_ruta_activa ON dbo.circuito_rutas(ruta_id) WHERE deleted_at IS NULL;
GO

-- 5.2 dbo.movil_mantenimiento
IF OBJECT_ID(N'dbo.movil_mantenimiento', N'U') IS NULL
CREATE TABLE dbo.movil_mantenimiento (
    id                      INT IDENTITY(1,1) NOT NULL,
    movil_id                INT NOT NULL,
    fecha_mantenimiento     DATETIME2 NOT NULL,
    kilometraje             INT NOT NULL,
    descripcion             NVARCHAR(500) NULL,
    tipo_mantenimiento_id   INT NULL,
    activo                  BIT NOT NULL CONSTRAINT DF_movil_mant_activo DEFAULT (1),
    fecha_creacion          DATETIME2 NOT NULL CONSTRAINT DF_movil_mant_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion     DATETIME2 NULL,
    CONSTRAINT PK_movil_mantenimiento PRIMARY KEY (id),
    CONSTRAINT FK_movil_mant_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id),
    CONSTRAINT FK_movil_mant_tipo FOREIGN KEY (tipo_mantenimiento_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 5.3 dbo.eas_estaciones
IF OBJECT_ID(N'dbo.eas_estaciones', N'U') IS NULL
CREATE TABLE dbo.eas_estaciones (
    id                  INT IDENTITY(1,1) NOT NULL,
    codigo              NVARCHAR(40) NOT NULL,
    nombre              NVARCHAR(160) NOT NULL,
    ubicacion           NVARCHAR(160) NULL,
    direccion           NVARCHAR(300) NULL,
    distrito_id         INT NULL,
    activo              BIT NOT NULL CONSTRAINT DF_eas_estaciones_activo DEFAULT (1),
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_eas_estaciones_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_eas_estaciones PRIMARY KEY (id),
    CONSTRAINT UQ_eas_estaciones_codigo UNIQUE (codigo),
    CONSTRAINT FK_eas_estaciones_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

-- 5.4 dbo.movil_eas_asignaciones
IF OBJECT_ID(N'dbo.movil_eas_asignaciones', N'U') IS NULL
CREATE TABLE dbo.movil_eas_asignaciones (
    id                      INT IDENTITY(1,1) NOT NULL,
    eas_id                  INT NOT NULL,
    movil_id                INT NOT NULL,
    fecha_asignacion        DATETIME2 NOT NULL CONSTRAINT DF_movil_eas_fecha DEFAULT (SYSDATETIME()),
    estado_asignacion_id    INT NOT NULL,
    observacion             NVARCHAR(500) NULL,
    activo                  BIT NOT NULL CONSTRAINT DF_movil_eas_activo DEFAULT (1),
    fecha_creacion          DATETIME2 NOT NULL CONSTRAINT DF_movil_eas_fecha_creacion DEFAULT (SYSDATETIME()),
    fecha_actualizacion     DATETIME2 NULL,
    CONSTRAINT PK_movil_eas_asignaciones PRIMARY KEY (id),
    CONSTRAINT FK_movil_eas_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id),
    CONSTRAINT FK_movil_eas_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id),
    CONSTRAINT FK_movil_eas_estado FOREIGN KEY (estado_asignacion_id) REFERENCES dbo.catalogo_detalles(id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_movil_eas_asignacion_activa' AND object_id = OBJECT_ID('dbo.movil_eas_asignaciones'))
    CREATE UNIQUE INDEX UX_movil_eas_asignacion_activa ON dbo.movil_eas_asignaciones (movil_id) WHERE activo = 1;
GO

PRINT 'Tablas de movilidad creadas.';
GO

-- ============================================================================
-- 6. TABLAS DE EAS CENTRAL / CENTRO DE OPERACIONES
-- ============================================================================

-- 6.1 dbo.eas_roles_central
IF OBJECT_ID(N'dbo.eas_roles_central', N'U') IS NULL
CREATE TABLE dbo.eas_roles_central (
    id              INT IDENTITY(1,1) NOT NULL,
    nombre          NVARCHAR(80) NOT NULL,
    activo          BIT NOT NULL CONSTRAINT DF_eas_roles_central_activo DEFAULT (1),
    CONSTRAINT PK_eas_roles_central PRIMARY KEY (id),
    CONSTRAINT UQ_eas_roles_central_nombre UNIQUE (nombre)
);
GO

-- 6.2 dbo.servidores_policiales
IF OBJECT_ID(N'dbo.servidores_policiales', N'U') IS NULL
CREATE TABLE dbo.servidores_policiales (
    id              INT IDENTITY(1,1) NOT NULL,
    eas_id          INT NOT NULL,
    nombre          NVARCHAR(180) NOT NULL,
    activo          BIT NOT NULL CONSTRAINT DF_servidores_policiales_activo DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_servidores_policiales_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_servidores_policiales PRIMARY KEY (id),
    CONSTRAINT FK_servidores_policiales_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id) ON DELETE CASCADE
);
GO

-- 6.3 dbo.eas_direcciones
IF OBJECT_ID(N'dbo.eas_direcciones', N'U') IS NULL
CREATE TABLE dbo.eas_direcciones (
    id              INT IDENTITY(1,1) NOT NULL,
    eas_id          INT NOT NULL,
    direccion       NVARCHAR(300) NOT NULL,
    activo          BIT NOT NULL CONSTRAINT DF_eas_direcciones_activo DEFAULT (1),
    fecha_creacion  DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_eas_direcciones PRIMARY KEY (id),
    CONSTRAINT FK_eas_direcciones_eas FOREIGN KEY (eas_id) REFERENCES dbo.eas_estaciones(id) ON DELETE CASCADE
);
GO

-- 6.4 dbo.lugares_servicio (puntos de servicio georreferenciados)
IF OBJECT_ID(N'dbo.lugares_servicio', N'U') IS NULL
CREATE TABLE dbo.lugares_servicio (
    id                      INT IDENTITY(1,1) NOT NULL,
    ruta_id                 INT NOT NULL,
    nombre                  NVARCHAR(180) NULL,
    descripcion             NVARCHAR(500) NULL,
    direccion_referencial   NVARCHAR(300) NULL,
    direccion               NVARCHAR(300) NULL,
    ubicacion_especifica    NVARCHAR(220) NULL,
    distrito_id             INT NULL,
    tipo_servicio_id        INT NULL,
    turno_id                INT NULL,
    hora_entrada            NVARCHAR(5) NULL,
    hora_salida             NVARCHAR(5) NULL,
    hora_inicio             TIME(0) NULL,
    hora_fin                TIME(0) NULL,
    cantidad_requerida      INT NOT NULL CONSTRAINT DF_lugares_cantidad DEFAULT (1),
    estado_operativo        NVARCHAR(30) NOT NULL CONSTRAINT DF_lugares_estado_op DEFAULT (N'SIN_ASIGNACION'),
    estado                  NVARCHAR(20) NOT NULL CONSTRAINT DF_lugares_estado DEFAULT (N'ACTIVO'),
    consignas               NVARCHAR(500) NULL,
    observacion             NVARCHAR(500) NULL,
    orden_distribucion      INT NOT NULL CONSTRAINT DF_lugares_orden DEFAULT (0),
    latitud                 DECIMAL(10,7) NULL,
    longitud                DECIMAL(10,7) NULL,
    activo                  BIT NOT NULL CONSTRAINT DF_lugares_activo DEFAULT (1),
    creado_por              INT NOT NULL,
    actualizado_por         INT NULL,
    fecha_creacion          DATETIME2 NOT NULL CONSTRAINT DF_lugares_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion     DATETIME2 NULL,
    CONSTRAINT PK_lugares_servicio PRIMARY KEY CLUSTERED (id),
    CONSTRAINT FK_lugares_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
    CONSTRAINT FK_lugares_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_lugares_tipo_servicio FOREIGN KEY (tipo_servicio_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_lugares_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id)
);
GO

-- 6.5 dbo.rutas_geograficas (trazado geográfico de rutas)
IF OBJECT_ID(N'dbo.rutas_geograficas', N'U') IS NULL
CREATE TABLE dbo.rutas_geograficas (
    id                    BIGINT IDENTITY(1,1) NOT NULL,
    distrito_id           INT NOT NULL,
    circuito_id           INT NULL,
    ruta_id               INT NULL,
    nivel_geografico      NVARCHAR(12) NOT NULL CONSTRAINT DF_rutasgeo_nivel DEFAULT (N'RUTA'),
    nombre                NVARCHAR(150) NOT NULL,
    descripcion           NVARCHAR(500) NULL,
    tipo_geometria        NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_tipo DEFAULT (N'lineal'),
    geojson               NVARCHAR(MAX) NULL,
    color                 NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_color DEFAULT (N'#2563EB'),
    grosor                DECIMAL(4,1) NOT NULL CONSTRAINT DF_rutasgeo_grosor DEFAULT (6),
    opacidad              DECIMAL(3,2) NOT NULL CONSTRAINT DF_rutasgeo_opacidad DEFAULT (0.55),
    estado                NVARCHAR(20) NOT NULL CONSTRAINT DF_rutasgeo_estado DEFAULT (N'ACTIVA'),
    creado_por            INT NOT NULL,
    actualizado_por       INT NULL,
    activo                BIT NOT NULL CONSTRAINT DF_rutasgeo_activo DEFAULT (1),
    fecha_creacion        DATETIME2 NOT NULL CONSTRAINT DF_rutasgeo_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion   DATETIME2 NULL,
    CONSTRAINT PK_rutas_geograficas PRIMARY KEY CLUSTERED (id),
    CONSTRAINT FK_rutasgeo_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_rutasgeo_circuito FOREIGN KEY (circuito_id) REFERENCES dbo.circuitos(id),
    CONSTRAINT FK_rutasgeo_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
    CONSTRAINT CK_rutasgeo_nivel_objetivo CHECK (
        (nivel_geografico=N'DISTRITO' AND circuito_id IS NULL AND ruta_id IS NULL) OR
        (nivel_geografico=N'CIRCUITO' AND circuito_id IS NOT NULL AND ruta_id IS NULL) OR
        (nivel_geografico=N'RUTA' AND ruta_id IS NOT NULL)
    )
);
CREATE UNIQUE INDEX UX_rutasgeo_distrito_activo ON dbo.rutas_geograficas(distrito_id) WHERE activo=1 AND nivel_geografico=N'DISTRITO';
CREATE UNIQUE INDEX UX_rutasgeo_circuito_activo ON dbo.rutas_geograficas(circuito_id) WHERE activo=1 AND nivel_geografico=N'CIRCUITO';
CREATE UNIQUE INDEX UX_rutasgeo_ruta_activo ON dbo.rutas_geograficas(ruta_id) WHERE activo=1 AND nivel_geografico=N'RUTA';
GO

PRINT 'Tablas de EAS central creadas.';
GO

-- ============================================================================
-- 7. TABLAS DE CARTILLAS, INSIGNIAS Y TEMPORALES
-- ============================================================================

-- 7.1 dbo.cartillas_generadas
IF OBJECT_ID(N'dbo.cartillas_generadas', N'U') IS NULL
CREATE TABLE dbo.cartillas_generadas (
    id                  INT IDENTITY(1,1) NOT NULL,
    personal_id         INT NOT NULL,
    tipo                NVARCHAR(30) NOT NULL,
    contenido           NVARCHAR(MAX) NULL,
    fecha_generacion    DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_cartillas_generadas PRIMARY KEY (id),
    CONSTRAINT FK_cartillas_generadas_personal FOREIGN KEY (personal_id) REFERENCES dbo.personal(id)
);
GO

-- 7.2 dbo.cartilla_temp_cp
IF OBJECT_ID(N'dbo.cartilla_temp_cp', N'U') IS NULL
CREATE TABLE dbo.cartilla_temp_cp (
    id              INT IDENTITY(1,1) NOT NULL,
    usuario_id      INT NOT NULL,
    nombre_cp       NVARCHAR(200) NULL,
    grado           NVARCHAR(100) NULL,
    unidad          NVARCHAR(200) NULL,
    ubicacion       NVARCHAR(300) NULL,
    fecha_servicio  DATE NULL,
    hora_inicio     TIME(0) NULL,
    hora_fin        TIME(0) NULL,
    fecha_creacion  DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_cartilla_temp_cp PRIMARY KEY (id),
    CONSTRAINT FK_cartilla_temp_cp_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id)
);
GO

-- 7.3 dbo.cartilla_temp_policia
IF OBJECT_ID(N'dbo.cartilla_temp_policia', N'U') IS NULL
CREATE TABLE dbo.cartilla_temp_policia (
    id              INT IDENTITY(1,1) NOT NULL,
    cartilla_cp_id  INT NOT NULL,
    nombre_policia  NVARCHAR(200) NOT NULL,
    cedula          NVARCHAR(20) NULL,
    grado           NVARCHAR(100) NULL,
    puesto          NVARCHAR(200) NULL,
    observaciones   NVARCHAR(500) NULL,
    fecha_creacion  DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    CONSTRAINT PK_cartilla_temp_policia PRIMARY KEY (id),
    CONSTRAINT FK_cartilla_temp_policia_cp FOREIGN KEY (cartilla_cp_id) REFERENCES dbo.cartilla_temp_cp(id) ON DELETE CASCADE
);
GO

-- 7.4 dbo.insignias
IF OBJECT_ID(N'dbo.insignias', N'U') IS NULL
CREATE TABLE dbo.insignias (
    id              INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_insignias PRIMARY KEY,
    codigo          NVARCHAR(80) NOT NULL,
    titulo          NVARCHAR(160) NOT NULL,
    descripcion     NVARCHAR(700) NOT NULL,
    meta_cartillas  INT NOT NULL,
    categoria       NVARCHAR(80) NOT NULL CONSTRAINT DF_insignias_categoria DEFAULT (N'cartillas'),
    icono           NVARCHAR(20) NULL,
    activo          BIT NOT NULL CONSTRAINT DF_insignias_activo DEFAULT (1),
    fecha_creacion  DATETIME2(0) NOT NULL CONSTRAINT DF_insignias_fecha DEFAULT (SYSDATETIME())
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_insignias_codigo' AND object_id = OBJECT_ID('dbo.insignias'))
    CREATE UNIQUE INDEX UX_insignias_codigo ON dbo.insignias (codigo);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_insignias_meta_cartillas' AND object_id = OBJECT_ID('dbo.insignias'))
    CREATE UNIQUE INDEX UX_insignias_meta_cartillas ON dbo.insignias (meta_cartillas);
GO

-- 7.5 dbo.usuario_insignias
IF OBJECT_ID(N'dbo.usuario_insignias', N'U') IS NULL
CREATE TABLE dbo.usuario_insignias (
    id                      INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_usuario_insignias PRIMARY KEY,
    usuario_id              INT NOT NULL,
    insignia_id             INT NOT NULL,
    total_cartillas_al_desbloquear INT NOT NULL,
    fecha_desbloqueo        DATETIME2(0) NOT NULL CONSTRAINT DF_usuario_insignias_fecha_desbloqueo DEFAULT (SYSDATETIME()),
    CONSTRAINT FK_usuario_insignias_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_usuario_insignias_insignia FOREIGN KEY (insignia_id) REFERENCES dbo.insignias(id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_usuario_insignias_usuario_insignia' AND object_id = OBJECT_ID('dbo.usuario_insignias'))
    CREATE UNIQUE INDEX UX_usuario_insignias_usuario_insignia ON dbo.usuario_insignias (usuario_id, insignia_id);
GO

PRINT 'Tablas de cartillas e insignias creadas.';
GO

-- ============================================================================
-- 8. TABLAS DE DISTRIBUCIÓN, TURNOS Y SORTEOS
-- ============================================================================

-- 8.1 dbo.sectores
IF OBJECT_ID(N'dbo.sectores', N'U') IS NULL
CREATE TABLE dbo.sectores (
    id                          INT IDENTITY(1,1) NOT NULL,
    distrito_id                 INT NOT NULL,
    ruta_id                     INT NOT NULL,
    nombre                      NVARCHAR(180) NOT NULL,
    cantidad_agentes_requeridos INT NOT NULL CONSTRAINT DF_sectores_cantidad DEFAULT (1),
    orden_distribucion          INT NOT NULL CONSTRAINT DF_sectores_orden DEFAULT (0),
    activo                      BIT NOT NULL CONSTRAINT DF_sectores_activo DEFAULT (1),
    creado_por                  INT NULL,
    fecha_creacion              DATETIME2 NOT NULL CONSTRAINT DF_sectores_fecha DEFAULT (SYSDATETIME()),
    actualizado_por             INT NULL,
    fecha_actualizacion         DATETIME2 NULL,
    CONSTRAINT PK_sectores PRIMARY KEY (id),
    CONSTRAINT UQ_sectores_ruta_nombre UNIQUE (ruta_id, nombre),
    CONSTRAINT FK_sectores_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_sectores_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
);
GO

-- 8.2 dbo.asignaciones_punto (personal asignado a puntos de servicio)
IF OBJECT_ID(N'dbo.asignaciones_punto', N'U') IS NULL
CREATE TABLE dbo.asignaciones_punto (
    id                  BIGINT IDENTITY(1,1) NOT NULL,
    punto_id            INT NOT NULL,
    personal_id         INT NOT NULL,
    tipo_asignacion     NVARCHAR(40) NOT NULL CONSTRAINT DF_asig_punto_tipo DEFAULT (N'FIJA'),
    fecha_inicio        DATE NOT NULL,
    fecha_fin           DATE NULL,
    turno_id            INT NOT NULL,
    hora_inicio         TIME(0) NOT NULL,
    hora_fin            TIME(0) NOT NULL,
    funcion             NVARCHAR(160) NULL,
    observaciones       NVARCHAR(500) NULL,
    estado              NVARCHAR(30) NOT NULL CONSTRAINT DF_asig_punto_estado DEFAULT (N'ACTIVA'),
    activo              BIT NOT NULL CONSTRAINT DF_asig_punto_activo DEFAULT (1),
    creado_por          INT NOT NULL,
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_asig_punto_fecha DEFAULT (SYSDATETIME()),
    actualizado_por     INT NULL,
    fecha_actualizacion DATETIME2 NULL,
    CONSTRAINT PK_asignaciones_punto PRIMARY KEY (id),
    CONSTRAINT FK_asig_punto_lugar FOREIGN KEY (punto_id) REFERENCES dbo.lugares_servicio(id),
    CONSTRAINT FK_asig_punto_personal FOREIGN KEY (personal_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_asig_punto_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id),
    CONSTRAINT CK_asig_punto_fechas CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);
GO

-- 8.3 dbo.asignaciones_ruta (asignaciones confirmadas por ruta/turno/fecha)
IF OBJECT_ID(N'dbo.asignaciones_ruta', N'U') IS NULL
CREATE TABLE dbo.asignaciones_ruta (
    id                  BIGINT IDENTITY(1,1) NOT NULL,
    agente_id           INT NOT NULL,
    distrito_id         INT NOT NULL,
    ruta_id             INT NOT NULL,
    sector_id           INT NULL,
    lugar_id            INT NULL,
    fecha_asignacion    DATE NOT NULL,
    turno               NVARCHAR(80) NOT NULL,
    hora_inicio         TIME(0) NOT NULL,
    hora_fin            TIME(0) NOT NULL,
    estado              NVARCHAR(30) NOT NULL CONSTRAINT DF_asig_ruta_estado DEFAULT (N'PENDIENTE'),
    tipo_asignacion     NVARCHAR(40) NOT NULL CONSTRAINT DF_asig_ruta_tipo DEFAULT (N'MANUAL'),
    sorteo_id           NVARCHAR(80) NULL,
    asignado_por        INT NOT NULL,
    observacion         NVARCHAR(500) NULL,
    fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_asig_ruta_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL,
    deleted_at          DATETIME2 NULL,
    CONSTRAINT PK_asignaciones_ruta PRIMARY KEY (id),
    CONSTRAINT FK_asig_ruta_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_asig_ruta_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_asig_ruta_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
    CONSTRAINT FK_asig_ruta_lugar_servicio FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id),
    CONSTRAINT CK_asig_ruta_estado CHECK (estado IN (N'PENDIENTE', N'ACTIVA', N'COMPLETADA', N'CANCELADA', N'INACTIVA'))
);
GO

-- 8.4 dbo.sorteos_historial
IF OBJECT_ID(N'dbo.sorteos_historial', N'U') IS NULL
CREATE TABLE dbo.sorteos_historial (
    id                   BIGINT IDENTITY(1,1) NOT NULL,
    sorteo_id            NVARCHAR(80) NOT NULL,
    usuario_id           INT NOT NULL,
    distrito_id          INT NOT NULL,
    ruta_id              INT NOT NULL,
    fecha_servicio       DATE NOT NULL,
    turno                NVARCHAR(80) NOT NULL,
    hora_inicio          TIME(0) NOT NULL,
    hora_fin             TIME(0) NOT NULL,
    sectores_incluidos   NVARCHAR(MAX) NOT NULL,
    agentes_requeridos   INT NOT NULL,
    agentes_disponibles  INT NOT NULL,
    agentes_seleccionados INT NOT NULL,
    agentes_cambiados    INT NOT NULL CONSTRAINT DF_sorteo_cambiados DEFAULT (0),
    agentes_confirmados  INT NOT NULL CONSTRAINT DF_sorteo_confirmados DEFAULT (0),
    veces_sorteo         INT NOT NULL CONSTRAINT DF_sorteo_veces DEFAULT (1),
    resultado            NVARCHAR(30) NOT NULL CONSTRAINT DF_sorteo_resultado DEFAULT (N'CONFIRMADO'),
    motivo_error         NVARCHAR(500) NULL,
    ip                   NVARCHAR(80) NULL,
    fecha_ejecucion      DATETIME2 NOT NULL CONSTRAINT DF_sorteo_fecha DEFAULT (SYSDATETIME()),
    deleted_at           DATETIME2 NULL,
    CONSTRAINT PK_sorteos_historial PRIMARY KEY (id),
    CONSTRAINT CK_sorteo_resultado CHECK (resultado IN (N'CONFIRMADO', N'CANCELADO', N'ERROR', N'PARCIAL'))
);
GO

PRINT 'Tablas de distribución y sorteos creadas.';
GO

-- 8.5 Cabecera y detalle de distribuciones generales por distrito/turno
IF OBJECT_ID(N'dbo.distribuciones_personal', N'U') IS NULL
CREATE TABLE dbo.distribuciones_personal (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribuciones_personal PRIMARY KEY,
    nombre NVARCHAR(220) NOT NULL, fecha_distribucion DATE NOT NULL,
    creado_por INT NOT NULL, distrito_id INT NOT NULL, turno_id INT NOT NULL,
    estado NVARCHAR(30) NOT NULL CONSTRAINT DF_distribuciones_estado DEFAULT (N'BORRADOR'),
    porcentaje_cobertura DECIMAL(5,2) NOT NULL CONSTRAINT DF_distribuciones_cobertura DEFAULT (0),
    total_requerido INT NOT NULL CONSTRAINT DF_distribuciones_requerido DEFAULT (0),
    total_asignado INT NOT NULL CONSTRAINT DF_distribuciones_asignado DEFAULT (0),
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribuciones_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL, eliminado_por INT NULL, deleted_at DATETIME2 NULL,
    CONSTRAINT FK_distribuciones_usuario FOREIGN KEY (creado_por) REFERENCES dbo.personal(id),
    CONSTRAINT FK_distribuciones_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_distribuciones_turno FOREIGN KEY (turno_id) REFERENCES dbo.turnos(id),
    CONSTRAINT FK_distribuciones_eliminado_por FOREIGN KEY (eliminado_por) REFERENCES dbo.personal(id),
    CONSTRAINT CK_distribuciones_estado CHECK (estado IN (N'BORRADOR',N'PARCIAL',N'COMPLETA',N'ELIMINADA')),
    CONSTRAINT CK_distribuciones_cobertura CHECK (porcentaje_cobertura BETWEEN 0 AND 100)
);
GO

IF OBJECT_ID(N'dbo.distribucion_personal_detalle', N'U') IS NULL
CREATE TABLE dbo.distribucion_personal_detalle (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribucion_personal_detalle PRIMARY KEY,
    distribucion_id BIGINT NOT NULL, ruta_id INT NOT NULL, lugar_id INT NOT NULL,
    cantidad_requerida INT NOT NULL, agente_id INT NULL, asignacion_ruta_id BIGINT NULL,
    tipo_asignacion NVARCHAR(40) NULL,
    estado NVARCHAR(30) NOT NULL CONSTRAINT DF_distribucion_detalle_estado DEFAULT (N'PENDIENTE'),
    fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribucion_detalle_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL, deleted_at DATETIME2 NULL,
    CONSTRAINT FK_distribucion_detalle_cabecera FOREIGN KEY (distribucion_id) REFERENCES dbo.distribuciones_personal(id),
    CONSTRAINT FK_distribucion_detalle_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
    CONSTRAINT FK_distribucion_detalle_lugar FOREIGN KEY (lugar_id) REFERENCES dbo.lugares_servicio(id),
    CONSTRAINT FK_distribucion_detalle_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_distribucion_detalle_asignacion FOREIGN KEY (asignacion_ruta_id) REFERENCES dbo.asignaciones_ruta(id),
    CONSTRAINT CK_distribucion_detalle_estado CHECK (estado IN (N'ASIGNADO',N'PENDIENTE',N'CANCELADO'))
);
GO

IF OBJECT_ID(N'dbo.distribucion_encargados', N'U') IS NULL
CREATE TABLE dbo.distribucion_encargados (
    id BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_distribucion_encargados PRIMARY KEY,
    distribucion_id BIGINT NOT NULL, distrito_id INT NOT NULL, ruta_id INT NULL,
    tipo_responsabilidad NVARCHAR(30) NOT NULL, requiere_encargado BIT NOT NULL,
    agente_id INT NULL, tipo_asignacion NVARCHAR(40) NULL,
    estado NVARCHAR(20) NOT NULL CONSTRAINT DF_distribucion_encargados_estado DEFAULT (N'ASIGNADO'),
    creado_por INT NOT NULL, fecha_creacion DATETIME2 NOT NULL CONSTRAINT DF_distribucion_encargados_fecha DEFAULT (SYSDATETIME()),
    fecha_actualizacion DATETIME2 NULL, deleted_at DATETIME2 NULL,
    CONSTRAINT FK_distribucion_encargados_distribucion FOREIGN KEY (distribucion_id) REFERENCES dbo.distribuciones_personal(id),
    CONSTRAINT FK_distribucion_encargados_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
    CONSTRAINT FK_distribucion_encargados_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
    CONSTRAINT FK_distribucion_encargados_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
    CONSTRAINT FK_distribucion_encargados_creador FOREIGN KEY (creado_por) REFERENCES dbo.personal(id),
    CONSTRAINT CK_distribucion_encargados_tipo CHECK (tipo_responsabilidad IN (N'ENCARGADO_DISTRITO',N'ENCARGADO_RUTA')),
    CONSTRAINT CK_distribucion_encargados_consistencia CHECK ((tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND ruta_id IS NULL AND requiere_encargado=1 AND agente_id IS NOT NULL) OR (tipo_responsabilidad=N'ENCARGADO_RUTA' AND ruta_id IS NOT NULL AND ((requiere_encargado=1 AND agente_id IS NOT NULL) OR (requiere_encargado=0 AND agente_id IS NULL))))
);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_encargado_distrito' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE UNIQUE INDEX UX_distribucion_encargado_distrito ON dbo.distribucion_encargados(distribucion_id) WHERE tipo_responsabilidad=N'ENCARGADO_DISTRITO' AND deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name=N'UX_distribucion_encargado_ruta' AND object_id=OBJECT_ID(N'dbo.distribucion_encargados'))
    CREATE UNIQUE INDEX UX_distribucion_encargado_ruta ON dbo.distribucion_encargados(distribucion_id,ruta_id) WHERE tipo_responsabilidad=N'ENCARGADO_RUTA' AND deleted_at IS NULL;
GO

-- ============================================================================
-- 9. TABLAS DE SOPORTE Y REGISTRO DE CAMBIOS
-- ============================================================================

-- 9.1 dbo.alertas_soporte
IF OBJECT_ID(N'dbo.alertas_soporte', N'U') IS NULL
CREATE TABLE dbo.alertas_soporte (
    id                      BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_alertas_soporte PRIMARY KEY,
    codigo_alerta           NVARCHAR(30) NULL,
    titulo                  NVARCHAR(200) NOT NULL,
    descripcion             NVARCHAR(3000) NOT NULL,
    usuario_id              INT NOT NULL,
    usuario_nombre          NVARCHAR(200) NOT NULL,
    rol                     NVARCHAR(100) NULL,
    area                    NVARCHAR(150) NULL,
    modulo                  NVARCHAR(100) NOT NULL,
    prioridad               NVARCHAR(20) NOT NULL CONSTRAINT DF_alertas_prioridad DEFAULT 'Media',
    estado                  NVARCHAR(30) NOT NULL CONSTRAINT DF_alertas_estado DEFAULT 'Nuevo',
    imagen                  NVARCHAR(500) NULL,
    fecha_creacion          DATETIME2 NOT NULL CONSTRAINT DF_alertas_creacion DEFAULT SYSDATETIME(),
    fecha_actualizacion     DATETIME2 NOT NULL CONSTRAINT DF_alertas_actualizacion DEFAULT SYSDATETIME(),
    asignado_a              INT NULL,
    asignado_nombre         NVARCHAR(200) NULL,
    fecha_primera_respuesta DATETIME2 NULL,
    fecha_resolucion        DATETIME2 NULL,
    activo                  BIT NOT NULL CONSTRAINT DF_alertas_activo DEFAULT 1,
    CONSTRAINT CK_alertas_prioridad CHECK (prioridad IN (N'Crítica', N'Alta', N'Media', N'Baja')),
    CONSTRAINT CK_alertas_estado CHECK (estado IN (N'Nuevo', N'En proceso', N'Pendiente', N'Resuelto', N'Cancelado'))
);
GO

-- 9.2 dbo.alertas_soporte_comentarios
IF OBJECT_ID(N'dbo.alertas_soporte_comentarios', N'U') IS NULL
CREATE TABLE dbo.alertas_soporte_comentarios (
    id              BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_alertas_soporte_comentarios PRIMARY KEY,
    alerta_id       BIGINT NOT NULL,
    usuario_id      INT NOT NULL,
    usuario_nombre  NVARCHAR(200) NOT NULL,
    rol             NVARCHAR(100) NULL,
    comentario      NVARCHAR(3000) NOT NULL,
    es_interno      BIT NOT NULL CONSTRAINT DF_alertas_comentario_interno DEFAULT 0,
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_alertas_comentario_fecha DEFAULT SYSDATETIME(),
    CONSTRAINT FK_alertas_soporte_comentarios_alerta FOREIGN KEY (alerta_id) REFERENCES dbo.alertas_soporte(id)
);
GO

-- 9.3 dbo.alertas_soporte_historial
IF OBJECT_ID(N'dbo.alertas_soporte_historial', N'U') IS NULL
CREATE TABLE dbo.alertas_soporte_historial (
    id              BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_alertas_soporte_historial PRIMARY KEY,
    alerta_id       BIGINT NOT NULL,
    usuario_id      INT NOT NULL,
    usuario_nombre  NVARCHAR(200) NOT NULL,
    accion          NVARCHAR(100) NOT NULL,
    valor_anterior  NVARCHAR(300) NULL,
    valor_nuevo     NVARCHAR(300) NULL,
    fecha_creacion  DATETIME2 NOT NULL CONSTRAINT DF_alertas_historial_fecha DEFAULT SYSDATETIME(),
    CONSTRAINT FK_alertas_soporte_historial_alerta FOREIGN KEY (alerta_id) REFERENCES dbo.alertas_soporte(id)
);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_soporte_usuario_fecha')
    CREATE INDEX IX_alertas_soporte_usuario_fecha ON dbo.alertas_soporte(usuario_id, fecha_creacion DESC) INCLUDE (estado, prioridad, modulo, activo);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_soporte_estado_prioridad')
    CREATE INDEX IX_alertas_soporte_estado_prioridad ON dbo.alertas_soporte(activo, estado, prioridad, fecha_creacion DESC) INCLUDE (usuario_id, modulo, asignado_a);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_comentarios_alerta')
    CREATE INDEX IX_alertas_comentarios_alerta ON dbo.alertas_soporte_comentarios(alerta_id, fecha_creacion);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_alertas_historial_alerta')
    CREATE INDEX IX_alertas_historial_alerta ON dbo.alertas_soporte_historial(alerta_id, fecha_creacion);
GO

UPDATE dbo.alertas_soporte
SET codigo_alerta = CONCAT('ALT-', YEAR(fecha_creacion), '-', RIGHT('000000' + CONVERT(VARCHAR(20), id), 6))
WHERE codigo_alerta IS NULL;
GO

-- 9.4 dbo.registro_cambios (bitácora de cambios del sistema)
IF OBJECT_ID(N'dbo.registro_cambios', N'U') IS NULL
CREATE TABLE dbo.registro_cambios (
    id              BIGINT IDENTITY(1,1) NOT NULL,
    fecha_cambio    DATETIME2 NOT NULL DEFAULT (SYSDATETIME()),
    descripcion     NVARCHAR(MAX) NULL,
    modulo          NVARCHAR(80) NULL,
    estado          NVARCHAR(30) NULL,
    CONSTRAINT PK_registro_cambios PRIMARY KEY (id)
);
GO

PRINT 'Tablas de soporte creadas.';
GO

-- ============================================================================
-- 10. VISTAS
-- ============================================================================

-- 10.1 dbo.vw_personal_detalle (vista base para personal)
IF OBJECT_ID(N'dbo.vw_personal_detalle', N'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_detalle;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_detalle AS
SELECT
    p.id,
    p.cedula,
    p.nombres,
    p.apellidos,
    p.correo_institucional,
    p.telefono,
    p.fecha_nacimiento,
    p.fecha_ingreso,
    ISNULL(r.nombre, ''SIN ROL'') AS rol,
    ISNULL(r.id, 0) AS rol_id,
    ISNULL(ep.nombre, ''SIN ESTADO'') AS estado_personal,
    ISNULL(ep.id, 0) AS estado_personal_id,
    ISNULL(p.activo, 1) AS activo,
    LTRIM(RTRIM(ISNULL(p.nombres, '''') + '' '' + ISNULL(p.apellidos, ''''))) AS nombre_completo
FROM dbo.personal p
LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id;
');
GO

-- 10.2 dbo.vw_personal (compatibilidad antigua)
IF OBJECT_ID(N'dbo.vw_personal', N'V') IS NOT NULL
    DROP VIEW dbo.vw_personal;
GO

EXEC ('
CREATE VIEW dbo.vw_personal AS
SELECT * FROM dbo.vw_personal_detalle;
');
GO

-- 10.3 dbo.vw_personal_operativo
IF OBJECT_ID(N'dbo.vw_personal_operativo', N'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_operativo;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_operativo AS
SELECT * FROM dbo.vw_personal_detalle WHERE activo = 1;
');
GO

-- 10.4 dbo.vw_personal_disponible
IF OBJECT_ID(N'dbo.vw_personal_disponible', N'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_disponible;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_disponible AS
SELECT * FROM dbo.vw_personal_detalle WHERE activo = 1;
');
GO

-- 10.5 dbo.vw_personal_disponible_sin_evento
IF OBJECT_ID(N'dbo.vw_personal_disponible_sin_evento', N'V') IS NOT NULL
    DROP VIEW dbo.vw_personal_disponible_sin_evento;
GO

EXEC ('
CREATE VIEW dbo.vw_personal_disponible_sin_evento AS
SELECT * FROM dbo.vw_personal_detalle WHERE activo = 1;
');
GO

-- 10.6 dbo.vw_moviles_mantenimiento
IF OBJECT_ID(N'dbo.vw_moviles_mantenimiento', N'V') IS NOT NULL
    DROP VIEW dbo.vw_moviles_mantenimiento;
GO

EXEC ('
CREATE VIEW dbo.vw_moviles_mantenimiento AS
SELECT
    m.id,
    m.numero_movil,
    m.placa,
    tm.nombre AS tipo,
    em.nombre AS estado,
    m.kilometraje_actual,
    m.kilometraje_ultimo_mantenimiento,
    m.proximo_mantenimiento,
    (m.proximo_mantenimiento - m.kilometraje_actual) AS kilometros_restantes,
    CASE
        WHEN m.kilometraje_actual > m.proximo_mantenimiento THEN N''KILOMETRAJE_EXCEDIDO''
        WHEN (m.proximo_mantenimiento - m.kilometraje_actual) <= 500 THEN N''EN_ESPERA''
        ELSE N''MANTENIMIENTO_COMPLETADO''
    END AS estado_mantenimiento,
    m.activo
FROM dbo.moviles m
INNER JOIN dbo.catalogo_detalles tm ON tm.id = m.tipo_movil_id
INNER JOIN dbo.catalogo_detalles em ON em.id = m.estado_movil_id;
');
GO

PRINT 'Vistas creadas.';
GO

-- ============================================================================
-- 11. ÍNDICES DE RENDIMIENTO
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_eventos_fecha' AND object_id = OBJECT_ID('dbo.eventos'))
    CREATE INDEX IX_eventos_fecha ON dbo.eventos (fecha_inicio);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_personal_cedula' AND object_id = OBJECT_ID('dbo.personal'))
    CREATE INDEX IX_personal_cedula ON dbo.personal (cedula);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_personal_rol' AND object_id = OBJECT_ID('dbo.personal'))
    CREATE INDEX IX_personal_rol ON dbo.personal (rol_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_anuncios_publicado' AND object_id = OBJECT_ID('dbo.anuncios'))
    CREATE INDEX IX_anuncios_publicado ON dbo.anuncios (publicado, fecha_publicacion);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_cartillas_personal' AND object_id = OBJECT_ID('dbo.cartillas_generadas'))
    CREATE INDEX IX_cartillas_personal ON dbo.cartillas_generadas (personal_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asig_ruta_ruta_fecha' AND object_id = OBJECT_ID('dbo.asignaciones_ruta'))
    CREATE NONCLUSTERED INDEX IX_asig_ruta_ruta_fecha ON dbo.asignaciones_ruta (ruta_id, fecha_asignacion, estado)
    INCLUDE (sector_id, agente_id);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asig_ruta_conflicto' AND object_id = OBJECT_ID('dbo.asignaciones_ruta'))
    CREATE NONCLUSTERED INDEX IX_asig_ruta_conflicto ON dbo.asignaciones_ruta (agente_id, fecha_asignacion, hora_inicio, hora_fin, estado)
    INCLUDE (ruta_id, sector_id, turno);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asignaciones_punto_conflicto' AND object_id = OBJECT_ID('dbo.asignaciones_punto'))
    CREATE NONCLUSTERED INDEX IX_asignaciones_punto_conflicto ON dbo.asignaciones_punto (personal_id, fecha_inicio, fecha_fin, hora_inicio, hora_fin, activo);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_distribucion_fecha_turno' AND object_id = OBJECT_ID('dbo.distribuciones_personal'))
    CREATE UNIQUE INDEX UX_distribucion_fecha_turno ON dbo.distribuciones_personal (distrito_id, turno_id, fecha_distribucion) WHERE deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_distribucion_agente' AND object_id = OBJECT_ID('dbo.distribucion_personal_detalle'))
    CREATE UNIQUE INDEX UX_distribucion_agente ON dbo.distribucion_personal_detalle (distribucion_id, agente_id) WHERE agente_id IS NOT NULL AND deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_distribucion_detalle_lugar' AND object_id = OBJECT_ID('dbo.distribucion_personal_detalle'))
    CREATE INDEX IX_distribucion_detalle_lugar ON dbo.distribucion_personal_detalle (distribucion_id, ruta_id, lugar_id) INCLUDE (agente_id, estado);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_asignacion_ruta_agente_turno' AND object_id = OBJECT_ID('dbo.asignaciones_ruta'))
    CREATE UNIQUE INDEX UX_asignacion_ruta_agente_turno ON dbo.asignaciones_ruta (agente_id, fecha_asignacion, turno) WHERE deleted_at IS NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UX_lugares_coordenadas_activas' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
    CREATE UNIQUE INDEX UX_lugares_coordenadas_activas ON dbo.lugares_servicio (latitud, longitud)
    WHERE activo = 1 AND latitud IS NOT NULL AND longitud IS NOT NULL;
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_lugares_geo_filtros' AND object_id = OBJECT_ID('dbo.lugares_servicio'))
    CREATE INDEX IX_lugares_geo_filtros ON dbo.lugares_servicio (activo, distrito_id, ruta_id, turno_id, estado_operativo)
    INCLUDE (latitud, longitud, nombre, cantidad_requerida);
PRINT 'Indices creados.';
GO


-- ============================================================================
-- 12. DATOS SEMILLA (SEED DATA)
-- ============================================================================

-- 12.1 CATÁLOGOS MAESTROS
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'DISTRITOS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('DISTRITOS', N'Distritos', N'Distritos del casco urbano');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'AREAS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('AREAS', N'Áreas', N'Áreas de trabajo del personal');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'CARGO')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('CARGO', N'Cargos', N'Cargos del personal');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'GRUPOS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('GRUPOS', N'Grupos', N'Grupos operativos (A/B)');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'JORNADAS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('JORNADAS', N'Jornadas', N'Jornadas laborales');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'ESTADOS_PERSONAL')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('ESTADOS_PERSONAL', N'Estados de personal', N'Estados del personal');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'FUNCIONES_OPERATIVAS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('FUNCIONES_OPERATIVAS', N'Funciones Operativas', N'Funciones operativas del personal');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_ROTACION')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('TIPOS_ROTACION', N'Tipos de Rotación', N'Tipos de rotación de turnos');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_MOVIL')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('TIPOS_MOVIL', N'Tipos de Móvil', N'Tipos de móviles de transporte');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'ESTADOS_MOVIL')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('ESTADOS_MOVIL', N'Estados de Móvil', N'Estados operativos de los móviles');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_MANTENIMIENTO')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('TIPOS_MANTENIMIENTO', N'Tipos de Mantenimiento', N'Tipos de mantenimiento de móviles');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'ESTADOS_ASIGNACION_MOVIL')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('ESTADOS_ASIGNACION_MOVIL', N'Estados de Asignación de Móviles', N'Estados de asignación móvil-EAS');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'LUGARES_SERVICIO')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('LUGARES_SERVICIO', N'Lugares de Servicio', N'Lugares de servicio del cuerpo de vigilancia');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_SERVICIO_LUGAR')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('TIPOS_SERVICIO_LUGAR', N'Tipos de Servicio por Lugar', N'Tipos de servicio en un lugar');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'TIPOS_EVENTOS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('TIPOS_EVENTOS', N'Tipos de Eventos', N'Tipos de eventos del módulo Eventos');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'ESTADOS_EVENTOS')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('ESTADOS_EVENTOS', N'Estados de Eventos', N'Estados de los eventos');
IF NOT EXISTS (SELECT 1 FROM dbo.catalogos WHERE codigo = 'ESTADOS_CONVOCATORIA')
    INSERT INTO dbo.catalogos (codigo, nombre, descripcion) VALUES ('ESTADOS_CONVOCATORIA', N'Estados de Convocatoria', N'Estados de la convocatoria de personal');
GO

-- 12.2 Detalles de catálogos base
DECLARE @catalogos_ins TABLE (codigo NVARCHAR(80), detalle_codigo NVARCHAR(80), detalle_nombre NVARCHAR(160), detalle_orden INT);
INSERT INTO @catalogos_ins (codigo, detalle_codigo, detalle_nombre, detalle_orden)
VALUES
('DISTRITOS', '9_OCTUBRE', N'9 de Octubre', 10),
('DISTRITOS', 'MALECON', N'Malecón Simón Bolívar', 20),
('DISTRITOS', 'CENTRO', N'Centro', 30),
('DISTRITOS', 'NORTE', N'Norte', 40),
('DISTRITOS', 'SUR', N'Sur', 50),

('AREAS', 'OPERATIVA', N'Operativa', 10),
('AREAS', 'ADMINISTRACION', N'Administración', 20),
('AREAS', 'COMUNICACIONES', N'Comunicaciones', 30),
('AREAS', 'AGENTE', N'Agente', 40),
('AREAS', 'SEGURIDAD', N'Seguridad', 50),

('GRUPOS', 'GRUPO_A', N'Grupo A', 10),
('GRUPOS', 'GRUPO_B', N'Grupo B', 20),

('JORNADAS', 'DIURNA', N'Diurna', 10),
('JORNADAS', 'NOCTURNA', N'Nocturna', 20),
('JORNADAS', 'ROTATIVA', N'Rotativa', 30),

('ESTADOS_PERSONAL', 'ACTIVO', N'Activo', 10),
('ESTADOS_PERSONAL', 'INACTIVO', N'Inactivo', 20),
('ESTADOS_PERSONAL', 'FRANCO', N'Franco', 30),
('ESTADOS_PERSONAL', 'VACACIONES', N'Vacaciones', 40),
('ESTADOS_PERSONAL', 'SUSPENDIDO', N'Suspendido', 50),
('ESTADOS_PERSONAL', 'PERMISO', N'Permiso', 60),
('ESTADOS_PERSONAL', 'REPOSO_MEDICO', N'Reposo Médico', 70),

('FUNCIONES_OPERATIVAS', 'ENCARGADO', N'Encargado', 10),
('FUNCIONES_OPERATIVAS', 'SUPERVISION', N'Supervisión', 20),
('FUNCIONES_OPERATIVAS', 'ADMINISTRATIVO', N'Administrativo', 30),
('FUNCIONES_OPERATIVAS', 'FILA_PEDESTRE', N'Fila Pedestre', 40),
('FUNCIONES_OPERATIVAS', 'AUXILIAR', N'Auxiliar', 50),

('TIPOS_ROTACION', 'FIJA', N'Fija', 10),
('TIPOS_ROTACION', 'ROTATIVA', N'Rotación', 20),

('TIPOS_MOVIL', 'CAMIONETA', N'Camioneta', 10),
('TIPOS_MOVIL', 'MOTOCICLETA', N'Motocicleta', 20),
('TIPOS_MOVIL', 'BICICLETA', N'Bicicleta', 30),
('TIPOS_MOVIL', 'OTRO', N'Otro', 40),

('ESTADOS_MOVIL', 'OPERATIVO', N'Operativo', 10),
('ESTADOS_MOVIL', 'EN_MANTENIMIENTO', N'En Mantenimiento', 20),
('ESTADOS_MOVIL', 'FUERA_SERVICIO', N'Fuera de Servicio', 30),

('TIPOS_MANTENIMIENTO', 'PREVENTIVO', N'Preventivo', 10),
('TIPOS_MANTENIMIENTO', 'CORRECTIVO', N'Correctivo', 20),

('ESTADOS_ASIGNACION_MOVIL', 'ACTIVA', N'Activa', 10),
('ESTADOS_ASIGNACION_MOVIL', 'INACTIVA', N'Inactiva', 20),

('TIPOS_SERVICIO_LUGAR', 'EAS', N'EAS', 10),
('TIPOS_SERVICIO_LUGAR', 'PEDESTRE', N'Pedestre', 20),
('TIPOS_SERVICIO_LUGAR', 'MOTORIZADO', N'Motorizado', 30),
('TIPOS_SERVICIO_LUGAR', 'CICLISTA', N'Ciclista', 40),
('TIPOS_SERVICIO_LUGAR', 'ADMINISTRATIVO', N'Administrativo', 50),
('TIPOS_SERVICIO_LUGAR', 'AMBIENTE', N'Ambiente', 60),
('TIPOS_SERVICIO_LUGAR', 'K9', N'K9', 70),
('TIPOS_SERVICIO_LUGAR', 'OTRO', N'Otro', 80),

('TIPOS_EVENTOS', 'ACTO_CIVICO', N'Acto Cívico', 10),
('TIPOS_EVENTOS', 'SESION', N'Sesión', 20),
('TIPOS_EVENTOS', 'CULTURAL', N'Cultural', 30),
('TIPOS_EVENTOS', 'DEPORTIVO', N'Deportivo', 40),
('TIPOS_EVENTOS', 'OPERATIVO', N'Operativo', 50),
('TIPOS_EVENTOS', 'OTRO', N'Otro', 60),

('ESTADOS_EVENTOS', 'PROGRAMADO', N'Programado', 10),
('ESTADOS_EVENTOS', 'EN_CURSO', N'En curso', 20),
('ESTADOS_EVENTOS', 'FINALIZADO', N'Finalizado', 30),
('ESTADOS_EVENTOS', 'CANCELADO', N'Cancelado', 40),
('ESTADOS_EVENTOS', 'PENDIENTE', N'Pendiente', 50),

('ESTADOS_CONVOCATORIA', 'CONVOCADO', N'Convocado', 10),
('ESTADOS_CONVOCATORIA', 'CONFIRMADO', N'Confirmado', 20),
('ESTADOS_CONVOCATORIA', 'ASISTIO', N'Asistió', 30),
('ESTADOS_CONVOCATORIA', 'NO_ASISTIO', N'No asistió', 40),
('ESTADOS_CONVOCATORIA', 'RECHAZADO', N'Rechazado', 50);

INSERT INTO dbo.catalogo_detalles (catalogo_id, codigo, nombre, orden)
SELECT c.id, i.detalle_codigo, i.detalle_nombre, i.detalle_orden
FROM @catalogos_ins i
INNER JOIN dbo.catalogos c ON c.codigo = i.codigo
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.catalogo_detalles cd
    WHERE cd.catalogo_id = c.id AND cd.codigo = i.detalle_codigo
);
GO

-- 12.3 GRADOS
IF NOT EXISTS (SELECT 1 FROM dbo.grados)
    INSERT INTO dbo.grados (nombre)
    VALUES
    (N'Agente 1'),
    (N'Agente 2'),
    (N'Agente 3'),
    (N'Agente 4'),
    (N'Sub-Inspector'),
    (N'Inspector'),
    (N'Jefe de Control Municipal');
GO

-- 12.4 TURNOS
IF NOT EXISTS (SELECT 1 FROM dbo.turnos)
    INSERT INTO dbo.turnos (nombre, hora_inicio, hora_fin)
    VALUES
    (N'Matutino', '06:00', '14:30'),
    (N'Vespertino', '14:30', '22:30'),
    (N'Nocturno', '22:30', '06:00');
GO

-- 12.5 ROLES
IF NOT EXISTS (SELECT 1 FROM dbo.roles)
    INSERT INTO dbo.roles (nombre, descripcion, activo, nivel_jerarquico, codigo)
    VALUES
    ('Administrador', 'Control total del sistema', 1, 100, 'admin'),
    ('Operaciones', 'Gestion operativa diaria', 1, 80, 'operaciones'),
    ('Supervisor', 'Encargado de servicio asignado', 1, 60, 'supervisor'),
    ('Inspector', 'Consulta y reporte operativo territorial', 1, 50, 'inspector'),
    ('Agente', 'Usuario operativo basico', 1, 40, 'agente'),
    ('Comunicaciones', 'Gestion del modulo Eventos', 1, 70, 'comunicaciones'),
    ('Consulta', 'Solo lectura general', 1, 10, 'consulta'),
    ('Auditoria', 'Control interno y trazabilidad', 1, 90, 'auditoria'),
    ('Encargado', 'Encargado de operaciones', 1, 55, 'encargado');
GO

-- 12.6 PERMISOS
IF NOT EXISTS (SELECT 1 FROM dbo.permisos)
    INSERT INTO dbo.permisos (codigo, descripcion, modulo)
    VALUES
    ('usuarios.ver','Ver usuarios','usuarios'),('usuarios.crear','Crear usuarios','usuarios'),
    ('usuarios.editar','Editar usuarios','usuarios'),('usuarios.eliminar','Eliminar usuarios','usuarios'),
    ('roles.ver','Ver roles','roles'),('roles.crear','Crear roles','roles'),
    ('roles.editar','Editar roles','roles'),('roles.eliminar','Eliminar roles','roles'),
    ('permisos.ver','Ver permisos','permisos'),
    ('personal.ver','Ver personal','personal'),('personal.ver_asignado','Ver personal asignado','personal'),
    ('personal.crear','Crear personal','personal'),('personal.editar','Editar personal','personal'),
    ('personal.editar_estado','Editar estado de personal','personal'),('personal.eliminar','Eliminar personal','personal'),
    ('servicios.ver','Ver servicios','servicios'),('servicios.ver_asignado','Ver servicios asignados','servicios'),
    ('servicios.crear','Crear servicios','servicios'),('servicios.editar','Editar servicios','servicios'),
    ('servicios.eliminar','Eliminar servicios','servicios'),
    ('servicios.reemplazar_personal','Reemplazar personal de servicio','servicios'),
    ('servicios.aprobar_cambios','Aprobar cambios de servicio','servicios'),
    ('servicios.planificacion_manual','Planificacion manual','servicios'),
    ('servicios.planificacion_automatica','Planificacion automatica','servicios'),
    ('eventos.ver','Ver eventos','eventos'),('eventos.ver_convocado','Ver eventos convocado','eventos'),
    ('eventos.crear','Crear eventos','eventos'),('eventos.editar','Editar eventos','eventos'),
    ('eventos.eliminar','Eliminar eventos','eventos'),('eventos.publicar','Publicar eventos','eventos'),
    ('eventos.convocar','Convocar personal','eventos'),('eventos.adjuntos','Gestionar adjuntos de eventos','eventos'),
    ('eventos.ubicacion','Gestionar ubicacion de eventos','eventos'),('eventos.asistencia','Gestionar asistencia de eventos','eventos'),
    ('eventos.confirmar_asistencia','Confirmar asistencia propia','eventos'),('eventos.reportes','Reportes de eventos','eventos'),
    ('anuncios.ver','Ver anuncios','anuncios'),('anuncios.crear','Crear anuncios','anuncios'),
    ('anuncios.editar','Editar anuncios','anuncios'),('anuncios.eliminar','Eliminar anuncios','anuncios'),
    ('cartillas.ver','Ver cartillas','cartillas'),('cartillas.generar','Generar cartillas','cartillas'),
    ('reportes.ver','Ver reportes','reportes'),('reportes.ver_servicio','Ver reportes de servicio','reportes'),
    ('reportes.exportar','Exportar reportes','reportes'),('reportes.exportar_eventos','Exportar reportes de eventos','reportes'),
    ('novedades.ver','Ver novedades','novedades'),('novedades.crear','Crear novedades','novedades'),
    ('novedades.crear_personal','Crear novedad personal','novedades'),('novedades.editar','Editar novedades','novedades'),
    ('incidencias.ver','Ver incidencias','incidencias'),('incidencias.crear','Crear incidencias','incidencias'),
    ('asistencia.registrar','Registrar asistencia','asistencia'),('asistencia.confirmar','Confirmar asistencia','asistencia'),
    ('perfil.ver','Ver perfil','perfil'),('horario.ver','Ver horario propio','horario'),
    ('servicio.ver_propio','Ver servicio propio','servicios'),
    ('consignas.ver','Ver consignas','consignas'),('sugerencias.crear','Crear sugerencias','sugerencias'),
    ('auditoria.ver','Ver auditoria','auditoria'),('auditoria.detalle','Ver detalle de auditoria','auditoria'),
    ('auditoria.exportar','Exportar auditoria','auditoria'),
    ('bitacoras.ver','Ver bitacoras','bitacoras'),('bitacoras.detalle','Ver detalle de bitacoras','bitacoras'),
    ('estadisticas.ver','Ver estadisticas','estadisticas'),
    ('configuracion.ver','Ver configuracion','configuracion'),('configuracion.editar','Editar configuracion','configuracion'),
    ('moviles.ver','Ver moviles','moviles'),('moviles.crear','Crear moviles','moviles'),
    ('moviles.editar','Editar moviles','moviles'),('moviles.mantenimiento','Gestionar mantenimiento','moviles'),
    ('distribucion.asignar','Administrar asignaciones de personal','distribucion'),
    ('tablero_distribucion.limpiar','Limpiar asignaciones de ruta','tablero'),
    ('rutas_geograficas.gestionar','Gestionar rutas geograficas','rutas_geograficas'),
    ('administracion.ver','Ver modulo administracion','administracion'),
    ('catalogos.ver','Ver catalogos maestros','administracion'),
    ('catalogos.crear','Crear catalogos maestros','administracion'),
    ('catalogos.editar','Editar catalogos maestros','administracion'),
    ('catalogos.estado','Activar o inactivar catalogos maestros','administracion'),
    ('rutas.ver','Ver rutas','administracion'),
    ('rutas.crear','Crear rutas','administracion'),
    ('rutas.editar','Editar rutas','administracion'),
    ('rutas.estado','Activar o inactivar rutas','administracion'),
    ('lugares_servicio.ver','Ver lugares de servicio','administracion'),
    ('lugares_servicio.crear','Crear lugares de servicio','administracion'),
    ('lugares_servicio.editar','Editar lugares de servicio','administracion'),
    ('lugares_servicio.estado','Activar o inactivar lugares de servicio','administracion'),
    ('circuitos.ver','Ver circuitos','administracion'),
    ('circuitos.crear','Crear circuitos','administracion'),
    ('circuitos.editar','Editar circuitos','administracion'),
    ('circuitos.rutas','Asignar y desasignar rutas de circuitos','administracion'),
    ('circuitos.eliminar','Eliminar circuitos','administracion'),
    ('eas.ver','Ver EAS','administracion'),
    ('eas.crear','Crear EAS','administracion'),
    ('eas.editar','Editar EAS','administracion'),
    ('eas.estado','Activar o inactivar EAS','administracion'),
    ('moviles.estado','Activar o inactivar moviles','moviles'),
    ('moviles.asignar','Asignar moviles a EAS','moviles'),
    ('personal.reset_password','Restablecer contrasena de personal','personal'),
    ('anuncios.publicar','Publicar anuncios','anuncios'),
    ('insignias.ver','Ver insignias','insignias'),
    ('dashboard.mantenimiento','Ver alertas de mantenimiento preventivo','dashboard'),
    ('distribucion.ver','Ver distribucion geografica','distribucion'),
    ('distribucion.crear','Crear puntos georreferenciados','distribucion'),
    ('distribucion.editar','Editar puntos georreferenciados','distribucion'),
    ('distribucion.desactivar','Desactivar puntos georreferenciados','distribucion'),
    ('distribucion.catalogos','Crear rutas y sectores desde distribucion','distribucion'),
    ('tablero_distribucion.ver','Ver tablero de distribucion','distribucion'),
    ('tablero_distribucion.asignar','Ejecutar asignacion aleatoria','distribucion'),
    ('tablero_distribucion.configurar','Configurar requerimiento de personal','distribucion'),
    ('tablero_distribucion.eliminar','Eliminar distribuciones de personal','distribucion'),
    ('soporte.ver','Ver alertas de soporte','soporte'),
    ('soporte.comentar','Comentar alertas de soporte','soporte');
GO

-- 12.7 ASIGNACIÓN DE PERMISOS A ROLES
DECLARE @asignaciones2 TABLE (rol NVARCHAR(80), permiso NVARCHAR(120));
INSERT INTO @asignaciones2 (rol, permiso)
SELECT 'Administrador', codigo FROM dbo.permisos;
INSERT INTO @asignaciones2 (rol, permiso) VALUES
('Operaciones','personal.ver'),('Operaciones','personal.editar_estado'),
('Operaciones','servicios.ver'),('Operaciones','servicios.crear'),('Operaciones','servicios.editar'),
('Operaciones','servicios.reemplazar_personal'),('Operaciones','servicios.aprobar_cambios'),
('Operaciones','servicios.planificacion_manual'),('Operaciones','servicios.planificacion_automatica'),
('Operaciones','eventos.ver'),('Operaciones','eventos.crear'),('Operaciones','eventos.editar'),
('Operaciones','anuncios.ver'),('Operaciones','anuncios.crear'),('Operaciones','anuncios.editar'),
('Operaciones','cartillas.ver'),('Operaciones','cartillas.generar'),
('Operaciones','reportes.ver'),('Operaciones','reportes.exportar'),
('Operaciones','novedades.ver'),('Operaciones','novedades.crear'),('Operaciones','novedades.editar'),
('Operaciones','auditoria.ver'),('Operaciones','moviles.ver'),('Operaciones','moviles.editar'),
('Encargado','personal.ver'),('Encargado','personal.editar_estado'),
('Encargado','servicios.ver'),('Encargado','servicios.crear'),('Encargado','servicios.editar'),
('Encargado','servicios.reemplazar_personal'),('Encargado','distribucion.asignar'),
('Encargado','tablero_distribucion.limpiar'),('Encargado','rutas_geograficas.gestionar'),
('Encargado','eventos.ver'),('Encargado','eventos.crear'),('Encargado','eventos.editar'),
('Encargado','anuncios.ver'),('Encargado','cartillas.ver'),('Encargado','cartillas.generar'),
('Encargado','reportes.ver'),('Encargado','reportes.exportar'),
('Supervisor','personal.ver_asignado'),('Supervisor','servicios.ver_asignado'),
('Supervisor','asistencia.registrar'),('Supervisor','asistencia.confirmar'),
('Supervisor','novedades.ver'),('Supervisor','novedades.crear'),
('Supervisor','eventos.ver'),('Supervisor','cartillas.ver'),
('Supervisor','reportes.ver_servicio'),
('Inspector','personal.ver'),('Inspector','servicios.ver'),
('Inspector','novedades.ver'),('Inspector','novedades.crear'),
('Inspector','incidencias.ver'),('Inspector','incidencias.crear'),
('Inspector','eventos.ver'),('Inspector','cartillas.ver'),('Inspector','reportes.ver'),
('Agente','perfil.ver'),('Agente','horario.ver'),('Agente','servicio.ver_propio'),
('Agente','consignas.ver'),('Agente','eventos.ver_convocado'),
('Agente','eventos.confirmar_asistencia'),('Agente','anuncios.ver'),
('Agente','cartillas.ver'),('Agente','sugerencias.crear'),('Agente','novedades.crear_personal'),
('Comunicaciones','eventos.ver'),('Comunicaciones','eventos.crear'),
('Comunicaciones','eventos.editar'),('Comunicaciones','eventos.eliminar'),
('Comunicaciones','eventos.publicar'),('Comunicaciones','eventos.convocar'),
('Comunicaciones','eventos.adjuntos'),('Comunicaciones','eventos.ubicacion'),
('Comunicaciones','eventos.asistencia'),('Comunicaciones','eventos.reportes'),
('Comunicaciones','reportes.exportar_eventos'),
('Consulta','personal.ver'),('Consulta','servicios.ver'),('Consulta','eventos.ver'),
('Consulta','cartillas.ver'),('Consulta','reportes.ver'),
('Auditoria','auditoria.ver'),('Auditoria','auditoria.detalle'),
('Auditoria','auditoria.exportar'),('Auditoria','bitacoras.ver'),
('Auditoria','bitacoras.detalle'),('Auditoria','usuarios.ver'),
('Auditoria','roles.ver'),('Auditoria','permisos.ver'),
('Auditoria','personal.ver'),('Auditoria','servicios.ver'),
('Auditoria','eventos.ver'),('Auditoria','cartillas.ver'),
('Auditoria','reportes.ver'),('Auditoria','novedades.ver');

INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM @asignaciones2 a
INNER JOIN dbo.roles r ON LOWER(r.nombre) = a.rol COLLATE Latin1_General_CI_AS
INNER JOIN dbo.permisos p ON p.codigo = a.permiso
WHERE NOT EXISTS (SELECT 1 FROM dbo.rol_permiso rp WHERE rp.rol_id = r.id AND rp.permiso_id = p.id);
GO

PRINT 'Datos semilla base insertados (catalogos, grados, turnos, roles, permisos).';
GO

-- 12.8 EAS ESTACIONES Y ROLES CENTRAL
IF NOT EXISTS (SELECT 1 FROM dbo.eas_estaciones)
    INSERT INTO dbo.eas_estaciones (codigo, nombre, ubicacion, direccion) VALUES
    ('ECO 1','URDESA','URDESA','AV. VICTOR EMILIO ESTRADA Y CIRCUNVALACION SUR'),
    ('ECO 2','LOMAS DE URDESA','LOMAS DE URDESA','AV. CERROS Y LOMAS DE URDESA'),
    ('ECO 3','KENNEDY VIEJA','KENNEDY VIEJA','AV. FRANCISCO URBINA Y AV. DEL PERIODISTA'),
    ('ECO 4','KENNEDY NUEVA','KENNEDY NUEVA','AV. JOSE SANTIAGO CASTILLO Y VICTOR HUGO'),
    ('ECO 5','FAE/ATARAZANA','FAE/ATARAZANA','AV. AL RAUL COUSIN Y CRNL LUIS LOPES'),
    ('ECO 6','PUERTO SANTA ANA','PUERTO SANTA ANA','PUERTO SANTA ANA'),
    ('ECO 7','SAMANES','SAMANES','AV TEODORO ALVARADO OLEAS'),
    ('ECO 8','PARQUE CENTENARIO','PARQUE CENTENARIO','CALLE LORENZO DE GARAICOA Y VELEZ'),
    ('ECO 9','PLAZA SAN FRANCISCO','PLAZA SAN FRANCISCO','AV. 9 DE OCTUBRE Y PEDRO CARBO'),
    ('ECO 10','VIA A LA COSTA','VIA A LA COSTA','CDLA. TERRANOSTRA'),
    ('ECO 11','BARRIO CENTENARIO','BARRIO CENTENARIO','AV. DOLORES SUCRE Y MARACAIBO'),
    ('ECO 12','CEIBOS','CEIBOS','DR ALBERTO DACACH Y AV 15AVA SUR');
GO

IF NOT EXISTS (SELECT 1 FROM dbo.eas_roles_central)
    INSERT INTO dbo.eas_roles_central (nombre) VALUES
    (N'Jefe de patrulla'), (N'Conductor'), (N'Auxiliar'), (N'Motorizado'),
    (N'K9'), (N'Radioperador'), (N'Comunicaciones');
GO

-- 12.9 MÓVILES 01-220
IF NOT EXISTS (SELECT 1 FROM dbo.moviles)
BEGIN
    DECLARE @i_mov INT = 1;
    DECLARE @tCam INT, @tMoto INT, @tBici INT, @tOtro INT, @estOpMov INT;
    SELECT @tCam = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id=cd.catalogo_id WHERE c.codigo='TIPOS_MOVIL' AND cd.codigo='CAMIONETA';
    SELECT @tMoto = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id=cd.catalogo_id WHERE c.codigo='TIPOS_MOVIL' AND cd.codigo='MOTOCICLETA';
    SELECT @tBici = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id=cd.catalogo_id WHERE c.codigo='TIPOS_MOVIL' AND cd.codigo='BICICLETA';
    SELECT @tOtro = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id=cd.catalogo_id WHERE c.codigo='TIPOS_MOVIL' AND cd.codigo='OTRO';
    SELECT @estOpMov = cd.id FROM dbo.catalogo_detalles cd INNER JOIN dbo.catalogos c ON c.id=cd.catalogo_id WHERE c.codigo='ESTADOS_MOVIL' AND cd.codigo='OPERATIVO';

    WHILE @i_mov <= 220
    BEGIN
        DECLARE @nombre_mov NVARCHAR(80) = 'Movil ' + CAST(@i_mov AS NVARCHAR(10));
        DECLARE @tipoId INT = CASE
            WHEN @i_mov BETWEEN 1 AND 80 THEN @tCam
            WHEN @i_mov BETWEEN 81 AND 140 THEN @tMoto
            WHEN @i_mov BETWEEN 141 AND 180 THEN @tBici
            ELSE @tOtro
        END;

        IF NOT EXISTS (SELECT 1 FROM dbo.moviles WHERE numero_movil = @nombre_mov)
            INSERT INTO dbo.moviles (numero_movil, placa, tipo_movil_id, kilometraje_actual, kilometraje_ultimo_mantenimiento, estado_movil_id, activo)
            VALUES (@nombre_mov, NULL, @tipoId, 0, 0, @estOpMov, 1);

        SET @i_mov = @i_mov + 1;
    END
    PRINT 'Móviles 01-220 insertados.';
END
GO

-- 12.10 INSIGNIAS DE CARTILLAS
IF NOT EXISTS (SELECT 1 FROM dbo.insignias)
    INSERT INTO dbo.insignias (codigo, titulo, descripcion, meta_cartillas, categoria, icono) VALUES
    ('cartillas_005', N'Agente Amateur', N'Felicidades, por haber realizado 5 cartillas has obtenido la insignia Agente Amateur. Sigue asi y seras el mejor.', 5, 'cartillas', '5'),
    ('cartillas_010', N'Redactor Novato', N'Excelente trabajo. Ya llevas 10 cartillas realizadas y desbloqueaste la insignia Redactor Novato.', 10, 'cartillas', '10'),
    ('cartillas_020', N'Cronista Operativo', N'Vas por muy buen camino. Has generado 20 cartillas y obtuviste la insignia Cronista Operativo.', 20, 'cartillas', '20'),
    ('cartillas_030', N'Agente Comprometido', N'Tu constancia comienza a marcar la diferencia. Has completado 30 cartillas y desbloqueaste la insignia Agente Comprometido.', 30, 'cartillas', '30'),
    ('cartillas_045', N'Reportero Activo', N'Tu productividad sigue creciendo. Has elaborado 45 cartillas y obtuviste la insignia Reportero Activo.', 45, 'cartillas', '45'),
    ('cartillas_060', N'Guardia de Novedades', N'Excelente desempeno. Alcanzaste 60 cartillas y desbloqueaste la insignia Guardia de Novedades.', 60, 'cartillas', '60'),
    ('cartillas_075', N'Operador Estrategico', N'Tu experiencia sigue aumentando. Has registrado 75 cartillas y obtuviste la insignia Operador Estrategico.', 75, 'cartillas', '75'),
    ('cartillas_095', N'Coordinador de Cartillas', N'Ya eres un referente en la generacion de reportes. Has completado 95 cartillas y desbloqueaste la insignia Coordinador de Cartillas.', 95, 'cartillas', '95'),
    ('cartillas_115', N'Supervisor de Incidencias', N'Tu dedicacion fortalece las operaciones. Has alcanzado 115 cartillas y obtuviste la insignia Supervisor de Incidencias.', 115, 'cartillas', '115'),
    ('cartillas_135', N'Agente Destacado', N'Gran logro. Llegaste a 135 cartillas y desbloqueaste la insignia Agente Destacado.', 135, 'cartillas', '135'),
    ('cartillas_155', N'Especialista Operativo', N'Tu compromiso operativo sigue creciendo. Has alcanzado 155 cartillas y desbloqueaste la insignia Especialista Operativo.', 155, 'cartillas', '155'),
    ('cartillas_175', N'Experto en Reportes', N'Tu dominio en la generacion de cartillas es evidente. Has completado 175 cartillas y obtuviste la insignia Experto en Reportes.', 175, 'cartillas', '175'),
    ('cartillas_195', N'Centinela Institucional', N'Has demostrado constancia y responsabilidad institucional. Alcanzaste 195 cartillas y desbloqueaste la insignia Centinela Institucional.', 195, 'cartillas', '195'),
    ('cartillas_215', N'Maestro de Cartillas', N'Tu experiencia te convierte en un referente. Has generado 215 cartillas y obtuviste la insignia Maestro de Cartillas.', 215, 'cartillas', '215'),
    ('cartillas_235', N'Leyenda Operativa', N'Felicidades. Has completado 235 cartillas y desbloqueaste la insignia Leyenda Operativa.', 235, 'cartillas', '235'),
    ('cartillas_255', N'Super Agente', N'Felicidades. Has alcanzado 255 cartillas y desbloqueaste la insignia Super Agente. Eres un verdadero ejemplo.', 255, 'cartillas', '255'),
    ('cartillas_275', N'El Mejor de los Papamike', N'Impresionante. Con 275 cartillas te has ganado la insignia El Mejor de los Papamike.', 275, 'cartillas', '275'),
    ('cartillas_295', N'El Loco de las Cartillas', N'Increible. Has generado 295 cartillas y desbloqueaste la insignia El Loco de las Cartillas.', 295, 'cartillas', '295'),
    ('cartillas_315', N'Tiburon de los Reportes', N'Excepcional. Con 315 cartillas has desbloqueado la insignia Tiburon de los Reportes.', 315, 'cartillas', '315'),
    ('cartillas_335', N'Sniper de Novedades', N'Precision absoluta. Con 335 cartillas desbloqueaste la insignia Sniper de Novedades.', 335, 'cartillas', '335'),
    ('cartillas_355', N'Tirador de Incidencias', N'Apuntas y aciertas. Has alcanzado 355 cartillas y obtuviste la insignia Tirador de Incidencias.', 355, 'cartillas', '355'),
    ('cartillas_375', N'Perito de Cartillas', N'Tu pericia es inigualable. Con 375 cartillas desbloqueaste la insignia Perito de Cartillas.', 375, 'cartillas', '375'),
    ('cartillas_395', N'Jefe de Patrulla', N'Lideras con el ejemplo. Alcanzaste 395 cartillas y obtuviste la insignia Jefe de Patrulla.', 395, 'cartillas', '395'),
    ('cartillas_415', N'Lluvia de Novedades', N'Generas reportes como lluvia. Con 415 cartillas desbloqueaste la insignia Lluvia de Novedades.', 415, 'cartillas', '415'),
    ('cartillas_435', N'Cartillas por Doquier', N'Las cartillas te persiguen. Alcanzaste 435 cartillas y obtuviste la insignia Cartillas por Doquier.', 435, 'cartillas', '435'),
    ('cartillas_455', N'Superheroe Operativo', N'Eres un heroe de las operaciones. Con 455 cartillas desbloqueaste la insignia Superheroe Operativo.', 455, 'cartillas', '455'),
    ('cartillas_475', N'Merodeador de Incidencias', N'Siempre en el lugar correcto. Alcanzaste 475 cartillas y obtuviste la insignia Merodeador de Incidencias.', 475, 'cartillas', '475'),
    ('cartillas_500', N'Jefe de Asuntos Operativos', N'La cima del rendimiento. Con 500 cartillas has desbloqueado la insignia Jefe de Asuntos Operativos.', 500, 'cartillas', '500'),
    ('cartillas_530', N'Comisionado de Elite', N'Excelencia comprobada. Con 530 cartillas has desbloqueado la insignia Comisionado de Elite.', 530, 'cartillas', '530'),
    ('cartillas_565', N'Guardian Supremo', N'Constancia inquebrantable. Al alcanzar 565 cartillas has obtenido la insignia Guardian Supremo.', 565, 'cartillas', '565'),
    ('cartillas_605', N'Maestro Consumado', N'Maestria absoluta. Con 605 cartillas desbloqueaste la insignia Maestro Consumado.', 605, 'cartillas', '605'),
    ('cartillas_650', N'Leyenda Viviente', N'Tu nombre es leyenda. Al llegar a 650 cartillas has obtenido la insignia Leyenda Viviente.', 650, 'cartillas', '650'),
    ('cartillas_700', N'Emblema de Honor', N'Honor y excelencia. Con 700 cartillas desbloqueaste la insignia Emblema de Honor.', 700, 'cartillas', '700'),
    ('cartillas_755', N'Custodio del Sistema', N'Guardian incansable. Al alcanzar 755 cartillas has obtenido la insignia Custodio del Sistema.', 755, 'cartillas', '755'),
    ('cartillas_800', N'Pinaculo del Merito', N'La cima absoluta. Con 800 cartillas has desbloqueado la insignia Pinaculo del Merito.', 800, 'cartillas', '800');
GO

PRINT 'Datos semilla complementarios insertados (EAS, roles central, moviles, insignias).';
GO

-- ============================================================================
-- 12.8 USUARIOS DE PRUEBA (25 PERSONAS)
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.personal)
BEGIN
    DECLARE @rolAdm INT, @rolOpe INT, @rolSup INT, @rolInsp INT, @rolAgente INT, @rolCom INT, @rolAud INT, @rolEnc INT;
    DECLARE @areaOpe INT, @areaAdm INT, @areaCom INT;
    DECLARE @jorDia INT, @jorNoc INT, @jorRot INT;
    DECLARE @grupoA INT, @grupoB INT;
    DECLARE @estActivo INT, @estadoFranco INT, @estVac INT, @estNoOp INT, @estPerm INT, @estLic INT;
    DECLARE @gAg1 INT, @gAg2 INT, @gAg3 INT, @gAg4 INT, @gSub INT, @gInsp INT, @gJefe INT;
    DECLARE @funcEnc INT, @funcSup INT, @funcFila INT, @funcAdm INT, @funcAux INT;
    DECLARE @rotFija INT, @rotRot INT;

    SELECT @rolAdm=id FROM dbo.roles WHERE nombre='Administrador';
    SELECT @rolOpe=id FROM dbo.roles WHERE nombre='Operaciones';
    SELECT @rolSup=id FROM dbo.roles WHERE nombre='Supervisor';
    SELECT @rolInsp=id FROM dbo.roles WHERE nombre='Inspector';
    SELECT @rolAgente=id FROM dbo.roles WHERE nombre='Agente';
    SELECT @rolCom=id FROM dbo.roles WHERE nombre='Comunicaciones';
    SELECT @rolAud=id FROM dbo.roles WHERE nombre='Auditoria';
    SELECT @rolEnc=id FROM dbo.roles WHERE nombre='Encargado';

    SELECT @areaOpe=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='AREAS' AND d.codigo='OPERATIVA';
    SELECT @areaAdm=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='AREAS' AND d.codigo='ADMINISTRACION';
    SELECT @areaCom=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='AREAS' AND d.codigo='COMUNICACIONES';

    SELECT @jorDia=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='JORNADAS' AND d.codigo='DIURNA';
    SELECT @jorNoc=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='JORNADAS' AND d.codigo='NOCTURNA';
    SELECT @jorRot=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='JORNADAS' AND d.codigo='ROTATIVA';

    SELECT @grupoA=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='GRUPOS' AND d.codigo='GRUPO_A';
    SELECT @grupoB=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='GRUPOS' AND d.codigo='GRUPO_B';

    SELECT @estActivo=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='ACTIVO';
    SELECT @estadoFranco=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='FRANCO';
    SELECT @estVac=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='VACACIONES';
    SELECT @estNoOp=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='SUSPENDIDO';
    SELECT @estPerm=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='PERMISO';
    SELECT @estLic=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='ESTADOS_PERSONAL' AND d.codigo='REPOSO_MEDICO';

    SELECT @gAg1=id FROM dbo.grados WHERE nombre=N'Agente 1';
    SELECT @gAg2=id FROM dbo.grados WHERE nombre=N'Agente 2';
    SELECT @gAg3=id FROM dbo.grados WHERE nombre=N'Agente 3';
    SELECT @gAg4=id FROM dbo.grados WHERE nombre=N'Agente 4';
    SELECT @gSub=id FROM dbo.grados WHERE nombre=N'Sub-Inspector';
    SELECT @gInsp=id FROM dbo.grados WHERE nombre=N'Inspector';
    SELECT @gJefe=id FROM dbo.grados WHERE nombre=N'Jefe de Control Municipal';

    SELECT @funcEnc=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='FUNCIONES_OPERATIVAS' AND d.codigo='ENCARGADO';
    SELECT @funcSup=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='FUNCIONES_OPERATIVAS' AND d.codigo='SUPERVISION';
    SELECT @funcFila=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='FUNCIONES_OPERATIVAS' AND d.codigo='FILA_PEDESTRE';
    SELECT @funcAdm=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='FUNCIONES_OPERATIVAS' AND d.codigo='ADMINISTRATIVO';
    SELECT @funcAux=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='FUNCIONES_OPERATIVAS' AND d.codigo='AUXILIAR';

    SELECT @rotFija=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='TIPOS_ROTACION' AND d.codigo='FIJA';
    SELECT @rotRot=d.id FROM dbo.catalogo_detalles d JOIN dbo.catalogos c ON c.id=d.catalogo_id WHERE c.codigo='TIPOS_ROTACION' AND d.codigo='ROTATIVA';

    IF @rolAdm IS NULL SET @rolAdm=1; IF @rolOpe IS NULL SET @rolOpe=@rolAdm;
    IF @rolSup IS NULL SET @rolSup=@rolAdm; IF @rolInsp IS NULL SET @rolInsp=@rolAdm;
    IF @rolAgente IS NULL SET @rolAgente=@rolAdm; IF @rolCom IS NULL SET @rolCom=@rolAdm;
    IF @rolAud IS NULL SET @rolAud=@rolAdm; IF @rolEnc IS NULL SET @rolEnc=@rolAdm;
    IF @areaOpe IS NULL SET @areaOpe=1; IF @areaAdm IS NULL SET @areaAdm=@areaOpe; IF @areaCom IS NULL SET @areaCom=@areaOpe;
    IF @jorDia IS NULL SET @jorDia=1; IF @jorNoc IS NULL SET @jorNoc=@jorDia; IF @jorRot IS NULL SET @jorRot=@jorDia;
    IF @grupoA IS NULL SET @grupoA=1; IF @grupoB IS NULL SET @grupoB=@grupoA;
    IF @estActivo IS NULL SET @estActivo=1; IF @estadoFranco IS NULL SET @estadoFranco=@estActivo;
    IF @estVac IS NULL SET @estVac=@estActivo; IF @estNoOp IS NULL SET @estNoOp=@estActivo;
    IF @estPerm IS NULL SET @estPerm=@estActivo; IF @estLic IS NULL SET @estLic=@estActivo;
    IF @gAg1 IS NULL SET @gAg1=1; IF @gAg2 IS NULL SET @gAg2=@gAg1; IF @gAg3 IS NULL SET @gAg3=@gAg1;
    IF @gAg4 IS NULL SET @gAg4=@gAg1; IF @gSub IS NULL SET @gSub=@gAg1; IF @gInsp IS NULL SET @gInsp=@gAg1; IF @gJefe IS NULL SET @gJefe=@gAg1;
    IF @funcEnc IS NULL SET @funcEnc=1; IF @funcSup IS NULL SET @funcSup=@funcEnc; IF @funcFila IS NULL SET @funcFila=@funcEnc;
    IF @funcAdm IS NULL SET @funcAdm=@funcEnc; IF @funcAux IS NULL SET @funcAux=@funcEnc;
    IF @rotFija IS NULL SET @rotFija=1; IF @rotRot IS NULL SET @rotRot=@rotFija;

    INSERT INTO dbo.personal (cedula, nombres, apellidos, correo_institucional, telefono,
        fecha_nacimiento, fecha_ingreso, cargo_id, area_id, jornada_id, grupo_id, rol_id,
        estado_personal_id, grado_id, funcion_operativa_id, tipo_rotacion_id, activo)
    VALUES
    ('0923456789','Carlos','Mendoza Rivera','cmendoza@bitsac.local','0991234567','1985-03-15','2020-01-10',@funcAdm,@areaAdm,@jorDia,@grupoA,@rolAdm,@estActivo,@gJefe,@funcEnc,@rotFija,1),
    ('0923456790','Ana','Torres Vera','atorres@bitsac.local','0991234568','1988-07-22','2021-03-15',@funcAdm,@areaAdm,@jorDia,@grupoA,@rolAdm,@estActivo,@gSub,@funcAdm,@rotFija,1),
    ('0923456791','Luis','Garcia Lopez','lgarcia@bitsac.local','0991234569','1990-01-08','2021-06-01',@funcEnc,@areaOpe,@jorDia,@grupoA,@rolOpe,@estActivo,@gSub,@funcEnc,@rotFija,1),
    ('0923456792','Maria','Paredes Castillo','mparedes@bitsac.local','0991234570','1992-05-14','2022-01-10',@funcAdm,@areaOpe,@jorDia,@grupoB,@rolOpe,@estActivo,@gAg4,@funcSup,@rotRot,1),
    ('0923456793','Roberto','Jimenez Vera','rjimenez@bitsac.local','0991234571','1987-11-30','2022-05-20',@funcEnc,@areaOpe,@jorNoc,@grupoA,@rolOpe,@estActivo,@gAg3,@funcEnc,@rotFija,1),
    ('0923456794','Pedro','Morales Diaz','pmorales@bitsac.local','0991234572','1986-09-12','2021-08-15',@funcSup,@areaOpe,@jorDia,@grupoA,@rolSup,@estActivo,@gInsp,@funcSup,@rotFija,1),
    ('0923456795','Carmen','Salazar Rojas','csalazar@bitsac.local','0991234573','1991-02-28','2022-03-01',@funcSup,@areaOpe,@jorRot,@grupoB,@rolSup,@estActivo,@gSub,@funcSup,@rotRot,1),
    ('0923456796','Diego','Herrera Mena','dherrera@bitsac.local','0991234574','1989-06-18','2021-11-10',@funcSup,@areaOpe,@jorDia,@grupoA,@rolSup,@estadoFranco,@gSub,@funcSup,@rotFija,1),
    ('0923456797','Sofia','Vargas Ponce','svargas@bitsac.local','0991234575','1993-04-05','2022-07-01',@funcSup,@areaOpe,@jorNoc,@grupoB,@rolInsp,@estActivo,@gAg4,@funcSup,@rotRot,1),
    ('0923456798','Andres','Chavez Lara','achavez@bitsac.local','0991234576','1988-12-20','2022-09-15',@funcEnc,@areaOpe,@jorDia,@grupoA,@rolInsp,@estActivo,@gAg3,@funcEnc,@rotFija,1),
    ('0923456799','Valeria','Rios Delgado','vrios@bitsac.local','0991234577','1994-08-03','2023-01-10',@funcSup,@areaOpe,@jorRot,@grupoB,@rolInsp,@estActivo,@gAg2,@funcSup,@rotRot,1),
    ('0923456800','Jorge','Calderon Aguirre','jcalderon@bitsac.local','0991234578','1995-01-25','2023-02-01',@funcFila,@areaOpe,@jorDia,@grupoA,@rolAgente,@estActivo,@gAg2,@funcFila,@rotFija,1),
    ('0923456801','Lopez','Mendoza Maria','lmendoza@bitsac.local','0991234579','1996-03-10','2023-03-15',@funcFila,@areaOpe,@jorNoc,@grupoB,@rolAgente,@estActivo,@gAg1,@funcFila,@rotRot,1),
    ('0923456802','Paredes','Ramirez Luis','lparedes@bitsac.local','0991234580','1991-07-14','2023-04-01',@funcFila,@areaOpe,@jorDia,@grupoA,@rolAgente,@estActivo,@gAg1,@funcFila,@rotFija,1),
    ('0923456803','Elena','Torres Guevara','etorres@bitsac.local','0991234581','1993-10-22','2023-05-10',@funcAux,@areaOpe,@jorRot,@grupoB,@rolAgente,@estActivo,@gAg2,@funcAux,@rotRot,1),
    ('0923456804','Miguel','Reyes Cevallos','mreyes@bitsac.local','0991234582','1990-05-30','2023-06-01',@funcFila,@areaOpe,@jorDia,@grupoA,@rolAgente,@estActivo,@gAg3,@funcFila,@rotFija,1),
    ('0923456805','Gabriela','Flores Jaramillo','gflores@bitsac.local','0991234583','1994-12-08','2023-07-15',@funcFila,@areaOpe,@jorNoc,@grupoB,@rolAgente,@estadoFranco,@gAg1,@funcFila,@rotRot,1),
    ('0923456806','Fernando','Bustamante Leon','fbustamante@bitsac.local','0991234584','1989-09-17','2023-08-01',@funcFila,@areaOpe,@jorDia,@grupoA,@rolAgente,@estVac,@gAg2,@funcFila,@rotFija,1),
    ('0923456807','Patricia','Sandoval Mejia','psandoval@bitsac.local','0991234585','1978-04-25','2023-09-10',@funcFila,@areaOpe,@jorRot,@grupoB,@rolAgente,@estNoOp,@gAg1,@funcFila,@rotRot,1),
    ('0923456808','Ricardo','Ponce Ortiz','rponce@bitsac.local','0991234586','1987-02-14','2022-04-01',@funcAdm,@areaCom,@jorDia,@grupoA,@rolCom,@estActivo,@gAg3,@funcAdm,@rotFija,1),
    ('0923456809','Claudia','Espinoza Vega','cespinoza@bitsac.local','0991234587','1991-08-09','2022-08-15',@funcAdm,@areaCom,@jorDia,@grupoB,@rolCom,@estActivo,@gAg2,@funcAdm,@rotFija,1),
    ('0923456810','Teresa','Guerrero Paz','tguerrero@bitsac.local','0991234588','1990-11-03','2022-10-01',@funcEnc,@areaOpe,@jorDia,@grupoA,@rolEnc,@estActivo,@gAg2,@funcEnc,@rotFija,1),
    ('0923456811','Hector','Cruz Viteri','hcruz@bitsac.local','0991234589','1986-06-21','2022-11-15',@funcEnc,@areaOpe,@jorDia,@grupoB,@rolEnc,@estPerm,@gAg1,@funcEnc,@rotFija,1),
    ('0923456812','Nancy','Moreira Cevallos','nmoreira@bitsac.local','0991234590','1989-03-28','2023-01-05',@funcAdm,@areaAdm,@jorDia,@grupoA,@rolAud,@estActivo,@gSub,@funcAdm,@rotFija,1),
    ('0923456813','Oscar','Medina Acosta','omedina@bitsac.local','0991234591','1990-07-16','2023-02-20',@funcAdm,@areaAdm,@jorRot,@grupoB,@rolAud,@estLic,@gAg3,@funcAdm,@rotRot,1);

    UPDATE dbo.personal SET password_hash = NULL;
    PRINT '25 usuarios de prueba insertados.';
END
GO

-- ============================================================================
-- 12.9 USUARIO ADMINISTRADOR ADICIONAL (Bermudez)
--     Copia las referencias (rol, area, jornada, grado, etc.) del primer
--     usuario con rol 'admin' para heredar la misma configuracion.
--     Con password_hash NULL, la cedula funciona como contrasena.
-- ============================================================================
IF NOT EXISTS (SELECT 1 FROM dbo.personal WHERE correo_institucional = 'adminbermudez@bitsac.local')
BEGIN
    DECLARE @adminRefId INT;

    SELECT TOP 1 @adminRefId = p.id
    FROM dbo.personal p
    JOIN dbo.roles r ON r.id = p.rol_id
    WHERE r.codigo = 'admin'
    ORDER BY p.id;

    INSERT INTO dbo.personal (cedula, nombres, apellidos, correo_institucional, telefono,
        fecha_nacimiento, fecha_ingreso, cargo_id, area_id, jornada_id, grupo_id, rol_id,
        estado_personal_id, grado_id, funcion_operativa_id, tipo_rotacion_id, activo)
    SELECT '0910000011', N'Bermudez', N'Administrador', 'adminbermudez@bitsac.local', '0990000011',
        '1980-01-01', '2024-01-01', cargo_id, area_id, jornada_id, grupo_id, rol_id,
        estado_personal_id, grado_id, funcion_operativa_id, tipo_rotacion_id, 1
    FROM dbo.personal WHERE id = @adminRefId;

    UPDATE dbo.personal SET password_hash = NULL WHERE correo_institucional = 'adminbermudez@bitsac.local';
    PRINT 'Admin adicional Bermudez insertado.';
END
GO

PRINT '============================================================';
PRINT '  SCRIPT COMPLETO DE BITSAC FINALIZADO CORRECTAMENTE';
PRINT '============================================================';
GO
// hoala //
