# Documentacion de Modulos - BITSAC / SIGO - Sistema Inteligente de Gestión Operativa

**Autor:** Jorge Luis Calderon Aguirre
**Organizacion:** SIGO WORKING TECHNOLOGIES
**Fecha de inicio:** 1 de junio de 2026

---

## Indice

1. [Modulo Autenticacion (auth)](#1-modulo-autenticacion-auth)
2. [Modulo Dashboard (dash)](#2-modulo-dashboard-dash)
3. [Modulo Cartillas (crt)](#3-modulo-cartillas-crt)
4. [Modulo Eventos (evt)](#4-modulo-eventos-evt)
5. [Modulo Insignias (ins)](#5-modulo-insignias-ins)
6. [Modulo Administracion (adm)](#6-modulo-administracion-adm)
7. [Modulo Soporte (sup)](#7-modulo-soporte-sup)
8. [Modulo Configuracion (config)](#8-modulo-configuracion-config)
9. [Modulo Perfil (profile)](#9-modulo-perfil-profile)

---

## 1. Modulo Autenticacion (auth)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `auth_scr.dart` | Pantalla de login |
| `auth_api.dart` | Servicio de autenticacion API |

### Pantalla de Login

**Diseno:** Panel dividido en pantallas anchas (imagen + formulario) y formulario completo en movil.

**Campos del formulario:**

| Campo | Tipo | Validacion |
|-------|------|-----------|
| Usuario | TextField | Requerido, minimo 3 caracteres |
| Contrasena | TextField (oculto) | Requerido, minimo 6 caracteres |

**Botones:**
- `Iniciar sesion` — Envia credenciales al backend
- `Mostrar/ocultar contrasena` — Toggle de visibilidad

**Comportamiento:**
- Rate limiting: maximo 10 intentos cada 15 minutos
- En exito: almacena token JWT + datos de usuario en `AuthSession` y navega a `DashScr`
- En error: muestra SnackBar con mensaje de error
- Si ya existe sesion activa: salta directamente al Dashboard

**API utilizada:**
```
POST /api/auth/login
Body: { "usuario": "...", "contrasena": "..." }
Response: { "ok": true, "token": "...", "usuario": { ... } }
```

### Token y Sesion

- JWT con expiracion configurable
- Refresh token con rate limiting (30/hora)
- Almacenamiento en `SharedPreferences`
- `AuthSession` singleton mantiene token y usuario en memoria
- Auto-logout cuando el token expira (`onSessionExpired`)

---

## 2. Modulo Dashboard (dash)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `dash_scr.dart` | Pantalla principal con navegacion |
| `wdg/side_menu_wdg.dart` | Menu lateral (web) |
| `wdg/side_menu_config.dart` | Configuracion y resolucion de menus |
| `wdg/side_menu_api.dart` | API de estructura de menus |
| `wdg/top_bar_wdg.dart` | Barra superior con perfil y notificaciones |
| `wdg/page_ttl_wdg.dart` | Widget de titulo de pagina |
| `wdg/dev_card_wdg.dart` | Card de modulo en desarrollo |

### Estructura de Navegacion

**Web:** Menu lateral colapsable + contenido principal con `IndexedStack`
**Movil:** Grid de modulos con navegacion por `Navigator.push`

### Modulos del Menu (segundos nivel)

| Destino | Icono | Descripcion |
|---------|-------|-------------|
| Dashboard | `dashboard_outlined` | Panel de bienvenida |
| Eventos | `event_available_outlined` | Gestion de eventos y anuncios |
| Cartillas | `description_outlined` | Generador de cartillas de novedades |
| Insignias | `workspace_premium` | Sistema de gamificacion |
| Administracion | `admin_panel_settings` | Gestion de usuarios, roles, catalogos |
| Configuracion | `settings` | Editor dinamico de menus y roles |
| Soporte | `support_agent` | Tickets de soporte en tiempo real |

### Barra Superior (TopBarWdg)

**Elementos:**
- Icono de modulo + Titulo
- Boton de notificaciones (badge con contador)
- Menu de perfil (avatar + nombre + rol)
  - Mi perfil
  - Configuracion (si tiene permiso)
  - Cerrar sesion

### Sistema de Notificaciones

- Combina eventos y anuncios no leidos
- `NotifReadStore` marca leidos localmente
- Dialogo de detalle con imagen/PDF adjunto

### Perfil de Usuario (ProfileMenuWdg)

**Campos visualizados:**
- Avatar con iniciales
- Nombre completo
- Cedula
- Correo electronico
- Grado
- Rol asignado
- Lista de permisos

### Menu Dinamico

Los menus se cargan desde la API (`GET /api/configuracion/mi-estructura`) y se resuelven con permisos del usuario. Fallback a menus estaticos si la API falla.

---

## 3. Modulo Cartillas (crt)

### Archivos Principales

| Archivo | Descripcion |
|---------|-------------|
| `crt_home_scr.dart` | Pantalla principal del generador |
| `mdl/crt_enums.dart` | Enums de tipos de cartilla y modulo |
| `mdl/crt_models.dart` | Modelos de datos (CrtEasStation, CrtFormData) |
| `mdl/crt_special_models.dart` | Modelos especiales (FormacionData, ConductorData) |
| `svc/crt_api.dart` | API de cartillas |
| `svc/crt_catalog.dart` | Catalogo local de EAS y dotacion |
| `svc/crt_text_generator.dart` | Generador de texto para cartillas |

### Tipos de Modulo (13)

| Modulo | Descripcion |
|--------|-------------|
| EAS | Estacion de Accion Segura |
| Motorizado | Agentes en moto |
| K9 | Unidades caninas |
| Ambiente | Proteccion ambiental |
| Fila/Pedestre | Agentes a pie |
| Administrativo | Personal administrativo |
| Ciclista | Agentes en bicicleta |
| Conductor | Conductores de unidades |
| Palacio | Custodia de edificios |
| Cuadrante | Patrullaje por cuadrante |
| Apoyo Seguridad Ciudadana | Apoyo a la ciudadania |
| Radioperador | Personal de comunicaciones |
| Supervision | Personal de supervision |

### Tipos de Cartilla (27)

| Cartilla | Tipo | Causa Automatica |
|----------|------|------------------|
| Formacion Entrante | Especial | No |
| Formacion Saliente | Especial | No |
| Desalojo de vendedores | EAS | Si |
| Punto Martillo | EAS | Si |
| Rondas Disuasivas | EAS | Si |
| Retiro Temporal | EAS | Si |
| Requerimiento | EAS | Si |
| Colaboracion Entidades | EAS | Si |
| Colaboracion Ciudadana | EAS | Si |
| Ausentismo | Comun | No |
| Otras Cartillas | Comun | No |
| Ingreso | Basica | No |
| Salida | Basica | No |
| Novedades | Basica | No |
| Incidencia | Basica | No |
| Procedimiento | Basica | No |
| Apoyo | Basica | No |
| Operativo | Basica | No |
| Permiso Ausentismo | EAS | Si |
| Accidente | Basica | No |
| Robo Mano Armada | Basica | No |
| Perdida Bien Inmueble | Basica | No |
| Extension | Basica | No |
| Amenazas | Basica | No |
| Desaparicion Persona | Basica | No |
| Agresion | Basica | No |
| Visualizacion Camaras | Basica | No |

### Formulario Estandar (todos los tipos)

**Campos comunes:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Tipo de servicio | Dropdown | EAS, Motorizado, K9, etc. (desde API) |
| EAS | Dropdown | Estaciones (desde API `GET admin/eas`) |
| Distrito | Dropdown | Distritos (desde API) |
| Direccion | TextField | Direccion del lugar |
| Horario | TextField | Rango de horas (auto-asignado para EAS/Radioperador) |
| Fecha/Hora | DateTime | Fecha y hora actual (auto) |
| Causa | TextField | Motivo de la cartilla |
| Novedades | TextField | Descripcion de novedades |
| Moviles | CheckboxListTile | Moviles asignados (desde API `GET cartillas/asignaciones-eas-moviles`) |
| Foto | ImagePicker | Adjuntar fotografias |
| Observaciones | TextField | Notas adicionales |

### Turno Automatico (EAS / Radioperador)

| Hora actual | Turno asignado |
|-------------|----------------|
| 06:00 - 13:59 | 06:00 - 14:30 (Manana) |
| 14:00 - 21:59 | 14:00 - 22:30 (Tarde) |
| 22:00 - 05:59 | 22:00 - 06:30 (Noche) |

Al seleccionar EAS o RADIOPERADOR se ocultan los campos de hora y se asigna automaticamente el turno.

### Formacion Entrante / Saliente

**Campos especiales:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Tipo formacion | Enum | Entrante / Saliente |
| Circuito | TextField | Codigo del circuito |
| Radiooperadores | TextField | Cantidad de radiooperadores |
| ACM Operativos | TextField | Cantidad de agentes operativos |
| Personal Policial | TextField | Nombre del personal policial |
| Reportantes | TextField | Agentes que reportan |
| Jefe Control Municipal | TextField | Nombre del jefe (cargado desde API) |

**Preview:** Formato institutional con saludo segun hora del dia.

### Conductor (Cartilla especial)

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Conductor | Dropdown | Seleccion de conductor |
| Cedula ultimos 4 | TextField | Ultimos 4 digitos de cedula |
| Opcion | Radio | Entrada personal / Salida personal / Novedades movil |
| Lugar | TextField | Lugar de operacion |
| Disco | TextField | Numero de disco |
| Combustible | TextField | Nivel de combustible |
| Kilometraje | TextField | Kilometraje actual |
| Servicio | TextField | Tipo de servicio |
| Encargado | Dropdown | Encargado de turno |
| Observaciones | TextField | Notas |

### Vista Previa en Tiempo Real

- Formato de WhatsApp (texto plano con asteriscos para negrita)
- Actualizacion con debounce de 250ms
- Boton de "Copiar" al portapapeles
- Boton de "Compartir" (Share Plus)
- Boton de "Generar" para registrar en API

### API de Cartillas

```
GET  /api/cartillas/eas                    — Lista de estaciones EAS
GET  /api/cartillas/asignaciones-eas-moviles — Moviles asignados por EAS
GET  /api/cartillas/catalogos-operativos   — Catalogos operativos
GET  /api/cartillas/jefe-control-municipal  — Jefe de control municipal
GET  /api/cartillas/eas-direcciones        — Direcciones por EAS
GET  /api/cartillas/servidores-policiales  — Servidores policiales
POST /api/cartillas                        — Registrar cartilla
```

---

## 4. Modulo Eventos (evt)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `scr/evt_home_scr.dart` | Pantalla principal con tabs Eventos/Anuncios |
| `new/scr/evt_new_scr.dart` | Formulario de nuevo evento |
| `svc/evt_svc.dart` | Servicio API de eventos |
| `mdl/evt_mdl.dart` | Modelo de evento |
| `wdg/evt_overview_wdg.dart` | Vista de resumen de eventos |
| `wdg/evt_fil_wdg.dart` | Filtros de eventos |
| `wdg/evt_estado_style.dart` | Estilos de estado |
| `ann/scr/ann_home_scr.dart` | Gestion de anuncios |
| `ann/mdl/ann_mdl.dart` | Modelo de anuncio |

### Eventos

**Campos del formulario:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Nombre | TextField | Nombre del evento |
| Tipo | Dropdown | Tipo de evento |
| Prioridad | Dropdown | Alta / Media / Baja |
| Fecha inicio | DatePicker | Fecha de inicio |
| Fecha fin | DatePicker | Fecha de fin |
| Hora | TimePicker | Hora del evento |
| Lugar | TextField | Ubicacion |
| Descripcion | TextField | Detalle del evento |
| Convocados | Selector | Personas convocadas |
| Notificar | Switch | Enviar notificaciones |
| Documento | FilePicker | Archivo adjunto (PDF) |
| Imagen | ImagePicker | Imagen adjunta |

**Estados del evento:**
- Programado
- En curso
- Finalizado
- Cancelado

**Filtros disponibles:**
- Busqueda por nombre
- Filtrar por estado
- Filtrar por prioridad
- Filtrar por tipo
- Ordenamiento

### Anuncios

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Titulo | TextField | Titulo del anuncio |
| Descripcion | TextField | Contenido del anuncio |
| Prioridad | Dropdown | Alta / Media / Baja |
| Publicado | Switch | Estado de publicacion |
| Notificar | Switch | Enviar notificaciones |
| Fecha expiracion | DatePicker | Fecha de caducidad |
| Personal destinatario | Selector | Personas destinatarias |
| Imagen | ImagePicker | Imagen adjunta |

### API de Eventos

```
GET    /api/eventos              — Listar eventos
POST   /api/eventos              — Crear evento
PUT    /api/eventos/:id          — Actualizar evento
DELETE /api/eventos/:id          — Eliminar evento
GET    /api/anuncios             — Listar anuncios
POST   /api/anuncios             — Crear anuncio
PUT    /api/anuncios/:id         — Actualizar anuncio
DELETE /api/anuncios/:id         — Eliminar anuncio
```

---

## 5. Modulo Insignias (ins)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `ins_home_scr.dart` | Pantalla principal de insignias |
| `ins_widgets.dart` | Widgets de UI (timeline, cards, leaderboard, tabs) |
| `ins_api.dart` | API de insignias |
| `ins_mdl.dart` | Modelos de datos |
| `badge_catalog.dart` | Catalogo de 48 insignias en 10 niveles |
| `ins_achievement_theme.dart` | Temas de color por nivel |
| `ins_icn_wdg.dart` | Widget de icono SVG de insignia |
| `ins_share_modal.dart` | Modal de compartir |
| `achievement_unlocked_card.dart` | Tarjeta de logro desbloqueado |
| `achievement_image_export.dart` | Exportacion de imagen (IO/Web) |

### Sistema de Niveles

| Nivel | Nombre | Rango Cartillas | Color Primario |
|-------|--------|----------------|----------------|
| 1 | Amateur | 1 - 5 | #A8D5BA (Verde claro) |
| 2 | Operativo | 6 - 15 | #2ECC71 (Verde) |
| 3 | Profesional | 16 - 30 | #1ABC9C (Turquesa) |
| 4 | Avanzado | 31 - 50 | #8E44AD (Morado) |
| 5 | Experto | 51 - 80 | #E67E22 (Naranja) |
| 6 | Elite | 81 - 120 | #E74C3C (Rojo) |
| 7 | Leyenda | 121 - 170 | #CD7F32 (Bronce) |
| 8 | Supremo | 171 - 230 | #95A5A6 (Gris) |
| 9 | Mitico | 231 - 300 | #4A7CC9 (Azul) |
| 10 | Maximo | 301+ | #FFD700 (Dorado) |

### Estructura de la Pantalla

1. **Header** — Titulo "Mis insignias" con descripcion
2. **Timeline** — Barra de progreso horizontal con nodos por insignia
   - Nodo desbloqueado: borde dorado + check verde
   - Nodo actual: borde azul con animacion de respiracion
   - Nodo bloqueado: gris con candado
3. **ProgressSummaryCards** — 4 cards: Desbloqueadas, Pendientes, Restantes, Nivel actual
4. **AchievementProgressCard** — Progreso circular + barra + boton compartir
5. **DashboardSection** — Ranking de top usuarios + podio (medallas)
6. **AchievementTabs** — 3 tabs: Desbloqueadas, En progreso, Bloqueadas

### Tarjeta de Insignia

**Campos visualizados:**
- Icono SVG (desbloqueado a color, bloqueado en gris)
- Titulo de la insignia
- Estado (DESBLOQUEADA / EN PROGRESO / BLOQUEADA)
- Meta: X cartillas
- Barra de progreso (solo en progreso)
- Porcentaje y ratio (ej: "12/30")
- Boton compartir

### Tarjeta de Logro Desbloqueado (Dialog)

**Elementos:**
- Animacion de escala (bounce)
- Icono de insignia grande
- Titulo del logro
- Mensaje/descripcion
- Nivel del usuario
- Nombre del usuario
- Fecha de desbloqueo
- Botones: Compartir / Continuar / Descargar imagen

### Leaderboard (Ranking)

**Columnas de la tabla:**
- # (posicion)
- Usuario (avatar + nombre)
- Insignia mas alta (icono + nombre)
- Nivel (badge de color)
- Progreso (barra + porcentaje)

### API de Insignias

```
GET /api/insignias                    — Todas las insignias
GET /api/usuarios/:id/insignias       — Insignias del usuario
GET /api/usuarios/:id/progreso-insignias — Progreso del usuario
GET /api/insignias/ranking            — Ranking de usuarios
POST /api/cartillas                   — Registrar cartilla (incrementa progreso)
```

---

## 6. Modulo Administracion (adm)

### Archivos Principales

| Archivo | Descripcion |
|---------|-------------|
| `adm_home_scr.dart` | Pantalla principal con tabs de admin |
| `adm_api.dart` | API de administracion |
| `adm_widgets.dart` | Widgets compartidos (tablas, formularios, paginacion) |
| `adm_helpers.dart` | Cache de catalogos, utilidades |
| `adm_lazy_tab.dart` | Carga lazy de tabs |
| `adm_design_tokens.dart` | Tokens de diseno (colores, tipografia) |

### Sub-modulos (9 tabs)

#### 6.1 Personal

**Tabla de campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Cedula | TextField | Numero de cedula (unico) |
| Nombres | TextField | Nombres completos |
| Apellidos | TextField | Apellidos completos |
| Correo | TextField | Correo electronico |
| Telefono | TextField | Numero de telefono |
| Grado | Dropdown | Grado academico |
| Cargo | Dropdown | Cargo asignado |
| Area | Dropdown | Area de trabajo |
| Grupo | Dropdown | Grupo operativo |
| Jornada | Dropdown | Tipo de jornada |
| Rotacion | Dropdown | Tipo de rotacion |
| Estado | Dropdown | Activo / Inactivo |
| Fecha ingreso | DatePicker | Fecha de ingreso |

**Operaciones:** CRUD completo, busqueda, filtros, paginacion, exportacion CSV

#### 6.2 Catalogos

**Catalogos administrables:**

| Codigo | Descripcion |
|--------|-------------|
| DISTRITOS | Distritos de Guayaquil |
| AREAS | Areas de trabajo |
| FUNCIONES_OPERATIVAS | Funciones operativas |
| GRUPOS | Grupos de trabajo |
| JORNADAS | Tipos de jornada |
| TIPOS_ROTACION | Tipos de rotacion |
| ESTADOS_PERSONAL | Estados del personal |
| SUBUNIDADES_OPERATIVAS | Subunidades |
| TIPOS_SERVICIO_LUGAR | Tipos de servicio de lugar |
| TIPOS_MOVIL | Tipos de vehiculo |
| ESTADOS_MOVIL | estados de vehiculo |
| TIPOS_MANTENIMIENTO | Tipos de mantenimiento |

**Operaciones:** CRUD por catalogo, busqueda, ordenamiento, exportacion

#### 6.3 Roles

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Nombre | TextField | Nombre del rol |
| Descripcion | TextField | Descripcion del rol |

**Funcionalidades:**
- CRUD de roles
- Asignacion de permisos granulares (arbol de permisos)
- Permisos por modulo: `modulo.accion` (ej: `personal.ver`, `cartillas.generar`)
- Vista detallada de permisos asignados

#### 6.4 Lugares de Servicio

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Nombre | TextField | Nombre del lugar |
| Ubicacion | TextField | Direccion/ubicacion |
| Observaciones | TextField | Notas adicionales |

**Vista:** Grid responsive (1-4 columnas) o DataTable
**Operaciones:** CRUD, busqueda, filtros (estado, ruta, distrito), activar/desactivar

#### 6.5 Rutas

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Nombre | TextField | Nombre de la ruta |
| Ubicacion | TextField | Ubicacion/descripcion |
| Distrito | Dropdown | Distrito al que pertenece |
| Horario entrada | TextField | Hora de inicio (HH:mm) |
| Horario salida | TextField | Hora de fin (HH:mm) |
| Consignas | TextField | Instrucciones especiales |

**Vista:** Tabla con columnas: Codigo, Nombre, Lugares (count), Distrito, Estado, Acciones
**Operaciones:** CRUD, activar/desactivar, ver lugares asociados

#### 6.6 Grados

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Nombre | TextField | Nombre del grado |

**Estadisticas:** Personal asignado por grado, grado mas asignado
**Operaciones:** CRUD, activar/desactivar

#### 6.7 EAS (Estaciones de Accion Segura)

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Codigo | TextField | Codigo de la EAS (ej: ECO 1) |
| Nombre | TextField | Nombre de la estacion |
| Direccion | TextField | Direccion de la estacion |
| Distrito | Dropdown | Distrito al que pertenece |
| Estado | Dropdown | Activo / Inactivo |

**Estadisticas:** Total EAS, EAS activos, asignaciones, distritos cubiertos
**Operaciones:** CRUD, ver asignaciones, ver detalle, activar/desactivar

#### 6.8 Moviles (Vehiculos)

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| Numero movil | TextField | Numero identificador (ej: Movil 187) |
| Placa | TextField | Placa del vehiculo |
| Tipo | Dropdown | Tipo de vehiculo |
| Estado | Dropdown | Estado del vehiculo |
| Kilometraje actual | TextField | Kilometraje actual |
| Proximo mantenimiento | TextField | Kilometraje proximo mantenimiento |

**Operaciones:** CRUD, ver asignacion actual, ver historial de mantenimiento, activar/desactivar

#### 6.9 Asignaciones EAS-Moviles

**Campos:**

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| EAS | Dropdown | Estacion de accion segura |
| Movil | Dropdown | Vehiculo a asignar |
| Estado | Dropdown | Activo / Finalizado |
| Observacion | TextField | Notas de la asignacion |

**Operaciones:** Crear asignacion, finalizar asignacion, ver historial

### API de Administracion

```
# Personal
GET    /api/personal                  — Listar personal
POST   /api/personal                  — Crear personal
PUT    /api/personal/:id              — Actualizar personal
DELETE /api/personal/:id              — Eliminar personal

# Catalogos
GET    /api/catalogos/:codigo         — Obtener catalogo
POST   /api/catalogos/:codigo         — Agregar item
PUT    /api/catalogos/:codigo/:id     — Actualizar item
DELETE /api/catalogos/:codigo/:id     — Eliminar item

# Roles
GET    /api/admin/roles               — Listar roles
POST   /api/admin/roles               — Crear rol
PUT    /api/admin/roles/:id           — Actualizar rol
DELETE /api/admin/roles/:id           — Eliminar rol
GET    /api/admin/roles/:id/permisos  — Permisos del rol
PUT    /api/admin/roles/:id/permisos  — Asignar permisos

# EAS
GET    /api/admin/eas                 — Listar EAS
POST   /api/admin/eas                 — Crear EAS
PUT    /api/admin/eas/:id             — Actualizar EAS
DELETE /api/admin/eas/:id             — Eliminar EAS
PUT    /api/admin/eas/:id/estado      — Activar/desactivar

# Moviles
GET    /api/admin/moviles             — Listar moviles
POST   /api/admin/moviles             — Crear movil
PUT    /api/admin/moviles/:id         — Actualizar movil
DELETE /api/admin/moviles/:id         — Eliminar movil

# Lugares
GET    /api/admin/lugares-servicio    — Listar lugares
POST   /api/admin/lugares-servicio    — Crear lugar
PUT    /api/admin/lugares-servicio/:id — Actualizar lugar
DELETE /api/admin/lugares-servicio/:id — Eliminar lugar

# Rutas
GET    /api/admin/rutas               — Listar rutas
POST   /api/admin/rutas               — Crear ruta
PUT    /api/admin/rutas/:id           — Actualizar ruta
DELETE /api/admin/rutas/:id           — Eliminar ruta

# Grados
GET    /api/admin/grados              — Listar grados
POST   /api/admin/grados              — Crear grado
PUT    /api/admin/grados/:id          — Actualizar grado
DELETE /api/admin/grados/:id          — Eliminar grado

# Asignaciones
GET    /api/cartillas/asignaciones-eas-moviles — Listar asignaciones
POST   /api/cartillas/asignaciones-eas-moviles — Crear asignacion
PUT    /api/cartillas/asignaciones-eas-moviles/:id — Finalizar
```

---

## 7. Modulo Soporte (sup)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `sup_home_scr.dart` | Pantalla principal de soporte |
| `sup_api.dart` | API de soporte |
| `sup_mdl.dart` | Modelos de ticket y estadisticas |
| `sup_badges.dart` | Badges de estado y prioridad |
| `sup_realtime.dart` | Cliente SSE para tiempo real |
| `sup_report_form.dart` | Formulario de reporte |
| `sup_ticket_detail.dart` | Detalle del ticket |

### Caracteristicas

- **Server-Sent Events (SSE)** para actualizaciones en tiempo real
- **Filtros:** busqueda, estado, prioridad, modulo, usuario, area, fecha
- **Paginacion:** 20 tickets por pagina
- **Estadisticas:** Total, Abiertos, En progreso, Cerrados, Urgentes

### Modelo de Ticket

| Campo | Tipo | Descripcion |
|-------|------|-------------|
| id | int | ID unico |
| titulo | String | Titulo del ticket |
| descripcion | String | Detalle del problema |
| estado | String | Abierto / En progreso / Cerrado |
| prioridad | String | Baja / Normal / Alta / Urgente |
| modulo | String | Modulo afectado |
| area | String | Area responsable |
| creado_por | String | Usuario que creo |
| asignado_a | String | Soporte asignado |
| fecha_creacion | DateTime | Fecha de creacion |
| fecha_cierre | DateTime? | Fecha de cierre |

### API de Soporte

```
GET    /api/soporte/stats        — Estadisticas
GET    /api/soporte/tickets      — Listar tickets (paginado, filtros)
POST   /api/soporte/tickets      — Crear ticket
PUT    /api/soporte/tickets/:id  — Actualizar ticket
GET    /api/soporte/stream       — SSE para tiempo real
```

---

## 8. Modulo Configuracion (config)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `config_editor_scr.dart` | Editor principal de configuracion |
| `config_api.dart` | API de configuracion |
| `config_mdl.dart` | Modelos de configuracion |
| `wdg/` | Widgets del editor |

### Funcionalidades

- **Editor de Menus:** Crear, editar, reordenar y eliminar elementos del menu
- **Editor de Roles:** Configurar roles con drag-and-drop
- **Permisos por Campo:** Control granular de acceso a campos
- **Alcance de Datos:** Definir que datos puede ver cada rol
- **Condiciones:** Reglas de negocio condicionales
- **Versioning:** Historial de cambios de configuracion

### API de Configuracion

```
GET  /api/configuracion/mi-estructura  — Estructura de menus del usuario
GET  /api/configuracion/roles          — Configuracion de roles
PUT  /api/configuracion/roles/:id      — Actualizar configuracion de rol
GET  /api/configuracion/version        — Version actual de configuracion
```

---

## 9. Modulo Perfil (profile)

### Archivos

| Archivo | Descripcion |
|---------|-------------|
| `profile_api.dart` | API de perfil |
| `profile_menu_wdg.dart` | Widget de menu de perfil |

### Informacion Visualizada

- Avatar con iniciales del usuario
- Nombre completo
- Numero de cedula
- Correo electronico
- Grado academico
- Rol asignado
- Lista de permisos activos

### Operaciones

- Ver perfil completo
- Editar perfil (si tiene permisos)
- Cerrar sesion
- Cambio de contrasena (futuro)

### API de Perfil

```
GET /api/auth/me  — Obtener datos del usuario autenticado
PUT /api/auth/me  — Actualizar perfil
```

---

## Diagrama de Relaciones entre Modulos

```
                    ┌──────────────┐
                    │  Auth (JWT)  │
                    └──────┬───────┘
                           │
                    ┌──────┴───────┐
                    │  Dashboard   │
                    └──────┬───────┘
                           │
        ┌──────────┬───────┼───────┬──────────┬──────────┐
        │          │       │       │          │          │
   ┌────┴───┐ ┌───┴──┐ ┌──┴──┐ ┌──┴──┐ ┌────┴───┐ ┌───┴────┐
   │Cartillas│ │Eventos│ │Insignias│ │Admin│ │Soporte│ │Config  │
   └────┬───┘ └───┬──┘ └──┬──┘ └──┬──┘ └────┬───┘ └───┬────┘
        │         │       │       │          │         │
        └─────────┴───────┴───────┴──────────┴─────────┘
                           │
                    ┌──────┴───────┐
                    │  SQL Server  │
                    │   (BITSAC)   │
                    └──────────────┘
```

---

## Permisos del Sistema

| Permiso | Descripcion | Modulos afectados |
|---------|-------------|-------------------|
| `personal.ver` | Ver personal | Personal, Grados |
| `personal.crear` | Crear personal | Personal |
| `catalogos.ver` | Ver catalogos | Catalogos |
| `catalogos.editar` | Editar catalogos | Catalogos |
| `roles.ver` | Ver roles | Roles |
| `roles.editar` | Editar roles | Roles |
| `lugares_servicio.ver` | Ver lugares | Lugares |
| `rutas.ver` | Ver rutas | Rutas |
| `eas.ver` | Ver EAS | EAS |
| `moviles.ver` | Ver moviles | Moviles |
| `moviles.asignar` | Asignar moviles | Asignaciones |
| `cartillas.ver` | Ver cartillas | Cartillas |
| `cartillas.generar` | Generar cartillas | Cartillas |
| `eventos.ver` | Ver eventos | Eventos |
| `eventos.crear` | Crear eventos | Eventos |
| `anuncios.ver` | Ver anuncios | Anuncios |
| `anuncios.crear` | Crear anuncios | Anuncios |
| `insignias.ver` | Ver insignias | Insignias |
| `soporte.ver` | Ver soporte | Soporte |
| `soporte.gestionar` | Gestionar soporte | Soporte |
| `configuracion.ver` | Ver configuracion | Configuracion |
| `configuracion.editar` | Editar configuracion | Configuracion |
| `admin.ver` | Ver administracion | Admin (acceso general) |

---

**Jorge Luis Calderon Aguirre**
SEGURA EP - Guayaquil, Ecuador
Junio 2026
