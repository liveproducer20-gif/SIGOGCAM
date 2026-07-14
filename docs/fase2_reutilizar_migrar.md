# FASE 2 — Documentación: qué reutilizar y qué migrar

## 1. TABLAS EXISTENTES QUE SE REUTILIZAN

| Tabla | Estado | Uso en nuevo sistema |
|-------|--------|---------------------|
| `dbo.roles` | ✅ Reutilizar | Migrar: agregar columnas `codigo`, `rol_padre_id`, `pagina_inicial`, `nivel_jerarquico`, `color_identificativo` y renombrar `nombre` → `nombre` (se mantiene). Agregar `codigo` único para referencias internas. La columna `activo` se mantiene. |
| `dbo.permisos` | ✅ Reutilizar | Ya tiene `codigo`, `modulo`, `descripcion`, `activo`. Agregar columna `recurso` (ej: "eventos", "personal") y `accion` (ej: "ver", "crear") separando el formato actual `codigo = modulo.accion`. |
| `dbo.rol_permiso` | ✅ Reutilizar | Agregar columnas: `permitido` (BIT, default 1), `heredado` (BIT, default 0), `fecha_actualizacion`. Mantener FK a roles y permisos. |

## 2. TABLAS EXISTENTES CON MODIFICACIONES MENORES

| Tabla | Cambio necesario |
|-------|-----------------|
| `dbo.auditoria` | Ya existe y se usa para auditoría general. Crear tabla separada `auditoria_roles_permisos` para cambios específicos de roles (no modificar la existente). |
| `dbo.personal` | Ya tiene `rol_id` FK → `dbo.roles.id`. Se mantiene sin cambios para el nuevo sistema. |

## 3. NUEVAS TABLAS REQUERIDAS (crear migración)

### 3.1 `dbo.modulos_sistema`
Catálogo de todos los módulos disponibles en la plataforma.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| codigo | NVARCHAR(80) NOT NULL UNIQUE | ej: 'eventos_anuncios', 'cartillas', 'admin' |
| nombre | NVARCHAR(120) NOT NULL | ej: 'Eventos y anuncios' |
| ruta | NVARCHAR(200) NULL | Ruta Flutter interna |
| icono | NVARCHAR(80) NULL | Icono Material Design |
| plataforma | NVARCHAR(20) NOT NULL DEFAULT 'ambos' | 'web', 'movil', 'ambos' |
| orden_global | INT NOT NULL DEFAULT 0 | Orden por defecto |
| tiene_submenus | BIT NOT NULL DEFAULT 0 | |
| estado | BIT NOT NULL DEFAULT 1 | |
| fecha_creacion | DATETIME2 NOT NULL DEFAULT SYSDATETIME() | |

**Seed data** — migrar de `dash_scr.dart` items + grupos actuales:

| codigo | nombre | icono |
|--------|--------|-------|
| dashboard | Dashboard | dashboard |
| eventos_anuncios | Eventos y anuncios | event |
| cartillas | Cartillas | description |
| insignias | Mis insignias | workspace_premium |
| servicios | Servicios | local_police |
| operaciones | Operaciones | security |
| personal | Personal | people |
| moviles | Móviles | directions_car |
| asignaciones | Asignaciones | assignment |
| reportes | Reportes | bar_chart |
| estadisticas | Estadísticas | insights |
| administracion | Administración | admin_panel_settings |
| configuracion | Configuración | settings |
| soporte | Alertas / Soporte | notifications_active |

### 3.2 `dbo.rol_menu_configuracion`
Configuración visual del menú por rol (drag & drop target).

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| rol_id | INT NOT NULL FK → roles | |
| modulo_id | INT NOT NULL FK → modulos_sistema | |
| modulo_padre_id | INT NULL FK → modulos_sistema | Para submenús |
| grupo | NVARCHAR(80) NULL | 'MENU_PRINCIPAL', 'OPERATIVO', 'ADMINISTRACION', etc. |
| nombre_visual | NVARCHAR(120) NULL | Si es NULL, usa el nombre del módulo |
| icono_visual | NVARCHAR(80) NULL | Si es NULL, usa el icono del módulo |
| orden | INT NOT NULL DEFAULT 0 | |
| visible | BIT NOT NULL DEFAULT 1 | |
| habilitado | BIT NOT NULL DEFAULT 1 | |
| expandido | BIT NOT NULL DEFAULT 0 | Para grupos expandidos |
| pagina_inicial | BIT NOT NULL DEFAULT 0 | Solo un módulo por rol |
| primera_opcion | BIT NOT NULL DEFAULT 0 | Redirigir al primer submenú |
| mostrar_badge | BIT NOT NULL DEFAULT 0 | |
| color_badge | NVARCHAR(20) NULL | |
| mostrar_vacio | BIT NOT NULL DEFAULT 1 | Mostrar aunque no tenga datos |
| fecha_actualizacion | DATETIME2 NULL | |
| UNIQUE(rol_id, modulo_id) | | |

