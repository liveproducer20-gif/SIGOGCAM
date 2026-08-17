# Auditoría de la plataforma SIGO-GCAM

**Fecha:** 2026-08-16
**Alcance:** Código fuente (backend Python/FastAPI, frontend PHP, SQL Server, Docker), configuración y prácticas de despliegue.
**Estado:** Auditoría de revisión de código estática; no se ejecutó la aplicación ni se probaron exploits.

---

## 1. Resumen ejecutivo

La plataforma está bien estructurada en varios aspectos (consultas SQL parametrizadas en toda la API, salida HTML escapada en las vistas, secretos fuera del repositorio, permisos por módulo en la mayoría de los endpoints). Sin embargo, se detectaron **2 vulnerabilidades críticas de control de acceso** que permiten a un usuario con permisos de solo lectura elevar sus privilegios o modificar datos operativos, y **un mecanismo de autenticación inseguro** (contraseña = cédula) que debe corregirse antes de cualquier despliegue real.

**Prioridad recomendada:** 1) corregir control de acceso en `configuracion` y `distribucion_geografica` (v2), 2) eliminar el fallback de contraseña-cédula, 3) endurecer autenticación (rate limiting, secret obligatorio), 4) limitar la exposición de datos personales.

---

## 2. Arquitectura auditada

| Capa | Tecnología | Ubicación |
| --- | --- | --- |
| Frontend | PHP 8 (renderizado servidor, sesiones) | `frontend_php/` |
| Backend | Python 3.12 + FastAPI + pyodbc | `backend_python/app/` |
| Base de datos | SQL Server (BITSAC) | `database/`, `docker/database/` |
| Despliegue | Docker Compose | `docker-compose.yml` |

El frontend PHP actúa como **proxy autenticado** hacia la API Python: valida la sesión localmente y reenvía el token JWT. Esto implica que la seguridad real reside en la API; el frontend solo es una capa de presentación.

---

## 3. Hallazgos por severidad

### 3.1 CRÍTICO

#### C1. Escalada de privilegios vía módulo de Configuración

> ✅ **Corregido (2026-08-16):** las mutaciones ahora exigen `configuracion.editar` o `configuracion.roles.gestionar` (ver `require_any_permission` en `app/middleware/auth.py`).

- **Archivos:** `backend_python/app/modules/configuracion/routes.py`
- **Detalle:** El router declara una sola dependencia a nivel de router: `require_permission("configuracion.ver")`. Sin embargo, todos los endpoints de **escritura** usan esa misma protección: `PUT /roles/{id}/permisos`, `PUT /roles/{id}/menu`, `POST /roles/{id}/alcance`, `POST /roles/{id}/condiciones`, `PUT /roles/{id}/campos`, `POST /roles/{id}/versiones`, `POST/DELETE /cambios`.
- **Impacto:** Cualquier usuario autenticado con el permiso de *ver* configuración puede modificar los permisos de cualquier rol (incluido el suyo propio), el menú, el alcance de datos y las condiciones. Es una escalada de privilegios directa a administrador.
- **Corrección:** Exigir permisos de escritura específicos (p. ej. `configuracion.editar`, `configuracion.permisos`) en cada endpoint de mutación, y proteger las mutaciones con `require_permission` a nivel de endpoint (como se hace en `admin/routes.py`).

#### C2. Control de acceso roto en Distribución Geográfica v2

> ✅ **Corregido (2026-08-16):** el módulo v2 se consolidó en la v1 (un solo router `routes.py` y un solo repositorio `repository.py`); las mutaciones exigen permisos finos (`rutas_geograficas.gestionar`/`distribucion.catalogos` para rutas geográficas; `distribucion.catalogos`/`distribucion.crear` para crear lugares; `distribucion.editar` para actualizar; `distribucion.desactivar` para eliminar; `distribucion.asignar` para asignaciones) y las lecturas solo `distribucion.ver`.

