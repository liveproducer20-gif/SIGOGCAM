# SIGO-GCAM — Documentación Completa de Módulos

**Plataforma:** BITSAC/SIGO-GCAM — Sistema Inteligente de Gestión Operativa
**Organizacion:** SIGO WORKING TECHNOLOGIES
**Fecha de inicio:** 1 de junio de 2026
---

## ÍNDICE

1. [Auth — Autenticación](#1-auth--autenticación)
2. [Dashboard — Panel Principal](#2-dashboard--panel-principal)
3. [Cartillas — Generador de Reportes](#3-cartillas--generador-de-reportes)
4. [Eventos y Anuncios](#4-eventos-y-anuncios)
5. [Insignias — Sistema de Logros](#5-insignias--sistema-de-logros)
6. [Administración](#6-administración)
7. [Soporte / Alertas](#7-soporte--alertas)
8. [Configuración — Roles y Permisos](#8-configuración--roles-y-permisos)
9. [Profile — Perfil de Usuario](#9-profile--perfil-de-usuario)

---

## 1. Auth — Autenticación

**Archivos:** `auth_scr.dart`, `auth_api.dart`

### 1.1 Screen: AuthScr

**Layout responsivo:**
- **Desktop (≥900px):** Panel dividido — imagen a la izquierda (flex:5), formulario a la derecha (flex:4)
- **Mobile (<900px):** Solo el formulario

### 1.2 Panel de Imagen (desktop)
- Imagen de fondo `assets/img/auth_bg.jpg` con gradiente overlay azul institucional
- Texto superpuesto:
  - Título: "Sistema Inteligente de Gestión Operativa"
  - Subtítulo: "Cuerpo de agentes de control Municipal de Guayaquil"
  - Marca: "SIGO-GCAM"
  - Lema: "Lealtad, Valor, Orden"

### 1.3 Formulario de Login

| Campo | Tipo | Obligatorio | Validación |
|-------|------|-------------|------------|
| Correo institucional | TextField (email) | Sí | Debe tener `@` |
| Contraseña | TextField (obscureText con toggle) | Sí | Mínimo 1 carácter |

**Botones:**
- "Iniciar sesión" — ElevatedButton, deshabilitado durante carga

**Comportamiento:**
- Password toggle: icono visibilidad/ocultar
- Enter en contraseña ejecuta login
- Empty fields → SnackBar: "Ingrese el correo institucional y la cédula como contraseña"
- Loading state: texto cambia a "Ingresando...", botón deshabilitado

### 1.4 API: AuthApi

| Endpoint | Método | Body | Response |
|----------|--------|------|----------|
| `auth/login` | POST | `{correo, password}` | `{usuario: {...}, token: "..."}` |

**Flujo login:**
1. POST `auth/login` con correo y password
2. Extrae token y guarda en `AuthSession.setToken()`
3. Parsea `AppUser` desde `usuario` del response
4. Guarda usuario con `AuthSession.setUser()`
5. Navega a `DashScr(user: user)` con `pushReplacement`

**Error handling:**
- Sin usuario en response → Exception con `mensaje` del backend
- Sin token → "Login sin token de sesión"
- Cualquier error → SnackBar con mensaje

**Footer:**
- Logo `assets/img/sigo_gcam.png`
- Versión mostrada desde `AppCnst.appVer`

---

## 2. Dashboard — Panel Principal

**Archivos:** `dash_scr.dart`, `wdg/side_menu_wdg.dart`, `wdg/side_menu_config.dart`, `wdg/side_menu_api.dart`, `wdg/top_bar_wdg.dart`, `wdg/dev_card_wdg.dart`, `wdg/page_ttl_wdg.dart`

### 2.1 Screen: DashScr

**Parámetros:** `AppUser user`

**Layout responsivo:**
- **Desktop (≥tablet):** `_WebDash` — side menu colapsable + contenido IndexedStack
- **Mobile:** `_MobDash` — TopBar + grid de cards de navegación

### 2.2 Side Menu (Desktop)

**Secciones del menú:**

| Sección | Items |
|---------|-------|
| MENÚ PRINCIPAL | Dashboard, Eventos y anuncios, Cartillas, Mis insignias |
| OPERATIVO | Servicios (no disponible), Operaciones (no disponible) |
| ANÁLISIS | Reportes (no disponible), Estadísticas (no disponible) |
| CONFIGURACIÓN | Administración, Roles permisos y estructura |
| SOPORTE | Alertas / Soporte (con badge) |

**SideMenuDestination enum:**
`dashboard`, `events`, `booklets`, `badges`, `services`, `operations`, `reports`, `statistics`, `administration`, `rolesPermisos`, `support`, `custom`

**Permisos por destino:**
- Eventos: `['eventos.ver', 'eventos.ver_convocado']`
- Cartillas: `['cartillas.ver', 'cartillas.generar']`
- Insignias: `['insignias.ver']`
- Administración: `['administracion.ver']`
- Roles: `['configuracion.roles.gestionar']`
- Soporte: sin permisos requeridos (siempre visible)

**Funcionalidades del menú:**
- Header con logo SIGO-GCAM y botón colapsar/expandir
- Menú animado (280px abierto, 72px cerrado)
- Tooltips en modo colapsado
- Badges con contador (soporte)
- Items no disponibles muestran candado + snackbar
- User card con popup: Mi perfil, Mi cuenta, Estado, Información de sesión, Personalización
- Logout con confirmación

### 2.3 User Card (Side Menu)

**Popup menu:**
- **Mi perfil:** Abre `ProfileDialog(editMode: false)`
- **Mi cuenta:** Abre `ProfileDialog(editMode: true)`
- **Estado:** Selector de disponibilidad (En línea, Ausente, Ocupado, Invisible)
- **Información de sesión:** Muestra inicio de sesión, último acceso, dispositivo, tiempo activo
- **Personalización:** Placeholder (próximamente)

**Avatar:** Iniciales del nombre o foto de perfil, indicador de presencia (punto de color)

### 2.4 TopBarWdg

- AppBar con color `AppThm.priClr`
- Título configurable
- Leading opcional (botón atrás)
- Actions: `ProfileMenuWdg` (avatar con badge de notificaciones)

### 2.5 Notificaciones

**Dialog de notificaciones (_NotifDialog):**
- Carga eventos + anuncios
- Filtra por `notificar == true` y lectura
- Cada notificación: ícono tipo (Evento/Anuncio), título, subtitle, chip de tipo
- Click → detail dialog con campos completos
- Soporta imágenes (base64) y PDFs
- Marca como leída con `NotifReadStore`

### 2.6 Navegación Mobile

Grid responsive de cards:
- 1 columna si <720px
- 2 columnas si 720-1080px
- 3 columnas si >1080px
- Cada card: ícono, título, estado (Disponible/En desarrollo), badge
- Click navega a la pantalla correspondiente

### 2.7 API del Menú

| Endpoint | Método | Response |
|----------|--------|----------|
| `configuracion/mi-estructura` | GET | Lista de nodos del menú del usuario |

**SideMenuConfig.fromApi:** Parsea la estructura del backend, mapea códigos a `SideMenuDestination`, aplica permisos del usuario.

---

## 3. Cartillas — Generador de Reportes

**Archivos:** `crt_home_scr.dart`, `mdl/crt_models.dart`, `mdl/crt_enums.dart`, `mdl/crt_special_models.dart`, `mdl/crt_type_item.dart`, `svc/crt_api.dart`, `svc/crt_catalog.dart`, `svc/crt_text_generator.dart`, `svc/crt_special_text_generator.dart`, `svc/colaboracion_ciudadana_text.dart`, `svc/otras_cartillas_text.dart`, + 14 archivos de formularios

### 3.1 Screen: CrtHomeScr

**Layout responsivo:**
- **Wide (≥1050px):** Dos paneles lado a lado (formulario + vista previa)
- **Tablet (800-1050px):** Formulario arriba, preview abajo
- **Mobile (<800px):** Igual que tablet pero más compacto

### 3.2 Tipos de Cartilla Disponibles

| ID | Nombre | Icono | Formulario |
|----|--------|-------|------------|
| `formacion_entrante` | Formación entrante | login_outlined | FormacionEntranteRedesign |
| `formacion_saliente` | Formación saliente | logout_outlined | FormacionSalienteRedesign |
| `otras_cartillas` | Otras cartillas | dashboard_customize_outlined | OtrasCartillasForm |
| `desalojo_vendedores` | Desalojo de vendedores autónomos no regularizados | storefront_outlined | DesalojoForm |
| `punto_martillo` | Punto martillo | gavel_outlined | PuntoMartilloForm |
| `rondas_disuasivas` | Rondas disuasivas | directions_walk_outlined | RondaDisuasivaForm |
| `retiro_temporal` | Retiro temporal | backup_outlined | RetiroTemporalForm |
| `requerimiento` | Requerimiento | receipt_long_outlined | RequerimientoForm |
| `colaboracion_entidades` | Colaboración con otras entidades | groups_outlined | ColaboracionEntidadesForm |
| `colaboracion_ciudadana` | Colaboración ciudadana | people_outlined | ColaboracionCiudadanaForm |
| `permiso_ausentismo` | Permiso de ausentismo | logout_outlined | AusentismoForm |

### 3.3 Modelos

**TipoModuloCartilla (13 módulos):**
`eas`, `motorizado`, `k9`, `ambiente`, `filaPedestre`, `administrativo`, `ciclista`, `conductor`, `palacio`, `cuadrante`, `apoyoSeguridadCiudadana`, `radioperador`, `supervision`

**TipoCartilla (26 tipos):**
Todos los tipos con `label` y `autoCausa` (tipos con causa automática)

**Jornada:** `matutina` (06:00-14:00), `vespertina` (14:00-22:00), `amanecida` (22:00-06:00)

**RolMovil:** `jp`, `conductor`, `auxiliar`

### 3.4 Formulario Desalojo (Ejemplo representativo)

**Sección 1 — Información del servicio:**
| Campo | Tipo | Opciones |
|-------|------|----------|
| Tipo de Servicio | Dropdown | PEDESTRE, MOTORIZADO, K9, EAS, TURISMO, CICLISTA, ADMINISTRATIVO, AMBIENTE, ENCARGADO, GESTION DE RIESGOS, SUPERVISION, RADIOPERADOR |
| Distrito | Dropdown (cargado de API) | Lista de distritos |
| Hora de Ingreso | TimePicker | Automática según hora |
| Hora de Salida | Calculada | +8.5 horas |
| Dirección general | TextField | |
| Circuito/EAS | Dropdown (si servicio=EAS/RADIOPERADOR) | 12 estaciones EAS |
| Móviles en circulación | FilterChip (si EAS) | Cargados de API |
| Número de ACM | TextField | Default: "1" |

**Sección 2 — Detalle del desalojo:**
| Campo | Tipo |
|-------|------|
| Dirección del desalojo | TextField |
| ¿Los vendedores se muestran agresivos? | Checkbox |
| ¿Se necesita colaboración de otro móvil? | Checkbox |
| Novedades adicionales | TextField multiline |

### 3.5 EAS Stations (12 estaciones)

| Código | Nombre | Dirección |
|--------|--------|-----------|
| ECO 1 | URDESA | AV. VICTOR EMILIO ESTRADA Y CIRCUNVALACIÓN SUR |
| ECO 2 | LOMAS DE URDESA | AV. CERROS Y LOMAS DE URDESA |
| ECO 3 | KENNEDY VIEJA | AV. FRANCISCO URBINA Y AV. DEL PERIODISTA |
| ECO 4 | KENNEDY NUEVA | AV. JOSE SANTIAGO CASTILLO Y VICTOR HUGO |
| ECO 5 | FAE/ATARAZANA | AV. AL RAUL COUSIN Y CRNL LUIS LOPES |
| ECO 6 | PUERTO SANTA ANA | PUERTO SANTA ANA |
| ECO 7 | SAMANES | AV. TEODORO ALVARADO OLEAS |
| ECO 8 | PARQUE CENTENARIO | CALLE LORENZO DE GARAICOA Y VELEZ |
| ECO 9 | PLAZA SAN FRANCISCO | AV. 9 DE OCTUBRE Y PEDRO CARBO |
| ECO 10 | VIA A LA COSTA | CDLA. TERRANOSTRA |
| ECO 11 | BARRIO CENTENARIO | AV. DOLORES SUCRE Y MARACAIBO |
| ECO 12 | CEIBOS | DR ALBERTO DACACH Y AV 15AVA NO |

### 3.6 CrtTextGenerator

Genera el texto formateado estilo WhatsApp para cada tipo de cartilla:

**Formato estándar:**
```
*CUERPO DE AGENTES DE CONTROL MUNICIPAL*
*REPORTE DE [TIPO]*
*DISTRITO:* #5 MODELO
*CIRCUITO:* [ECO X - NOMBRE]
*HORARIO:* HH:MM - HH:MM
*HORA:* HH:MM
*FECHA:* DD/MM/YYYY
*DIRECCIÓN:* [dirección]
*CAUSA:* [causa]

[Buenos días/buenas tardes], permiso Sr. [Jefe Nombre] Jefe de Control Municipal.

Muy respetuosamente me permito informar que [procedimiento].

[Detalle]

*REPORTA:*
*CP:* [conductor]
*JP:* [JP]
*Aux.:* [auxiliar]

*"LEALTAD, VALOR Y ORDEN"*

*ADJUNTO FOTOGRAFÍA:*
```

**Flujo de generación:**
1. Usuario selecciona tipo de cartilla → abre formulario específico
2. Llena campos del formulario
3. Vista previa se actualiza en tiempo real (debounce 250ms)
4. Click "GENERAR":
   - POST `cartillas` con contenido, tipo, causa, datos
   - Recibe `totalCartillasGeneradas` + posible `insigniaDesbloqueada`
   - Copia texto al portapapeles
   - Abre share sheet (`share_plus`)
   - Si insignia desbloqueada → dialog de felicitación
   - Vuelve a selector de tipos

### 3.7 API: CrtApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `cartillas/catalogos-operativos` | GET | Catálogos operativos |
| `cartillas/temp/cp` | GET/PUT | CP temporal (guardar/cargar) |
| `cartillas/temp/policia` | GET/PUT | Policía temporal |
| `cartillas/servidores-policiales?easId=` | GET | Servidores policiales por EAS |
| `cartillas/servidores-policiales` | POST | Crear servidor policial |
| `cartillas/jefe-control-municipal` | GET | Nombre del jefe |
| `cartillas/eas-direcciones?easId=` | GET | Direcciones por EAS |
| `cartillas/eas-direcciones` | POST | Crear dirección |
| `catalogos/DISTRITOS` | GET | Lista de distritos |
| `cartillas/asignaciones-eas-moviles` | GET | Asignaciones EAS-móviles |
| `admin/catalogos/TIPOS_SERVICIO_LUGAR` | GET | Tipos de servicio |
| `cartillas/eas` | GET | Estaciones EAS |

### 3.8 Dotación EAS (hardcoded)

Cada EAS tiene móviles predefinidos con roles JP, Conductor, Auxiliar. ECO 12 (CEIBOS) tiene 3 móviles (187, 188, 189).

---

## 4. Eventos y Anuncios

**Archivos:** `evt/scr/evt_home_scr.dart`, `evt/data/api/evt_api.dart`, `evt/mdl/evt_mdl.dart`, `evt/new/scr/evt_new_scr.dart`, `evt/new/mdl/evt_new_mdl.dart`, `evt/new/ctl/evt_new_ctl.dart`, `evt/new/stp/*.dart` (5 steps), `evt/ann/mdl/ann_mdl.dart`, `evt/ann/svc/ann_svc.dart`, `evt/svc/evt_svc.dart`, `evt/wdg/*.dart`

### 4.1 Screen: EvtHomeScr

**Tabs:**
1. **Eventos** — Lista de eventos con filtros y CRUD
2. **Anuncios** — Lista de anuncios con gestión

**Parámetros:** `AppUser user`, `int initialTab`, `int? focusAnnId`, `bool showBack`

### 4.2 Lista de Eventos (Admin)

**Filtros (EvtFilWdg):**
| Filtro | Tipo | Opciones |
|--------|------|----------|
| Buscar | TextField (debounce 300ms) | Nombre, tipo, estado |
| Estado | Dropdown | Todos, Nuevo, En curso, Finalizado, Cancelado |
| Tipo | Dropdown | Todos + tipos del catálogo |
| Lugar | TextField (debounce 300ms) | Búsqueda parcial |
| Prioridad | Dropdown | Todas, Normal, Importante, Urgente |
| Fecha | DatePicker | Fecha específica |

**Botones admin:**
- "Nuevo evento" → navega a `EvtNewScr`
- Editar evento → dialog `_EvtEditDlg`
- Eliminar evento → confirmación
- Cambiar estado

### 4.3 Modelo EvtMdl

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID del evento |
| nom | String | Nombre del evento |
| tipoId | int | ID del tipo |
| tipo | String | Nombre del tipo |
| fecha | String | Fecha formateada |
| fechaFin | String | Fecha fin formateada |
| fechaInicioRaw | String | ISO8601 |
| fechaFinRaw | String | ISO8601 |
| hora | String | Hora |
| lugar | String | Dirección/ubicación |
| descripcion | String | Descripción |
| prioridad | String | Normal/Importante/Urgente |
| imgUrl | String? | URL de imagen |
| pdfNombre | String? | Nombre del PDF |
| pdfUrl | String? | URL del PDF |
| notificar | bool | Si genera notificación |
| convocados | int | Personas convocadas |
| confirmados | int | Personas confirmadas |
| estado | String | Estado actual |

### 4.4 Crear Evento (EvtNewScr)

**Wizard de 5 pasos:**

| Paso | Widget | Campos |
|------|--------|--------|
| 1. Información | EvtInfStp | Nombre, Tipo (dropdown catálogo), Fecha, Hora inicio, Hora fin, Lugar (Google Maps URL), Descripción, Prioridad |
| 2. Personal | EvtPrsStp | Selector de personal (PrsSlcDlg) |
| 3. Publicación | EvtPubStp | Publicar ahora (toggle), Enviar notificación (toggle) |
| 4. Preview | EvtPreStp | Vista previa del evento |
| 5. Validación | EvtValStp | Resumen final y confirmación |

**EvtNewMdl (modelo del wizard):**
- `nom`, `tipoId`, `tipo`, `lugar`, `fechaTxt`, `fecha`, `horaIni`, `horaFin`, `desc`
- `pubAhora`, `enviarNot`
- `prioridad`, `imagenNombre`, `imagenUrl`, `pdfNombre`, `pdfUrl`
- `fecExp`, `fecExpTxt`
- `prsIds`, `prsItems`

### 4.5 API: EvtApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `catalogos/TIPOS_EVENTO` | GET | Tipos de evento |
| `personal/operativos` | GET | Personal operativo |
| `eventos` | GET | Lista eventos (params: personalId, marcarVisto) |
| `eventos` | POST | Crear evento |
| `eventos/archivos` | POST (bytes) | Subir archivo |
| `eventos/$id/estado` | PUT | Cambiar estado |
| `eventos/$id` | PUT | Actualizar evento |
| `eventos/$id` | DELETE | Eliminar evento |

**Upload de archivos:** DataURL → base64 decode → POST bytes a `eventos/archivos` → devuelve `{ruta: "..."}`

### 4.6 Anuncios (AnnMdl)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID |
| ttl | String | Título |
| desc | String | Descripción |
| img | String | Asset local |
| imgNombre | String? | Nombre archivo |
| imgUrl | String? | URL imagen |
| fecPub | DateTime | Fecha publicación |
| fecExp | DateTime? | Fecha expiración |
| personalIds | List<int> | IDs destinatarios |
| prioridad | String | Prioridad |
| publicado | bool | Publicado |
| notificar | bool | Notificar |

### 4.7 API: AnnSvc

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `anuncios` | GET | Lista anuncios (con cache 30s) |
| `anuncios/imagenes` | POST (bytes) | Subir imagen |
| `anuncios` | POST | Crear anuncio |
| `anuncios/$id` | PUT | Actualizar |
| `anuncios/$id/publicado` | PUT | Cambiar publicado |
| `anuncios/$id` | DELETE | Eliminar |

---

## 5. Insignias — Sistema de Logros

**Archivos:** `ins_home_scr.dart`, `ins_api.dart`, `ins_mdl.dart`, `badge_catalog.dart`, `ins_achievement_theme.dart`, `ins_widgets.dart`, `ins_share_modal.dart`, `ins_icn_wdg.dart`, `achievement_unlocked_card.dart`, `achievement_image_export.dart`, `achievement_image_export_io.dart`, `achievement_image_export_web.dart`

### 5.1 Screen: InsHomeScr

**Secciones:**
1. **Header** — Título "Mis insignias" + descripción
2. **AchievementsTimeline** — Timeline visual de todas las insignias
3. **ProgressSummaryCards** — Desbloqueadas, pendientes, cartillas restantes, nivel actual
4. **AchievementProgressCard** — Barra de progreso + botón compartir
5. **DashboardSection** — Leaderboard + tarjetas top users
6. **AchievementTabs** — Tabs de insignias por categoría

**Carga de datos:**
1. `api.obtenerTodas()` — Todas las insignias del catálogo
2. `api.obtenerUsuarioInsignias(userId)` — Insignias desbloqueadas por el usuario
3. `api.obtenerProgreso(userId)` — Progreso del usuario
4. `api.obtenerRanking()` — Ranking de usuarios

### 5.2 Modelo: InsMdl

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID |
| codigo | String | Código único |
| titulo | String | Nombre de la insignia |
| descripcion | String | Descripción |
| metaCartillas | int | Meta de cartillas para desbloquear |
| categoria | String | Categoría |
| icono | String | Código del icono |
| desbloqueada | bool | Si fue desbloqueada |
| totalAlDesbloquear | int? | Total de cartillas al desbloquear |
| fechaDesbloqueo | String? | Fecha de desbloqueo |

**InsProgresoMdl:**
| Campo | Tipo |
|-------|------|
| totalCartillasGeneradas | int |
| ultimaInsignia | String? |
| proximaInsignia | String? |
| metaProxima | int? |
| cartillasFaltantes | int |
| porcentajeProgreso | int |

**CartillaRegistroMdl (respuesta al generar):**
| Campo | Tipo |
|-------|------|
| cartillaId | int |
| totalCartillasGeneradas | int |
| insigniaDesbloqueada | InsigniaDesbloqueadaMdl? |
| advertencia | String? |

### 5.3 Badge Catalog (48 insignias, 10 niveles)

| Nivel | Nombre | Rango de Cartillas | Insignias |
|-------|--------|-------------------|-----------|
| 1 | Amateur | 5 - 45 | 5 (Agente Amateur → Agente Comprometido) |
| 2 | Operativo | 60 - 150 | 5 (Operador Estratégico → Especialista Operativo) |
| 3 | Profesional | 180 - 350 | 5 (Experto en Reportes → Super Agente) |
| 4 | Avanzado | 405 - 675 | 5 (El Mejor de los Papamike → Tirador de Incidencias) |
| 5 | Experto | 755 - 1125 | 5 (Perito de Cartillas → Superhéroe Operativo) |
| 6 | Élite | 1230 - 1700 | 5 (Merodeador de Incidencias → Maestro Consumado) |
| 7 | Leyenda | 1830 - 2400 | 5 (Leyenda Viviente → Arquitecto Operativo) |
| 8 | Supremo | 2555 - 3225 | 5 (Director de Operaciones → Titán de las Cartillas) |
| 9 | Mítico | 3405 - 3975 | 4 (Gran Centinela → Maestro de Estrategias) |
| 10 | Máximo | 4175 - 4805 | 4 (Gran Comisionado → Emblema Supremo) |

### 5.4 LevelTheme (temas por nivel)

Cada nivel tiene un tema completo de colores:
- primaryColor, accentColor, bgGradient, borderColor
- progressColor, glowColor, buttonColor
- confettiColors, particleColors (para animaciones)

### 5.5 API: InsApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `cartillas` | POST | Registrar cartilla (retorno: cartillaId, total, insignia desbloqueada) |
| `insignias` | GET | Todas las insignias |
| `usuarios/$id/insignias` | GET | Insignias del usuario |
| `usuarios/$id/progreso-insignias` | GET | Progreso |
| `insignias/ranking` | GET | Ranking de usuarios |

### 5.6 Funcionalidades Especiales

- **Compartir:** Genera imagen de logro para compartir (ins_share_modal.dart)
- **Exportar imagen:** Plataforma específica (io/web)
- **Auto-refresh:** Cuando la pantalla vuelve a estar visible
- **Pull-to-refresh:** Recarga datos al deslizar

---

## 6. Administración

**Archivos:** `adm_home_scr.dart`, `adm_api.dart`, `adm_personal_tab.dart`, `adm_catalogos_tab.dart`, `adm_roles_tab.dart`, `adm_lugares_tab.dart`, `adm_rutas_tab.dart`, `adm_grados_tab.dart`, `adm_eas_tab.dart`, `adm_moviles_tab.dart`, `adm_asignaciones_tab.dart`, `adm_crud_tab.dart`, `adm_lazy_tab.dart`, `adm_widgets.dart`, `adm_helpers.dart`, `adm_export.dart`, `adm_export_io.dart`, `adm_export_web.dart`, `adm_design_tokens.dart`

### 6.1 Screen: AdmHomeScr

**Tabs disponibles (según permisos del usuario):**

| Tab | Permiso | Widget |
|-----|---------|--------|
| Personal | `personal.ver` | PersonalTab |
| Catálogos | `catalogos.ver` | CatalogosTab |
| Roles | `roles.ver` | RolesTab |
| Lugares | `lugares_servicio.ver` | LugaresTab |
| Rutas | `rutas.ver` | RutasTab |
| Grados | `personal.ver` | GradosTab |
| EAS | `eas.ver` | EasTab |
| Móviles | `moviles.ver` | MovilesTab |
| Asignaciones | `moviles.asignar` | AsignacionesTab |

**Layout:**
- Header con tabs horizontales (scrollable)
- Contenido en TabBarView
- Responsive: submenu horizontal scrollable en mobile

### 6.2 CRUD Genérico (AdmCrudTab)

Todos los tabs usan un patrón CRUD genérico con:
- **Tabla paginada** con búsqueda (debounce 350ms)
- **Botón "Nuevo"** → dialog de creación
- **Acciones por fila:** Editar, Activar/Desactivar, Eliminar
- **Paginación:** Anterior/Siguiente, total de registros
- **Búsqueda:** Server-side con parámetro `search`

### 6.3 API: AdmApi

**Personal:**
| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `personal` | GET/POST | Lista/Crear |
| `personal?page=&limit=&search=` | GET | Paginado |
| `personal/$id` | PUT | Actualizar |
| `personal/$id/estado` | PUT | Activar/Desactivar |
| `personal/$id` | DELETE | Eliminar |

**Catálogos:**
| Endpoint | Método |
|----------|--------|
| `admin/catalogos` | GET |
| `admin/catalogos/$codigo` | GET (detalles) |
| `admin/catalogos/$codigo` | POST (crear detalle) |
| `admin/catalogos/detalles/$id` | PUT |
| `admin/catalogos/detalles/$id/estado` | PUT |
| `admin/catalogos/detalles/$id` | DELETE |

**Roles:**
| Endpoint | Método |
|----------|--------|
| `admin/roles` | GET/POST |
| `admin/roles?page=&limit=&search=` | GET |
| `admin/roles/$id` | PUT |
| `admin/roles/$id/estado` | PUT |
| `admin/roles/$id` | DELETE |
| `admin/permisos` | GET |

**Lugares de Servicio:**
| Endpoint | Método |
|----------|--------|
| `admin/lugares-servicio` | GET/POST |
| `admin/lugares-servicio/$id` | PUT |
| `admin/lugares-servicio/$id/estado` | PUT |
| `admin/lugares-servicio/$id` | DELETE |

**Rutas:**
| Endpoint | Método |
|----------|--------|
| `admin/rutas` | GET/POST |
| `admin/rutas/$id` | PUT |
| `admin/rutas/$id/estado` | PUT |
| `admin/rutas/$id` | DELETE |

**Grados:**
| Endpoint | Método |
|----------|--------|
| `admin/grados` | GET/POST |
| `admin/grados/$id` | PUT |
| `admin/grados/$id/estado` | PUT |
| `admin/grados/$id` | DELETE |

**EAS:**
| Endpoint | Método |
|----------|--------|
| `admin/eas` | GET/POST |
| `admin/eas?page=&limit=&search=` | GET |
| `admin/eas/$id` | PUT |
| `admin/eas/$id/estado` | PUT |
| `admin/eas/$id` | DELETE |

**Móviles:**
| Endpoint | Método |
|----------|--------|
| `admin/moviles` | GET/POST |
| `admin/moviles?page=&limit=&search=` | GET |
| `admin/moviles/$id` | PUT |
| `admin/moviles/$id/estado` | PUT |
| `admin/moviles/$id` | DELETE |

**Asignaciones Móvil-EAS:**
| Endpoint | Método |
|----------|--------|
| `admin/movil-eas-asignaciones` | GET/POST |
| `admin/movil-eas-asignaciones?page=&limit=&search=` | GET |
| `admin/movil-eas-asignaciones/$id` | PUT |
| `admin/movil-eas-asignaciones/$id` | DELETE |

**Mantenimiento de Móviles:**
| Endpoint | Método |
|----------|--------|
| `admin/dashboard/mantenimiento` | GET |
| `admin/moviles/$id/mantenimientos` | GET |
| `admin/moviles/$id/mantenimientos` | POST |

### 6.4 Exportación (adm_export.dart)

- **CSV:** Genera CSV con columnas y exporta a archivo
- **Excel:** Genera XLS
- **PDF:** Impresión de página admin (solo web)

---

## 7. Soporte / Alertas

**Archivos:** `sup_home_scr.dart`, `sup_api.dart`, `sup_mdl.dart`, `sup_report_form.dart`, `sup_ticket_detail.dart`, `sup_realtime.dart`, `sup_badges.dart`

### 7.1 Screen: SupHomeScr

**Dos vistas según rol:**
- **Admin:** Vista de monitoreo con tabla, filtros, stats, detalle side panel
- **Usuario:** 3 tabs (Mis reportes, Nuevo reporte, Historial)

### 7.2 Vista Admin

**Stats Row (6 tarjetas):**
| Stat | Color | Descripción |
|------|-------|-------------|
| Total alertas | Azul | Conteo total |
| Críticas | Rojo | Prioridad crítica |
| Altas | Naranja | Prioridad alta |
| Medias | Amarillo | Prioridad media |
| Bajas | Verde | Prioridad baja |
| Respuesta promedio | Púrpura | Tiempo promedio |

**Filtros:**
| Filtro | Tipo | Opciones |
|--------|------|----------|
| Buscar | TextField (debounce 350ms) | Título, usuario, código |
| Estado | Dropdown | Todos, Nuevo, En proceso, Pendiente, Resuelto, Cancelado |
| Prioridad | Dropdown | Todos, Crítica, Alta, Media, Baja |
| Módulo | Dropdown | Todos + 14 módulos |
| Filtros avanzados | Dialog | Usuario, Área, Fecha (Hoy, 7 días, 30 días, Personalizado) |

**Tabla (desktop):**
Columnas: Estado, Título, Usuario, Módulo, Prioridad, Fecha, Acciones

**Detalle (SupportTicketDetail):**
- Información del ticket
- Comentarios (públicos e internos)
- Historial de cambios
- Formulario de comentario
- Cambio de estado/prioridad/asignación

### 7.3 Vista Usuario

**Tabs:**
1. **Mis reportes** — Lista de reportes propios con estado
2. **Nuevo reporte** — Formulario de creación
3. **Historial** — Reportes cerrados/resueltos

### 7.4 Formulario de Reporte (SupportReportForm)

| Campo | Tipo | Validación |
|-------|------|------------|
| Título del problema | TextField | Mínimo 5 caracteres, máx 200 |
| Módulo relacionado | Dropdown | Obligatorio |
| Detalle del problema | TextField multiline | Mínimo 20 caracteres, máx 3000 |
| Imagen evidencia | FilePick | PNG/JPG/WEBP, máx 5MB |

**Módulos disponibles:**
Eventos, Cartillas, Personal, Roles, Lugares, Rutas, Grados, EAS, Móviles, Asignaciones, Insignias, Reportes, Configuración, General

### 7.5 Modelo: SupportTicket

| Campo | Tipo | Descripción |
|-------|------|-------------|
| id | int | ID |
| code | String | Código de alerta |
| title | String | Título |
| description | String | Descripción |
| userName | String | Usuario reporter |
| role | String | Rol |
| area | String | Área |
| module | String | Módulo |
| priority | String | Crítica/Alta/Media/Baja |
| status | String | Nuevo/En proceso/Pendiente/Resuelto/Cancelado |
| image | String? | Ruta de imagen |
| assignedName | String? | Asignado a |
| createdAt | DateTime | Fecha creación |
| updatedAt | DateTime | Última actualización |

**SupportComment:**
- id, userId, userName, role, text, internal (bool), createdAt

**SupportHistory:**
- userName, action, oldValue, newValue, createdAt

**SupportStats:**
- total, critical, high, medium, low, pending, averageMinutes

### 7.6 API: SupportApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `soporte` | GET | Lista paginada con filtros |
| `soporte/estadisticas` | GET | Estadísticas |
| `soporte/$id` | GET | Detalle + comentarios + historial |
| `soporte` | POST | Crear reporte |
| `soporte/imagenes` | POST (bytes) | Subir imagen |
| `soporte/$id` | PUT | Actualizar (estado, prioridad, asignación) |
| `soporte/$id/comentarios` | POST | Agregar comentario |
| `soporte/stream` | GET (SSE) | Server-Sent Events en tiempo real |

### 7.7 Realtime (SupportRealtime)

**Singleton** que comparte una conexión SSE entre dashboard y pantalla de soporte:
- Referencia counting (attach/detach)
- Reconexión progresiva: 5s → 10s → 20s → 40s → 60s → 120s
- Eventos: `data: ...` → stream de líneas
- En dashboard: recarga automática con debounce 350ms + snackbar
- En usuario: snackbar "Tu reporte de soporte fue actualizado"

---

## 8. Configuración — Roles y Permisos

**Archivos:** `config/config_editor_scr.dart`, `config/config_api.dart`, `config/config_mdl.dart`, `config/wdg/arbol_modulos_wdg.dart`, `config/wdg/panel_config_wdg.dart`, `config/wdg/preview_menu_wdg.dart`, `config/wdg/alcance_rol_wdg.dart`, `config/wdg/campos_rol_wdg.dart`, `config/wdg/versiones_wdg.dart`, `config/wdg/auditoria_wdg.dart`

### 8.1 Screen: ConfigEditorScr

**5 Tabs:**

| Tab | Widget | Descripción |
|-----|--------|-------------|
| Menú | _buildMenuEditor | Editor de menú por rol |
| Alcance | AlcanceRolWdg | Alcance de datos por rol |
| Campos | CamposRolWdg | Permisos de campos por rol |
| Versiones | VersionesWdg | Historial de versiones |
| Auditoría | AuditoriaWdg | Log de auditoría |

### 8.2 Editor de Menú (Tab 1)

**Layout desktop (≥1100px):** 3 paneles
1. **Árbol de módulos** (260px) — ArbolModulosWdg
2. **Panel de configuración** — PanelConfigWdg
3. **Preview del menú** (280px) — PreviewMenuWdg

**Funcionalidades:**
- Seleccionar rol → carga menú actual
- Agregar módulo al menú del rol
- Remover módulo del menú
- Editar item: etiqueta personalizada, nivel (0-2), orden, visible/oculto
- Guardar menú del rol
- Crear nuevo módulo (nombre, código, ruta, icono)

### 8.3 Modelos: Config

**ModuloModel:**
- id, nombre, codigo, icono, ruta, moduloPadreId, orden, activo

**RolModel:**
- id, nombre, codigo, activo

**RolMenuConfigModel:**
- id, rolId, moduloId, nivel, orden, visible, etiquetaPersonalizada, moduloNombre, moduloCodigo, icono, ruta

**ScopeModel:**
- id, rolId, modulo, alcance, entidad, condicionAdicional

**CampoPermisoModel:**
- id, rolId, campoId, puedeVer, puedeEditar, requerido, campoNombre, campoCodigo, tipoDato, entidad, seccion

**VersionModel:**
- id, rolId, version, datosJson, descripcion, creadoPor, creadoEn

**AuditoriaModel:**
- id, rolId, modulo, accion, detalle, usuarioId, datosAntiguos, datosNuevos, creadoEn

### 8.4 API: ConfigApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `configuracion/estructura` | GET | Módulos + roles |
| `configuracion/modulos` | GET | Lista módulos |
| `configuracion/modulos` | POST | Crear módulo |
| `configuracion/modulos/$id` | PUT | Actualizar módulo |
| `configuracion/modulos/$id` | DELETE | Eliminar módulo |
| `configuracion/modulos/$id/permisos` | GET | Permisos del módulo |
| `configuracion/roles/$id/menu` | GET | Menú del rol |
| `configuracion/roles/$id/menu` | PUT | Guardar menú del rol |
| `configuracion/roles/$id/alcance` | GET | Alcance del rol |
| `configuracion/roles/$id/alcance` | PUT | Guardar alcance |
| `configuracion/roles/$id/campos` | GET | Campos del rol |
| `configuracion/roles/$id/campos` | PUT | Guardar campos |
| `configuracion/roles/$id/versiones` | GET | Versiones |
| `configuracion/roles/$id/versiones` | POST | Crear versión |
| `configuracion/roles/$id/versiones/$vid/restaurar` | POST | Restaurar versión |
| `configuracion/auditoria` | GET | Auditoría (params: rolId, modulo, accion, limite) |
| `configuracion/campos-sistema` | GET | Campos del sistema |
| `configuracion/mi-estructura` | GET | Estructura del usuario actual |

---

## 9. Profile — Perfil de Usuario

**Archivos:** `profile/profile_menu_wdg.dart`, `profile/profile_api.dart`

### 9.1 ProfileMenuWdg

**Widget** que se integra en el TopBar de todas las pantallas:

**Popup menu:**
| Acción | Descripción |
|--------|-------------|
| Ver perfil | Abre ProfileDialog(editMode: false) |
| Editar perfil | Abre ProfileDialog(editMode: true) |
| Notificaciones | Callback onNotifications |
| Cerrar sesión | Callback onLogout |

**Avatar:**
- Foto de perfil (network) o iniciales
- Badge con contador de notificaciones no leídas
- Calcula notificaciones de: eventos (con `notificar`) + anuncios (publicados, dirigidos al usuario)

### 9.2 ProfileDialog

**Modos:**
- **Lectura (editMode: false):** Campos readonly
- **Edición (editMode: true):** Campos editables

**Campos:**

| Campo | Editable | Validación |
|-------|----------|------------|
| Nombres | No | — |
| Apellidos | No | — |
| Cédula | Sí | 10 dígitos |
| Correo institucional | Sí | Debe contener @ |
| Teléfono | Sí | — |
| Fecha de nacimiento | Sí (date picker) | — |
| Rol | No | Solo lectura |
| Estado operativo | No | Solo lectura |
| Foto de perfil | Sí (file picker) | — |

**Acciones:**
- "Editar" → habilita campos
- "Guardar" → valida → POST `personal/perfil/me` → cierra dialog con usuario actualizado
- "Cerrar" → cierra sin guardar
- "Cambiar foto" → file picker → actualiza preview

### 9.3 _ChangePasswordDialog

**Campos:**
| Campo | Tipo |
|-------|------|
| Vieja contraseña | TextField (obscureText) |
| Nueva contraseña | TextField (obscureText) |
| Verifique nueva contraseña | TextField (obscureText) |

**Cooldown:** Opción disponible cada 72 horas (showPasswordCooldownNotice)

### 9.4 API: ProfileApi

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `personal/perfil/me` | GET | Obtener perfil actualizado |
| `personal/perfil/me` | PUT | Actualizar perfil (cedula, correo, telefono, fechaNacimiento, fotoPerfilUrl) |
| `auth/change-password` | POST | Cambiar contraseña (oldPassword, newPassword, confirmPassword) |

---

## Notas Generales

### Arquitectura
- **State management:** StatefulWidgets con setState
- **API client:** ApiClient centralizado con manejo de tokens
- **Navegación:** Navigator push/pushReplacement
- **Responsive:** Breakpoints en AppResponsive (mobile/tablet/desktop)

### Patrones Comunes
- **Debounced search:** Timer de 250-350ms en campos de búsqueda
- **Cache:** AnnSvc usa cache de 30s con invalidación
- **Loading states:** CircularProgressIndicator o LinearProgressIndicator
- **Error handling:** try/catch con SnackBar
- **File upload:** DataURL → base64 → POST bytes
- **Exportación:** CSV/Excel/PDF con exportAdminCsv

### Permisos
Los permisos se evalúan con `user.hasPermission('modulo.accion')` y se usan para:
- Mostrar/ocultar tabs en Administración
- Habilitar/deshabilitar menú lateral
- Controlar acceso a funcionalidades CRUD
