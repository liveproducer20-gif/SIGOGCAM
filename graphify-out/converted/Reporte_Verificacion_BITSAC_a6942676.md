<!-- converted from Reporte_Verificacion_BITSAC.docx -->

Reporte de Verificación y Comprobación del Proyecto BITSAC
Fecha: 07/07/2026 14:15
================================================================================

# 1. Información General del Proyecto
Nombre del proyecto: BITSAC (SIGO-GCAM)
Descripción: Sistema Inteligente de Gestión Operativa para el Cuerpo de Agentes de Control Municipal de Guayaquil


# 2. Lo que Funciona Correctamente
## 2.1 Backend - Estructura y Arquitectura
- ✅ Arquitectura en 4 capas bien definida (Routes → Controllers → Services → Repositories)
- ✅ Separación de responsabilidades correcta y consistente en todos los módulos
- ✅ Uso de Express 5 (versión más reciente) con middlewares globales adecuados
- ✅ Manejo de errores global con códigos HTTP apropiados (400, 401, 403, 404, 413, 500)
- ✅ Sistema de auditoría funcional que registra acciones CRUD automáticamente
- ✅ Middleware de autenticación JWT con verificación de token y expiración
- ✅ Sistema RBAC con 3 funciones: requireAuth, requirePermission, requireAnyPermission
## 2.2 Backend - Módulos Funcionales
- ✅ Módulo de Autenticación: login con JWT (8h expiración), cambio de contraseña, hash bcrypt
- ✅ Módulo de Personal: CRUD completo, búsqueda, perfiles, cambio de estado, reset de contraseña
- ✅ Módulo de Eventos: CRUD, cambio de estado, convocatoria de personal, vista de confirmados
- ✅ Módulo de Anuncios: Publicación con asignación personal, expiración, notificaciones
- ✅ Módulo de Cartillas: Generación de reportes de novedades con formato SAC
- ✅ Módulo de Insignias: Sistema de gamificación con 15 insignias escalonadas
- ✅ Módulo de Administración: CRUD de catálogos, roles, permisos, lugares, EAS, móviles, asignaciones
- ✅ Vista de alertas de mantenimiento preventivo de móviles
## 2.3 Backend - Base de Datos
- ✅ Migraciones SQL con control de versiones (formato YYYYMMDD)
- ✅ Scripts idempotentes (usan IF ... COL_LENGTH para evitar errores en re-ejecución)
- ✅ Uso de vistas SQL Server para abstraer consultas complejas (vw_personal_detalle, vw_personal_operativo, etc.)
- ✅ Sistema RBAC completo con ~80 permisos en 24 módulos
- ✅ Transacciones SQL en operaciones críticas (crear/actualizar eventos con personal asociado)
- ✅ Integridad referencial con claves foráneas y índices únicos filtrados
## 2.4 Mobile - Estructura y UI
- ✅ Aplicación multi-plataforma (Android, iOS, Web, Windows, macOS, Linux)
- ✅ UI adaptativa responsiva (Web vs Mobile según ancho de pantalla)
- ✅ Pantalla de Login con validación de campos vacíos y ocultación de teclado
- ✅ Dashboard con menú lateral y módulos funcionales (Eventos, Cartillas, Insignias, Administración)
- ✅ Navegación con gestión de estado usando setState y mounted checks
- ✅ Manejo de errores con timeout y mensajes descriptivos al usuario
- ✅ Soporte nativo para web con implementaciones condicionales (stub vs web)
- ✅ Tema institucional consistente con colores SEGURA EP
## 2.5 Scripts y Herramientas
- ✅ Script de prueba de conexión ODBC con 8 variantes de conexión
- ✅ Script de auditoría de esquema SQL vs código fuente con fallback estático
- ✅ Parches para corrección de validación en login (auth_scr.dart)
# 3. Errores Detectados
## 3.1 CRÍTICOS
❌ [CRIT-01] Contraseña por defecto insegura
[Severidad: MEDIA]
El script reset_usuarios_seed.sql usa la cédula como contraseña inicial. Además, si la columna password_hash no existe, el login acepta la cédula como contraseña válida (validarClave, línea 275-285 de auth.routes.js).
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:275 | C:\\database\\*_reset_usuarios_seed.sql
❌ [CRIT-02] JWT_SECRET hardcodeado y expuesto
[Severidad: MEDIA]
El JWT_SECRET en .env es "sigo_bitsac_creado_Lunatics" y el fallback es "sigo_gcam_secret". El .env con datos reales está en el repositorio.
Ubicación: C:\\backend\\.env | C:\\backend\\src\\routes\\auth.routes.js:97
❌ [CRIT-03] Sin limitación de intentos de login
[Severidad: ALTA]
No hay rate limiting ni bloqueo por intentos fallidos en el endpoint /api/auth/login. Vulnerable a ataques de fuerza bruta.
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:15
❌ [CRIT-04] Inyección SQL potencial en admin.repository.js
[Severidad: MEDIA]
La función insertarBasico y cambiarActivo usan interpolación directa del nombre de tabla: INSERT INTO ${tabla}...
Ubicación: C:\\backend\\src\\repositories\\admin.repository.js:459-480
❌ [CRIT-05] Token JWT sin renovación ni refresh token
[Severidad: MEDIA]
El token expira en 8h sin mecanismo de refresh. Al expirar, el usuario pierde la sesión forzosamente.
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:95-99
## 3.2 GRAVES
❌ [ERR-01] Conexión ODBC sin pool
[Severidad: ALTA]
Cada operación de base de datos abre y cierra una conexión individual. Sin pool de conexiones, el rendimiento se degrada severamente con múltiples usuarios.
Ubicación: Todos los repositories
❌ [ERR-02] Error HTTP 500 en lugar de 404 en obtenerPerfil
[Severidad: MEDIA]
El controller de personal usa status(404) pero si el service lanza otro error (ej. BD caída), responde 500, lo cual es correcto, pero el mensaje de error expone detalles internos al cliente.
Ubicación: C:\\backend\\src\\controllers\\personal.controller.js:84-97
❌ [ERR-03] Falta sanitización de entrada en búsqueda
[Severidad: BAJA]
El endpoint de búsqueda usa LIKE con el texto directamente. Aunque el driver ODBC escapa parámetros, no hay validación de longitud mínima/máxima.
Ubicación: C:\\backend\\src\\repositories\\personal.repository.js:77-97
❌ [ERR-04] Sin validación de permisos en cambio de contraseña
[Severidad: MEDIA]
El endpoint /api/auth/change-password solo requiere autenticación (requireAuth) pero no verifica permisos adicionales.
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:120
❌ [ERR-05] Variables de entorno sin validación exhaustiva
[Severidad: MEDIA]
db.js valida DB_SERVER y DB_DATABASE, pero no valida DB_DRIVER, DB_ENCRYPT ni DB_CONNECTION_TIMEOUT.
Ubicación: C:\\backend\\src\\config\\db.js
## 3.3 MOBILE (Flutter/Dart)
❌ [MOB-01] Gestión de estado débil (solo setState)
[Severidad: ALTA]
Toda la app usa setState para manejo de estado. Sin Provider, BLoC, Riverpod ni ningún gestor de estado. Esto causa renderizados innecesarios y dificulta el mantenimiento.
Ubicación: Todos los StatefulWidget
❌ [MOB-02] AuthSession con singleton estático puro
[Severidad: MEDIA]
AuthSession es una clase con campos static. El token se pierde al cerrar la app. No persiste en SharedPreferences ni SecureStorage.
Ubicación: C:\\mobile\\lib\\core\\auth\\auth_session.dart
❌ [MOB-03] Sin manejo de errores HTTP granulares
[Severidad: MEDIA]
Todos los errores HTTP se tratan como Exception genérica. No hay distinción entre 401 (no autorizado), 403 (prohibido), 404, 500, etc.
Ubicación: C:\\mobile\\lib\\core\\api\\api_client.dart:138-169
❌ [MOB-04] Router vacío (app_rtr.dart sin implementación)
[Severidad: ALTA]
El archivo app_rtr.dart está completamente vacío. La navegación usa Navigator.pushReplacement imperativo en lugar de un router declarativo.
Ubicación: C:\\mobile\\lib\\core\\rtr\\app_rtr.dart
❌ [MOB-05] Sin autologout al recibir 401
[Severidad: ALTA]
Si el backend responde 401 (token expirado), la app no redirige automáticamente al login. El usuario ve un error genérico.
Ubicación: C:\\mobile\\lib\\core\\api\\api_client.dart
❌ [MOB-06] NotifReadStore usa Set en memoria (se pierde al cerrar app)
[Severidad: MEDIA]
Las notificaciones leídas solo se marcan en un Set estático en memoria. Al cerrar la app, se pierde el estado de leído.
Ubicación: C:\\mobile\\lib\\core\\notif\\notif_read_store.dart
## 3.4 BASE DE DATOS
❌ [DB-01] Reset_usuarios_seed.sql elimina TODOS los datos sin advertencia
[Severidad: ALTA]
El script elimina datos existentes sin preguntar ni hacer backup. Peligroso en producción.
Ubicación: C:\\database\\*_reset_usuarios_seed.sql
❌ [DB-02] Sin índices explícitos en tablas críticas
[Severidad: MEDIA]
No se definen índices en columnas usadas frecuentemente en WHERE/JOIN (correo_institucional, cedula, evento_presidente.evento_id, etc.)
Ubicación: Archivos SQL en C:\\database
❌ [DB-03] Contracción de nombres inconsistente
[Severidad: BAJA]
Mezcla de estilos: fecha_creacion vs fecha_actualizacion vs createdAt. Algunas tablas tienen ambas columnas, otras solo una.
Ubicación: Archivos SQL en C:\\database
# 4. Código Obsoleto / Deprecated
⚠️ [OBS-01] Dependencias duplicadas de SQL Server
[Severidad: MEDIA] package.json incluye odbc (driver principal), msnodesqlv8 (driver nativo Windows) y mssql (driver alternativo). Solo se usa odbc realmente. Los otros dos son redundantes.
Ubicación: C:\\backend\\package.json
⚠️ [OBS-02] Scripts con rutas relativas a node_modules
[Severidad: BAJA] test_odbc_connection.js require("../backend/node_modules/odbc") en lugar de usar la resolución normal de módulos.
Ubicación: C:\\scripts\\test_odbc_connection.js:1
⚠️ [OBS-03] Parche duplicado (auth_01_correct.patch vs auth_01.patch)
[Severidad: BAJA] Hay dos parches casi idénticos. auth_01_correct.patch es una versión incompleta. Debería eliminarse.
Ubicación: C:\\patch
⚠️ [OBS-04] .agents/ directorio vacío
[Severidad: BAJA] El directorio .agents/ está vacío. Si no se va a usar, debería eliminarse.
Ubicación: C:\\.agents
⚠️ [OBS-05] estadisticas.txt vacío en backend/
[Severidad: BAJA] Archivo estadisticas.txt en la raíz del backend está vacío (0 bytes). Sin uso aparente.
Ubicación: C:\\backend\\estadisticas.txt
⚠️ [OBS-06] README.md vacío
[Severidad: BAJA] El README.md del proyecto raíz está completamente vacío.
Ubicación: C:\\README.md
⚠️ [OBS-07] assets/anim/ y assets/icn/ vacíos
[Severidad: BAJA] Las carpetas assets/anim/ y assets/icn/ en el proyecto mobile están vacías pero referenciadas en pubspec.yaml.
Ubicación: C:\\mobile\\assets\\anim | C:\\mobile\\assets\\icn | pubspec.yaml:60-62
# 5. Código Redundante
⚠ [RED-01] Ruta /api/probar-db duplicada
[Severidad: BAJA] La ruta /probar-db se registra dos veces: como /probar-db y como /api/probar-db en index.js.
Ubicación: C:\\backend\\index.js:75-76
⚠ [RED-02] Validación de cédula y correo duplicada en personal.service.js
[Severidad: MEDIA] La validación de cédula (10 dígitos) y correo (regex) está repetida en las funciones actualizarPerfil, crear y actualizar.
Ubicación: C:\\backend\\src\\services\\personal.service.js:48-55, 106-113, 150-157
⚠ [RED-03] Contraseña por defecto duplicada en auth.routes y personal.service
[Severidad: MEDIA] La función passwordInicial/passwordDesdeFecha está implementada dos veces con la misma lógica.
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:450-459 | C:\\backend\\src\\services\\personal.service.js:218-233
⚠ [RED-04] Función tieneColumnaFoto duplicada
[Severidad: MEDIA] La función para verificar existencia de columna foto_perfil_url está implementada en auth.routes.js y personal.repository.js.
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:461-467 | C:\\backend\\src\\repositories\\personal.repository.js:196-202
⚠ [RED-05] Permisos hardcodeados en auth.routes.js que duplican los de la BD
[Severidad: ALTA] La función permisosPorDefecto() contiene listas de permisos hardcodeadas para cada rol. Si la BD tiene permisos, estos se ignoran y se usan los hardcodeados (solo se consulta BD si hay registros en rol_permiso).
Ubicación: C:\\backend\\src\\routes\\auth.routes.js:245-273
⚠ [RED-06] Controladores con estructura casi idéntica
[Severidad: BAJA] Todos los controladores sigue el mismo patrón try-catch con res.status(500).json(...). Hay mucha repetición de código.
Ubicación: Todos los controllers en C:\\backend\\src\\controllers
# 6. Lo que No Funciona / No Está Implementado
❌ [NF-01] Router declarativo no implementado
[Severidad: ALTA] app_rtr.dart está vacío. La navegación usa Navigator.pushReplacement manual en lugar de GoRouter, Navigator 2.0 o similar.
Ubicación: C:\\mobile\\lib\\core\\rtr\\app_rtr.dart
❌ [NF-02] Módulos del Dashboard deshabilitados
[Severidad: MEDIA] Servicios, Reportes, Operaciones, Estadísticas y Configuración tienen enabled: false. No hay implementación.
Ubicación: C:\\mobile\\lib\\features\\dash\\dash_scr.dart:51-55
❌ [NF-03] Sin gestor de estado global
[Severidad: MEDIA] No hay Provider, Riverpod, BLoC ni similar. El estado es completamente local con setState.
Ubicación: Toda la app mobile
❌ [NF-04] Sin persistencia de sesión (token en memoria volátil)
[Severidad: MEDIA] AuthSession guarda el token en un campo static. Se pierde al recargar/cerrar la app.
Ubicación: C:\\mobile\\lib\\core\\auth\\auth_session.dart
❌ [NF-05] Sin pruebas automatizadas (backend)
[Severidad: ALTA] package.json tiene "test": "echo \"Error: no test specified\" && exit 1". No hay un solo test en el backend.
Ubicación: C:\\backend\\package.json:8
❌ [NF-06] Pruebas mínimas en mobile (1 solo test widget)
[Severidad: ALTA] Solo existe un test widget ('widget_test.dart') que probablemente falla por no tener MaterialApp apropiado.
Ubicación: C:\\mobile\\test\\widget_test.dart
❌ [NF-07] Sin CI/CD pipeline
[Severidad: MEDIA] No hay configuración de GitHub Actions, GitLab CI u otro pipeline de integración continua.
Ubicación: Raíz del proyecto
❌ [NF-08] Sin Docker ni contenedorización
[Severidad: BAJA] No hay Dockerfile ni docker-compose.yml. El despliegue depende del entorno local.
Ubicación: Raíz del proyecto
❌ [NF-09] Sin soporte de archivos móvil (stubs retornan null)
[Severidad: MEDIA] file_pick_stub.dart retorna null. La selección de archivos no funciona en plataformas no-web.
Ubicación: C:\\mobile\\lib\\core\\file\\file_pick_stub.dart
❌ [NF-10] Sin visualización de PDF nativa (solo web)
[Severidad: MEDIA] pdf_preview_stub.dart no tiene implementación nativa. Solo funciona en web.
Ubicación: C:\\mobile\\lib\\core\\pdf\\pdf_preview_stub.dart
❌ [NF-11] Botón "Olvidó su contraseña" sin funcionalidad
[Severidad: BAJA] El botón "Olvidó su contraseña" en la pantalla de login tiene onPressed: () => {} (vacío).
Ubicación: C:\\mobile\\lib\\features\\auth\\auth_scr.dart:252
# 7. Recomendaciones para Mejorar
## 7.1 SEGURIDAD (Prioridad: Alta)
- → Implementar rate limiting (express-rate-limit) en el endpoint de login
- → Usar refresh tokens con JWT (access + refresh tokens)
- → Mover JWT_SECRET a variable de entorno segura y rotarla periódicamente
- → Agregar validación de longitud y caracteres en entradas de texto
- → Implementar bloqueo de cuenta tras N intentos fallidos de login
- → Sanitizar nombres de tabla en consultas dinámicas (insertarBasico, cambiarActivo)
- → Nunca exponer el archivo .env con credenciales reales en el repositorio (agregar a .gitignore)
- → Validar permisos en el endpoint de cambio de contraseña
## 7.2 RENDIMIENTO (Prioridad: Alta)
- → Implementar pool de conexiones ODBC en lugar de abrir/cerrar por operación
- → Agregar índices SQL en columnas usadas en WHERE/JOIN (correo_institucional, cedula, evento_personal.evento_id, etc.)
- → Reducir el límite de JSON de 25MB a un valor más razonable (ej. 5-10MB)
- → Evaluar el uso de Redis para caché de consultas frecuentes (catálogos, roles, permisos)
## 7.3 ARQUITECTURA (Prioridad: Media)
- → Migrar a un gestor de estado global en Flutter (Riverpod recomendado por ser moderno y simple)
- → Implementar GoRouter o Navigator 2.0 para navegación declarativa con deep linking
- → Centralizar el manejo de errores HTTP en el ApiClient para redirigir al login en 401
- → Extraer lógica repetida de controladores a un helper/middleware genérico
- → Unificar las funciones de contraseña por defecto en un solo lugar
- → Eliminar dependencias no utilizadas (msnodesqlv8, mssql) del package.json
## 7.4 PERSISTENCIA (Prioridad: Media)
- → Persistir token JWT en flutter_secure_storage (o al menos SharedPreferences)
- → Persistir notificaciones leídas en almacenamiento local (Hive, SQLite, SharedPreferences)
- → Implementar refresh automático de token antes de expirar
## 7.5 CALIDAD Y TESTING (Prioridad: Alta)
- → Escribir tests unitarios para services y repositories del backend (usar Jest o Mocha)
- → Escribir tests unitarios para modelos, servicios y widgets en Flutter
- → Configurar CI/CD con GitHub Actions (lint, typecheck, test, build)
- → Configurar linting más estricto tanto en backend (ESLint) como en mobile (flutter_lints ya incluido)
## 7.6 DOCUMENTACIÓN (Prioridad: Media)
- → Completar README.md con instrucciones de instalación, configuracion y despliegue
- → Documentar la API REST (OpenAPI/Swagger)
- → Agregar diagrama de base de datos y arquitectura
## 7.7 FUNCIONALIDADES FALTANTES (Prioridad: Media)
- → Implementar los módulos deshabilitados del Dashboard (Servicios, Reportes, Operaciones, Estadísticas, Configuración)
- → Implementar funcionalidad de "Olvidó su contraseña" (envío de correo)
- → Implementar visualización de PDF en plataformas nativas (usar flutter_pdfview u open_file)
- → Implementar selección de archivos/imágenes en plataformas nativas (usar file_picker package)
- → Agregar soporte para notificaciones push (Firebase Cloud Messaging)
## 7.8 INFRAESTRUCTURA (Prioridad: Baja)
- → Crear Dockerfile y docker-compose.yml para el backend
- → Configurar entorno de desarrollo con variables de entorno separadas (.env.dev, .env.prod)
- → Agregar .gitignore adecuado que excluya node_modules, .env, build/
- → Crear script de inicialización rápida (setup.sh/setup.ps1)
# 8. Estadísticas del Proyecto
Archivos totales (sin node_modules): ~90 archivos
Backend (JS): 27 archivos fuente, ~3,590 líneas
Mobile (Dart/Flutter): ~40+ archivos fuente, ~5,000+ líneas
Base de Datos (SQL): 10 scripts de migración, ~1,511 líneas
Commits en git: 2 commits
Dependencias backend: 6 directas (bcrypt, cors, dotenv, express, jsonwebtoken, odbc) + 2 redundantes (msnodesqlv8, mssql)
Dependencias mobile: 3 directas (cupertino_icons, http, web)
Roles del sistema: 8-9 roles con ~80-100 permisos
Insignias (gamificación): 15 niveles escalonados
Datos de prueba: 58 usuarios de ejemplo
# 9. Resumen Final
El proyecto BITSAC (SIGO-GCAM) es un sistema de gestión operativa funcional y bien estructurado que utiliza tecnologías modernas (Node.js/Express 5 + Flutter 3.44). La arquitectura en capas del backend es sólida y el frontend mobile tiene una base multi-plataforma sólida con Flutter.
Sin embargo, se identificaron los siguientes puntos críticos:

Puntuación de salud del proyecto: 6.5/10
- Arquitectura: 8/10
- Seguridad: 4/10
- Rendimiento: 5/10
- Testing: 1/10
- Documentación: 3/10
- Mantenibilidad: 7/10

Recomendación: Abordar primero los 5 errores críticos de seguridad (sección 3.1), luego implementar pool de conexiones y gestor de estado, y finalmente configurar CI/CD con tests automatizados.
| Componente | Detalle |
| --- | --- |
| Backend | Node.js (Express 5.2.1) - JavaScript (CommonJS) |
| Base de Datos | SQL Server (ODBC Driver 18) |
| Mobile | Flutter 3.44.4 / Dart 3.12.2 |
| Sistemas Operativos | Android, iOS, Web, Windows, macOS, Linux |
| Arquitectura Backend | 4 Capas: Routes → Controllers → Services → Repositories |
| Arquitectura Mobile | Feature-first + Clean Architecture simplificada |
| Autenticación | JWT + bcrypt + RBAC (Role-Based Access Control) |
| Módulos | Personal, Eventos, Anuncios, Cartillas, Insignias, Administración, Catálogos |
| Líneas de código | Backend: ~3,590 líneas | Mobile: ~5,000+ líneas | SQL: ~1,511 líneas |
| Categoría | Cantidad |
| --- | --- |
| Errores críticos | 5 |
| Errores graves/medios | 15+ |
| Código obsoleto | 7 |
| Redundancias | 6 |