- **Archivos:** `backend_python/app/modules/distribucion_geografica/routes_geo.py`
- **Detalle:** El router `distribucion-v2` tiene como única dependencia `require_permission("distribucion.ver")`. Todos los endpoints de escritura (`POST/PUT/DELETE /rutas-geograficas`, `POST/PUT/DELETE /lugares-servicio`, `POST /lugares-servicio/{id}/asignaciones`, `DELETE /asignaciones-punto/{id}`) quedan abiertos a cualquier usuario con permiso de solo lectura.
- **Impacto:** Un usuario con permiso de consulta puede crear, modificar y eliminar rutas, lugares de servicio y asignaciones operativas, corrompiendo el tablero de distribución y la asistencia.
- **Corrección:** Aplicar los mismos permisos finos que la versión 1 del módulo (`distribucion.catalogos`, `distribucion.crear`, `distribucion.editar`, `distribucion.asignar`, `distribucion.desactivar` en `routes.py`). Idealmente consolidar ambas versiones del módulo para evitar divergencias de seguridad.

#### C3. Autenticación con contraseña = cédula
- **Archivos:** `backend_python/app/modules/auth/routes.py` (líneas 20-24); `docker/database/seed-users.sql` (crea usuarios con `password_hash = NULL`)
- **Detalle:** Cuando un registro de personal no tiene `password_hash`, el login acepta como contraseña la **cédula** del usuario:
  ```python
  password_ok = payload.password.strip() == str(user.get("cedula") or "").strip()
  ```
- **Impacto:** La cédula es un dato público en Ecuador (aparece en documentos, planillas y en el propio sistema). Cualquier persona que conozca la cédula de un agente puede ingresar a su cuenta si esa cuenta nunca tuvo contraseña hasheada. Combinado con la ausencia de rate limiting (A2), permite fuerza bruta trivial.
- **Corrección:** Eliminar el fallback. Si `password_hash` es nulo, rechazar el login y obligar a un restablecimiento de contraseña. Ejecutar un script que genere hashes para todos los registros con `password_hash IS NULL`.

### 3.2 ALTO

#### A1. Exposición masiva de datos personales a cualquier usuario autenticado

> ✅ **Corregido (2026-08-16):** lecturas de personal/usuarios ahora protegidas. Matriz aplicada:
>
> | Endpoint | Permiso |
> | --- | --- |
> | `GET /api/personal` (listado) | `personal.ver` |
> | `GET /api/personal/buscar` | `personal.ver` |
> | `GET /api/personal/operativos` y `/disponibles` | `personal.ver` **o** `personal.ver_asignado` **o** `eventos.convocar` **o** `anuncios.crear` |
> | `GET /api/personal/catalogos` | `personal.ver` |
> | `GET /api/personal/{id}` | propio **o** `personal.ver` |
> | `GET /api/usuarios/{id}/perfil` | propio **o** `personal.ver` |
> | `GET /api/usuarios/{id}/insignias` y `/progreso-insignias` | propio **o** `insignias.ver` |
>
> `GET /api/dashboard/resumen` y el módulo de soporte se dejan como están: el resumen son métricas agregadas no sensibles (página de inicio de todos los roles autenticados) y soporte ya filtra por usuario propietario salvo `soporte.listar`/admin.

- **Archivos:** `backend_python/app/modules/personal/routes.py`, `backend_python/app/modules/usuarios/routes.py`
- **Detalle:** `GET /api/personal`, `GET /api/personal/buscar`, `GET /api/personal/operativos`, `GET /api/personal/disponibles`, `GET /api/personal/{id}`, `GET /api/usuarios/{id}/perfil` y `GET /api/usuarios/{id}/insignias` solo exigen `current_user` (estar autenticado). No hay verificación de permiso ni de propiedad del recurso.
- **Impacto:** Cualquier agente con la cuenta más básica puede enumerar cédulas, teléfonos, correos institucionales y perfiles completos de todo el personal. En Ecuador, la cédula combinada con otros datos facilita suplantación de identidad.
- **Corrección:** Exigir `personal.ver` para los listados/consultas, y para `usuarios/{id}` validar que el usuario consulte su propio perfil o tenga un permiso específico (p. ej. `personal.ver`). Considerar enmascarar datos sensibles (cédula parcial) para roles de solo lectura.

#### A2. Sin protección contra fuerza bruta ni rate limiting en el login
- **Archivos:** `backend_python/app/modules/auth/routes.py` (no hay middleware de límites en `app/middleware/`)
- **Detalle:** No existe límite de intentos fallidos, bloqueo temporal por IP/cuenta ni dependencia de rate limiting (slowapi o similar). La API no emite cabeceras de seguridad.
- **Impacto:** Fuerza bruta de contraseñas sin fricción, agravada por C3.
- **Corrección:** Añadir rate limiting (p. ej. `slowapi`) sobre `/auth/login` y un bloqueo temporal tras N intentos fallidos. Habilitar `Access-Control-*` y cabeceras de seguridad en un middleware.