### 3.3 `dbo.campos_sistema`
Campos de cada módulo para control de visibilidad.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| modulo_id | INT NOT NULL FK → modulos_sistema | |
| codigo | NVARCHAR(120) NOT NULL | ej: 'personal.cedula', 'personal.telefono' |
| nombre | NVARCHAR(200) NOT NULL | ej: 'Cédula', 'Teléfono' |
| tipo_dato | NVARCHAR(40) NOT NULL DEFAULT 'texto' | 'texto', 'numero', 'fecha', 'email', 'telefono' |
| clasificacion | NVARCHAR(40) NOT NULL DEFAULT 'general' | 'general', 'sensible', 'medica', 'disciplinaria' |
| estado | BIT NOT NULL DEFAULT 1 | |
| UNIQUE(modulo_id, codigo) | | |

### 3.4 `dbo.rol_campos_permisos`
Nivel de acceso por campo por rol.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| rol_id | INT NOT NULL FK → roles | |
| campo_id | INT NOT NULL FK → campos_sistema | |
| nivel_acceso | NVARCHAR(20) NOT NULL DEFAULT 'oculto' | 'oculto', 'lectura', 'editable', 'obligatorio' |
| enmascarado | BIT NOT NULL DEFAULT 0 | |
| UNIQUE(rol_id, campo_id) | | |

### 3.5 `dbo.rol_alcance_datos`
Scope de datos por rol y módulo.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| rol_id | INT NOT NULL FK → roles | |
| modulo_id | INT NOT NULL FK → modulos_sistema | |
| tipo_alcance | NVARCHAR(40) NOT NULL | 'propio', 'area', 'equipo', 'turno', 'distrito', 'creado_por_usuario', 'asignado_usuario', 'global', 'personalizado' |
| configuracion_json | NVARCHAR(MAX) NULL | JSON con configuración adicional |
| UNIQUE(rol_id, modulo_id) | | |

### 3.6 `dbo.rol_condiciones`
Reglas condicionales.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | INT IDENTITY PK | |
| rol_id | INT NOT NULL FK → roles | |
| modulo_id | INT NULL FK → modulos_sistema | NULL = aplica a todo el rol |
| campo | NVARCHAR(120) NOT NULL | ej: 'area', 'rol', 'turno' |
| operador | NVARCHAR(20) NOT NULL | 'igual', 'diferente', 'contiene', 'en', 'mayor', 'menor', 'verdadero', 'falso', 'vacio', 'no_vacio' |
| valor | NVARCHAR(500) NULL | |
| agrupador | NVARCHAR(10) NULL | 'AND', 'OR' |
| estado | BIT NOT NULL DEFAULT 1 | |

### 3.7 `dbo.versiones_configuracion_roles`
Versionado de configuraciones.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | BIGINT IDENTITY PK | |
| rol_id | INT NOT NULL FK → roles | |
| version | INT NOT NULL | |
| estado | NVARCHAR(20) NOT NULL DEFAULT 'borrador' | 'borrador', 'publicado', 'restaurado' |
| configuracion_json | NVARCHAR(MAX) NOT NULL | Snapshot completo |
| comentario | NVARCHAR(500) NULL | |
| creado_por | INT NOT NULL | usuario_id |
| fecha_creacion | DATETIME2 NOT NULL DEFAULT SYSDATETIME() | |
| UNIQUE(rol_id, version) | | |

### 3.8 `dbo.auditoria_roles_permisos`
Auditoría específica.