#### A3. Secretos con valores por defecto conocidos
- **Archivos:** `backend_python/app/core/config.py` (`jwt_secret = "cambie_esta_clave_por_una_segura"`), `backend_python/.env.example`
- **Detalle:** Si la app arranca sin `JWT_SECRET` configurado (o con el del ejemplo), cualquier persona puede firmar tokens JWT válidos y autenticarse como administrador.
- **Corrección:** Fallar al arranque si `jwt_secret` es el valor por defecto (sobre todo con `APP_ENV=production`). Validar fortaleza mínima (≥32 bytes aleatorios).

#### A4. Detalles de errores internos expuestos al cliente
- **Archivo:** `backend_python/app/middleware/errors.py`
- **Detalle:** El manejador de errores inesperados devuelve `{"detalle": str(exc)}`, exponiendo mensajes internos de pyodbc, rutas de archivos y detalles de consultas a cualquier cliente (incluso no autenticado).
- **Corrección:** En producción, loguear el detalle completo en el servidor y devolver un mensaje genérico. Solo en desarrollo incluir detalles.

#### A5. Contraseñas guardadas con sha256 y passlib incompatible con bcrypt ≥ 4.1

> ✅ **Corregido (2026-08-16):** `app/core/security.py` ahora usa `bcrypt` directamente (hash/verify); `personal/repository.py` dejó de usar sha256 y `requirements.txt` reemplaza `passlib[bcrypt]==1.7.4` por `bcrypt==5.0.0`.

- **Archivos:** `backend_python/app/modules/personal/repository.py`, `backend_python/app/core/security.py`, `backend_python/requirements.txt`
- **Detalle:** `_hash_password` guardaba `sha256` (sin sal) mientras el login verificaba con bcrypt, por lo que las contraseñas creadas/restablecidas desde el módulo Personal eran inutilizables. Además, `passlib 1.7.4` es incompatible con `bcrypt >= 4.1` (rompe con `bcrypt 5.0.0`, instalado en el venv y en Docker), lo que hacía fallar toda verificación de hash.

#### A6. Documentación de API (Swagger) expuesta en producción
- **Archivo:** `backend_python/app/main.py` (`docs_url=f"{settings.api_prefix}/docs"`)
- **Detalle:** `/api/docs` está habilitado siempre, sin importar `APP_ENV`.
- **Impacto:** Muestra el inventario completo de endpoints (superficie de ataque) a cualquier visitante.
- **Corrección:** Deshabilitar `docs_url`/`openapi_url` cuando `APP_ENV=production` o protegerlo tras autenticación.

#### A7. Permisos embebidos en el JWT con expiración de 12 horas
- **Archivos:** `backend_python/app/core/security.py` (`jwt_expire_minutes: int = 720`), `backend_python/app/modules/auth/routes.py`
- **Detalle:** Los permisos del usuario se incrustan en el token al iniciar sesión y no se recargan hasta que expira (12 h). Además, `require_permission` en `app/middleware/auth.py` concede acceso total si el código del rol contiene "ADMINISTRADOR", ignorando los permisos granulares.
- **Impacto:** (a) Si un administrador revoca permisos, el usuario conserva acceso hasta 12 h; (b) el bypass por nombre de rol hace que los permisos granulares sean decorativos para roles "ADMINISTRADOR" y rompe si se renombra un rol.
- **Corrección:** Recargar permisos desde la BD por petición (o acortar expiración + renovar token), y eliminar el bypass textual de rol a favor de permisos explícitos.

### 3.3 MEDIO

#### M1. Sin tokens CSRF en el frontend PHP
- **Archivos:** `frontend_php/public/index.php` (todas las rutas POST), `frontend_php/app/Core/AuthSession.php`
- **Detalle:** Ningún formulario/endpoint POST valida un token CSRF. La mitigación actual depende del comportamiento `SameSite=Lax` del navegador (por defecto en PHP 7.3+), que no cubre todos los escenarios (subdominios, métodos, navegadores antiguos).
- **Corrección:** Emitir un token CSRF por sesión, validarlo en todos los POST y fijar la cookie de sesión con `SameSite=Strict` cuando sea viable.