| Columna | Tipo | Notas |
|---------|------|-------|
| id | BIGINT IDENTITY PK | |
| usuario_id | INT NOT NULL | |
| accion | NVARCHAR(40) NOT NULL | 'crear_rol', 'editar_rol', 'asignar_permiso', 'quitar_permiso', 'publicar_config', 'restaurar_version' |
| rol_afectado_id | INT NULL FK → roles | |
| valor_anterior | NVARCHAR(MAX) NULL | JSON |
| valor_nuevo | NVARCHAR(MAX) NULL | JSON |
| ip | NVARCHAR(80) NULL | |
| dispositivo | NVARCHAR(200) NULL | |
| fecha | DATETIME2 NOT NULL DEFAULT SYSDATETIME() | |

## 4. ARCHIVOS BACKEND A MODIFICAR

| Archivo | Cambio |
|---------|--------|
| `backend/src/config/db.js` | Sin cambios (solo si se agregan nuevas queries) |
| `backend/index.js` | Agregar ruta `/api/configuracion` → `configuracion.routes.js` |
| `backend/src/middleware/auth.middleware.js` | Agregar `requireDataScope(modulo)`, `requireFieldAccess(campo)` |
| `backend/src/middleware/scope.middleware.js` | **NUEVO** — middleware de alcance de datos (filtrado en SQL) |
| `backend/src/validators/auth.validator.js` | Eliminar `permisosPorDefecto` (ya no serán hardcoded). Agregar nuevos códigos de permiso granular. |
| `backend/src/services/auth.service.js` | Cargar permisos SOLO desde DB, no mezclar con defaults hardcoded |
| `backend/src/controllers/admin.controller.js` | Sin cambios mayores (roles CRUD sigue igual, se expande) |
| `backend/src/services/admin.service.js` | Agregar `rolMenuConfiguracion`, `campos`, `alcance`, `condiciones` |
| `backend/src/repositories/admin.repository.js` | Agregar queries para nuevas tablas |
| `backend/src/routes/admin.routes.js` | Agregar rutas para configuraciones de menú, campos, alcance |
| `backend/src/routes/configuracion.routes.js` | **NUEVO** — GET /mi-estructura (menú dinámico), GET /roles-permisos (solo con permiso `configuracion.roles.gestionar`) |
| `backend/src/controllers/configuracion.controller.js` | **NUEVO** — handler para endpoints de configuración |
| `backend/src/services/configuracion.service.js` | **NUEVO** — lógica de construcción del menú dinámico |
| `backend/src/repositories/configuracion.repository.js` | **NUEVO** — queries para estructura de menú |

## 5. ARCHIVOS FRONTEND A MODIFICAR

| Archivo | Cambio |
|---------|--------|
| `mobile/lib/core/auth/app_user.dart` | Agregar `paginaInicial`, `menusAutorizados` (lista dinámica). Eliminar getters hardcoded (`puedeVerAdministracion`, `puedeGestionarEventos`, etc.) o migrarlos a usar la lista dinámica. |
| `mobile/lib/core/auth/auth_session.dart` | Agregar persistencia de `AppUser` (SharedPreferences) para no perder permisos al reiniciar. |
| `mobile/lib/core/api/api_client.dart` | Agregar interceptor para refrescar permisos si se recibe evento de cambio. |
| `mobile/lib/features/dash/dash_scr.dart` | **REFACTOR COMPLETO** — Menú lateral dinámico desde API. Eliminar `items` hardcoded. Usar respuesta de `GET /api/configuracion/mi-estructura`. |
| `mobile/lib/features/dash/wdg/side_menu_wdg.dart` | Hacerlo genérico para recibir lista dinámica de `SideMenuItem` con grupos. |
| `mobile/lib/features/dash/wdg/side_menu_wdg.dart` → `SideMenuItem` | Agregar campos: `codigo`, `ruta`, `grupo`, `submenus`, `acciones`, `plataforma`. |
| `mobile/lib/features/adm/adm_home_scr.dart` | Quitar RolesTab de Admin (se mueve a Configuración). Los tabs se cargan dinámicamente según permisos. |
| `mobile/lib/features/adm/adm_roles_tab.dart` | Mover a `mobile/lib/features/config/` (nuevo módulo Configuración). Expandir con drag & drop. |
| `mobile/lib/features/config/` | **NUEVO** — Módulo completo: editor drag & drop, 3 paneles, vista previa. |
| `mobile/lib/features/config/scr/config_home_scr.dart` | **NUEVO** — Pantalla principal de Configuración con tabs: "Roles, permisos y estructura" |
| `mobile/lib/features/config/scr/rol_editor_scr.dart` | **NUEVO** — Editor drag & drop de 3 paneles |
| `mobile/lib/features/config/wdg/modulos_disponibles_panel.dart` | **NUEVO** — Panel izquierdo: biblioteca de módulos |
| `mobile/lib/features/config/wdg/estructura_rol_panel.dart` | **NUEVO** — Panel central: estructura del menú |
| `mobile/lib/features/config/wdg/configuracion_modulo_panel.dart` | **NUEVO** — Panel derecho: configuración y permisos |
| `mobile/lib/features/config/wdg/rol_permisos_tree.dart` | **NUEVO** — Árbol de permisos por módulo |
| `mobile/lib/features/config/wdg/rol_campos_grid.dart` | **NUEVO** — Grid de campos por módulo |
| `mobile/lib/features/config/wdg/rol_alcance_wdg.dart` | **NUEVO** — Configuración de alcance de datos |
| `mobile/lib/features/config/wdg/rol_condiciones_wdg.dart` | **NUEVO** — Constructor de condiciones |
| `mobile/lib/features/config/svc/config_api.dart` | **NUEVO** — Llamadas a API de configuración |
| `mobile/lib/features/config/svc/estructura_rol_svc.dart` | **NUEVO** — Lógica de drag & drop, undo/redo, validación |
| `mobile/lib/core/auth/menu_constructor.dart` | **NUEVO** — Construye menú dinámico desde JSON de API |

## 6. NUEVOS ENDPOINTS REQUERIDOS

### API Pública (para los usuarios)
| Método | Ruta | Permiso | Propósito |
|--------|------|---------|-----------|
| GET | `/api/configuracion/mi-estructura` | `requireAuth` | Menú dinámico del usuario autenticado |
| GET | `/api/configuracion/mis-permisos` | `requireAuth` | Lista de permisos plana (para checks en UI) |

### API de Administración (editor drag & drop)
| Método | Ruta | Permiso | Propósito |
|--------|------|---------|-----------|
| GET | `/api/admin/configuracion/modulos` | `configuracion.roles.gestionar` | Lista todos los módulos del sistema |
| POST | `/api/admin/configuracion/modulos` | `configuracion.roles.gestionar` | Crear módulo |
| PUT | `/api/admin/configuracion/modulos/:id` | `configuracion.roles.gestionar` | Editar módulo |
| GET | `/api/admin/configuracion/rol/:rolId/estructura` | `configuracion.roles.gestionar` | Estructura de menú del rol |
| PUT | `/api/admin/configuracion/rol/:rolId/estructura` | `configuracion.roles.gestionar` | Guardar estructura (borrador) |
| POST | `/api/admin/configuracion/rol/:rolId/publicar` | `configuracion.roles.gestionar` | Publicar configuración |
| GET | `/api/admin/configuracion/rol/:rolId/versiones` | `configuracion.roles.gestionar` | Historial de versiones |
| POST | `/api/admin/configuracion/rol/:rolId/versiones/:version/restaurar` | `configuracion.roles.gestionar` | Restaurar versión |
| GET | `/api/admin/configuracion/campos/:moduloId` | `configuracion.roles.gestionar` | Campos del módulo |
| PUT | `/api/admin/configuracion/rol/:rolId/campos` | `configuracion.roles.gestionar` | Guardar permisos de campos |
| GET | `/api/admin/configuracion/rol/:rolId/alcance` | `configuracion.roles.gestionar` | Alcance de datos del rol |
| PUT | `/api/admin/configuracion/rol/:rolId/alcance` | `configuracion.roles.gestionar` | Guardar alcance |
| GET | `/api/admin/configuracion/rol/:rolId/condiciones` | `configuracion.roles.gestionar` | Condiciones del rol |
| PUT | `/api/admin/configuracion/rol/:rolId/condiciones` | `configuracion.roles.gestionar` | Guardar condiciones |
| GET | `/api/admin/configuracion/rol/:rolId/vista-previa` | `configuracion.roles.gestionar` | Vista previa (simulación segura) |
| POST | `/api/admin/configuracion/rol/:rolId/clonar` | `configuracion.roles.gestionar` | Clonar configuración a otro rol |
| GET | `/api/admin/configuracion/rol/:rolId/auditoria` | `configuracion.roles.gestionar` | Auditoría del rol |