#### M2. Cookies de sesión sin parámetros explícitos
- **Archivo:** `frontend_php/app/Core/AuthSession.php`
- **Detalle:** `session_start()` sin `session_set_cookie_params()`: no se fuerza `HttpOnly`, `Secure` ni `SameSite` explícitamente; depende de la configuración del servidor PHP.
- **Corrección:** Configurar explícitamente `httponly=true`, `secure=true` (bajo HTTPS), `samesite=Lax/Strict` y un nombre de sesión no predecible.

#### M3. Conexión a SQL Server con cifrado y verificación de certificado débiles
- **Archivos:** `backend_python/app/core/config.py` (`db_encrypt="optional"`, `db_trust_server_certificate="yes"`), `docker-compose.yml` (usa `Encrypt=yes` pero sigue confiando el certificado)
- **Detalle:** En desarrollo el tráfico hacia la BD puede ir sin cifrar y con certificado no verificado; en Docker el `sa` se usa por red interna con trust de certificado.
- **Corrección:** En producción usar `Encrypt=yes` con certificados reales y un usuario de aplicación con permisos mínimos (no `sa`).

#### M4. Endpoints de diagnóstico sin autenticación
- **Archivos:** `backend_python/app/modules/health/routes.py`
- **Detalle:** `GET /api` y `GET /api/probar-db` no requieren autenticación y revelan el nombre de la base, la versión y el inventario de rutas.
- **Corrección:** Requerir autenticación (o restringirlos a red interna en producción).

#### M5. Restablecimiento de contraseña: devuelve la clave en claro y con entropía baja
- **Archivo:** `backend_python/app/modules/personal/routes.py`
- **Detalle:** `POST /personal/{id}/reset-password` genera `secrets.token_urlsafe(8)` (~64 bits) y lo devuelve en la respuesta HTTP.
- **Impacto:** La contraseña viaja en claro (falta HTTPS) y queda en logs/proxies; 64 bits es débil frente a políticas institucionales.
- **Corrección:** Exigir HTTPS, generar claves más largas o enviarlas por canal seguro, e idealmente marcar la clave como "cambio obligatorio en el próximo inicio de sesión".

#### M6. Imágenes y PDF de eventos/anuncios guardados como data URI en la BD
- **Archivos:** `backend_python/app/modules/eventos/repository.py`, `backend_python/app/modules/anuncios/`
- **Detalle:** `imagen_url`/`pdf_url` almacenan el contenido completo como `data:...` en `NVARCHAR(MAX)`.
- **Impacto:** Crecimiento desmedido de la base, consultas lentas, y riesgo de XSS almacenado si algún render futuro no escapa el contenido.
- **Corrección:** Guardar archivos en disco/object storage y solo la ruta en la BD; validar tipo y tamaño en el backend.

#### M7. Duplicación del módulo de distribución con autorizaciones divergentes

> ✅ **Resuelto (2026-08-16):** el módulo v2 (`routes_geo.py`/`repository_geo.py`) se eliminó y su funcionalidad única (rutas geográficas, lugares de servicio y asignaciones de punto) se integró en la v1 con permisos finos. Los endpoints duplicados (`/distritos`, `/distritos/{id}/rutas`, `/rutas/{id}/lugares-servicio`) los sirve ahora la implementación v1.

### 3.4 BAJO / OPERATIVO

#### B1. Scripts de mantenimiento y semilla mezclados con el producto
- **Archivos:** `seed_agente1_100.py`, `seed_fix.py`, `seed_personal.py`, `seed_remaining.py`, `cleanup_personal.py`, `check_ids.py`, `verify_personal.py`, `check_col.py` (raíz y `backend_python/`)
- **Detalle:** Scripts puntuales de carga/limpieza en la raíz del producto; `seed-users.sql` crea usuarios con `password_hash = NULL` (origen de C3).
- **Corrección:** Mover a `scripts/` o `tools/`, documentar su uso, y corregir la semilla para crear hashes reales.