### API de Roles (expandida desde admin actual)
| Método | Ruta | Permiso | Propósito |
|--------|------|---------|-----------|
| PUT | `/api/admin/roles/:id/herencia` | `roles.editar` | Establecer rol_padre_id |
| GET | `/api/admin/roles/comparar` | `roles.ver` | Comparar dos roles |

## 7. NUEVOS PERMISOS REQUERIDOS (crear en DB)

### Módulo: `configuracion`
```
configuracion.roles.gestionar   — Acceso al editor de roles, menús y permisos
configuracion.roles.ver         — Ver configuración de roles
configuracion.general.ver       — Ver configuración general
configuracion.general.editar    — Editar configuración general
```

### Nuevos permisos granulares por módulo (formato `modulo.accion`)
Para cada módulo existente (`eventos`, `anuncios`, `personal`, `cartillas`, `insignias`, `soporte`, `moviles`, `eas`, `lugares_servicio`, `catalogos`, `reportes`):

```
*.visualizar           — Ver el módulo en el menú
*.listar               — Listar registros
*.consultar_detalle    — Ver detalle de un registro
*.crear                — Crear registros
*.editar               — Editar registros
*.eliminar             — Eliminar registros
*.exportar             — Exportar datos
*.descargar            — Descargar archivos
```

### Adicionales específicos:
```
eventos.confirmar_asistencia   — Confirmar asistencia propia
eventos.gestionar_asistentes   — Gestionar asistentes (ya existe como eventos.asistencia)
eventos.abrir_ubicacion        — Abrir ubicación en mapa
eventos.descargar_archivos     — Descargar archivos adjuntos (ya existe como eventos.adjuntos)
anuncios.publicar              — Publicar anuncios (ya existe)
anuncios.archivar              — Archivar anuncios
anuncios.compartir             — Compartir anuncios
personal.ver_sensible          — Ver información sensible (cédula, teléfono, etc.)
```

## 8. RIESGOS IDENTIFICADOS

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Romper roles existentes al migrar permisos | Media | Alto | Migrar en transacción; probar con borrador antes de publicar |
| Perder permisos hardcoded de `auth.validator.js` | Alta | Alto | Los defaults hardcoded deben migrarse a la DB antes de eliminar el código |
| Código Flutter hardcoded deja de funcionar sin menú dinámico | Alta | Alto | Implementar menú dinámico como reemplazo directo, mantener compatibilidad |
| Usuario pierde permisos durante sesión activa | Media | Medio | Implementar notificación "Tu configuración ha sido actualizada" + redirección |
| Admin se quita permiso `configuracion.roles.gestionar` | Baja | Alto | Validar en backend: no permitir que el último admin pierda ese permiso |
| Ciclos de herencia entre roles | Baja | Medio | Validar en backend antes de guardar herencia |
| Carga masiva de datos al pedir menú dinámico | Baja | Bajo | Cachear estructura con invalidación controlada |

## 9. DEPENDENCIAS ENTRE FASES

```
FASE 3 (SQL migraciones)
  └── FASE 4 (Middleware + servicios Node)
       └── FASE 5 (Proteger endpoints existentes)
            └── FASE 6 (API configuración dinámica)
                 ├── FASE 7 (Editor drag & drop Flutter)
                 └── FASE 8 (Menú dinámico Flutter)
                      └── FASE 9 (Campos, alcance, condiciones)
                           └── FASE 10 (Vista previa, versionado)
                                └── FASE 11 (Pruebas)
```

**Nota**: FASES 7 y 8 pueden desarrollarse en paralelo si hay dos developers.

## 10. ESTRATEGIA DE MIGRACIÓN DE DATOS

1. **Migrar permisos hardcoded** (`auth.validator.js` → `permisosPorDefecto`) a la tabla `dbo.permisos` y asignarlos a cada rol en `dbo.rol_permiso` — esto elimina la dependencia de código.
2. **Crear módulos del sistema** basados en los menús actuales de Flutter.
3. **Generar configuración inicial de menú** para cada rol existente basada en la estructura actual (dashboard_scr.dart items + grupos).
4. **Generar configuración de campos** básica para cada módulo.
5. **Establecer alcance global** para Administrador, y `propio` para roles operativos como configuración inicial.
6. Publicar como `version 1` de cada rol.