#### B2. Migraciones SQL manuales sin sistema de versionado
- **Archivo:** `database/` (19 scripts con prefijo de fecha)
- **Detalle:** Los cambios de esquema se aplican a mano; no hay un mecanismo que garantice el mismo esquema en todos los entornos.
- **Corrección:** Adoptar un sistema de migraciones (p. ej. Alembic o scripts idempotentes ordenados) y registrar el estado aplicado.

#### B3. Documentos institucionales y PDFs firmados en el repositorio
- **Archivos:** `*.docx`, `*.pdf` (incluidos `-signed.pdf`)
- **Detalle:** Documentos sensibles del convenio en Git. `Backup/` está bien excluido (`.gitignore`), pero los PDF firmados no.
- **Corrección:** Trasladar a un repositorio/documentación privada fuera del código.

#### B4. Sin pruebas automatizadas
- **Detalle:** No hay suite de tests (pytest/PHPUnit) en el repositorio; la validación es manual (scripts `verify_*.py`, sintaxis).
- **Corrección:** Añadir al menos tests de autenticación y control de acceso (los hallazgos C1-C2 se habrían detectado con un test por endpoint).

#### B5. CORS con lista fija
- **Archivo:** `backend_python/app/core/config.py` (`cors_origins` = solo localhost)
- **Detalle:** Correcto por defecto, pero en producción el origen real del frontend debe agregarse explícitamente o el navegador bloqueará llamadas.
- **Corrección:** Configurar `cors_origins` vía entorno con la lista exacta de dominios autorizados.

---

## 4. Aspectos positivos (mantener)

- **SQL parametrizado en toda la API** (pyodbc `?` placeholders); los pocos `f-strings` interpolan solo identificadores fijos (listas de columnas, cláusulas armadas con condiciones controladas). No se encontró inyección SQL directa.
- **Salida HTML escapada** en vistas (`htmlspecialchars`, helpers `esc()`/`$e()` en JS).
- **Secretos fuera del repositorio**: `.env` en `.gitignore`; solo hay `.env.example` en Git. `Backup/` excluido.
- **Contraseñas con bcrypt** (passlib) cuando existe hash.
- **Desactivación lógica (soft delete)** en administración y asistencia.
- **Auditoría de cambios de configuración** (`auditoria_roles_permisos`) y control de IP/dispositivo en algunas operaciones.
- **Docker Compose** con contraseñas obligatorias (`MSSQL_SA_PASSWORD`, `JWT_SECRET` con `:?`), healthchecks y red interna.
- **Validación de entrada** en la API con Pydantic y paginación con límites (le=100, le=200).

---

## 5. Plan de remediación priorizado

| # | Acción | Severidad | Esfuerzo |
| --- | --- | --- | --- |
| 1 | Proteger mutaciones de `configuracion` con permisos de escritura | Crítico | Bajo |
| 2 | Aplicar permisos finos en `routes_geo.py` (v2) y consolidar con v1 | Crítico | Bajo |
| 3 | Eliminar login con cédula; hashear/segregar cuentas sin hash | Crítico | Bajo |
| 4 | Rate limiting + bloqueo de intentos en `/auth/login` | Alto | Bajo |
| 5 | Fallar al arrancar con `JWT_SECRET` por defecto; secret obligatorio en prod | Alto | Bajo |
| 6 | Restringir `personal` y `usuarios/{id}` a permisos/propiedad | Alto | Medio |
| 7 | No exponer `str(exc)` en producción; deshabilitar `/api/docs` en prod | Alto | Bajo |
| 8 | CSRF + cookies de sesión explícitas (HttpOnly/Secure/SameSite) | Medio | Medio |
| 9 | Recargar permisos por petición; eliminar bypass textual de rol | Medio | Medio |
| 10 | Añadir suite de tests de autenticación/autorización | Medio | Medio |
| 11 | Migrar adjuntos a disco/object storage; cifrado de BD con certificados | Medio | Alto |
| 12 | Limpiar raíz (scripts), semilla con hashes, migraciones versionadas | Bajo | Medio |

---

## 6. Pendiente de verificación (no evaluado)

- Ejecución dinámica de la aplicación y pruebas de penetración reales (las vulnerabilidades C1-C3 son verificables manualmente con tokens forjados o cuentas de prueba).
- Estado de las dependencias (no se realizó análisis de vulnerabilidades de paquetes: `pip-audit`/`composer audit`).
- Configuración real de los servidores de despliegue (HTTPS, firewalls, respaldos).
