# Módulos SIGO-GCAM

Este documento describe la estructura vigente de la plataforma después de la reestructuración tecnológica a frontend PHP y backend Python. El cambio se realizó para facilitar el mantenimiento por parte del equipo, que domina mejor estos lenguajes.

## Arquitectura

- Frontend: PHP con vistas renderizadas en servidor.
- Backend: Python con FastAPI.
- Base de datos: SQL Server `BITSAC`.
- Autenticación: JWT emitido por la API y conservado en sesión PHP.

## Módulos Migrados

| Módulo | Ruta web | API principal | Estado |
| --- | --- | --- | --- |
| Autenticación | `/` | `/api/auth/login` | Funcional |
| Dashboard | `/dashboard` | `/api/configuracion/mi-estructura` | Funcional |
| Cartillas | `/cartillas` | `/api/cartillas` | Funcional con generador institucional base |
| Eventos | `/eventos` | `/api/eventos` | Funcional con listado, creación, eliminación, imagen y PDF |
| Anuncios | `/anuncios` | `/api/anuncios` | Funcional con listado, creación, eliminación e imagen |
| Personal | `/personal` | `/api/personal` | Funcional para consulta |
| Administración | `/admin` | `/api/admin/*` | Funcional con consulta, creación, edición y desactivación |
| Insignias | `/insignias` | `/api/insignias` | Funcional para progreso y ranking |
| Soporte | `/soporte` | `/api/soporte` | Funcional para alertas y estadísticas |
| Perfil | `/perfil` | `/api/personal/perfil/me` | Funcional para consulta |
| Configuración | `/configuracion` | `/api/configuracion/*` | Funcional para consulta de roles, permisos y versión |

## Endpoints Principales

### Autenticación

`POST /api/auth/login`

```json
{
  "correo": "usuario@institucion.gob.ec",
  "password": "clave"
}
```

### Cartillas

`GET /api/cartillas/eas`

`GET /api/cartillas/catalogos-operativos`

`POST /api/cartillas`

```json
{
  "causa": "Punto Martillo",
  "contenido": "Texto institucional de la cartilla",
  "tipo": "EAS",
  "subtipo": "NOVEDAD",
  "datos": {}
}
```

### Eventos

`GET /api/eventos`

`POST /api/eventos`

`DELETE /api/eventos/{id}`

### Anuncios

`GET /api/anuncios`

`POST /api/anuncios`

`DELETE /api/anuncios/{id}`

### Insignias

`GET /api/insignias`

`GET /api/insignias/progreso/me`

`GET /api/insignias/ranking`

### Soporte

`GET /api/soporte/stats`

`GET /api/soporte/tickets`

`POST /api/soporte/tickets`

## Cartillas

El módulo mantiene el formato institucional:

```text
*CUERPO DE AGENTES DE CONTROL MUNICIPAL*

*DISTRITO:*
*CIRCUITO:*
*HORARIO:*
*HORA:*
*FECHA:*
*DIRECCIÓN:*

*CAUSA:*

*PROCEDIMIENTO:*

Notifico novedades para fines correspondientes.

*REPORTA:*

*CP:*
*JP:*
*POLICÍA:* si aplica

"Lealtad, Valor y Orden"

Adjunto fotografía
```

La frase de punto martillo se agrega automáticamente en las cartillas generadas desde el formulario cuando la causa no corresponde a ausentismo y existe dirección registrada.

## Validación Actual

La plataforma fue validada con:

- Compilación de módulos Python.
- Validación sintáctica de archivos PHP.
- Conexión ODBC a SQL Server.
- Consulta real de eventos, anuncios, EAS, móviles, rutas, lugares, grados, insignias, soporte y configuración.

## Funciones Finas Implementadas

- CRUD administrativo para EAS, móviles, rutas, lugares de servicio y grados.
- Desactivación lógica de registros administrativos.
- Adjuntos en eventos mediante imagen y PDF guardados como data URI.
- Adjuntos en anuncios mediante imagen guardada como data URI.
- Previsualización embebida de PDF e imagen directamente en tablas de eventos/anuncios.
- Formularios administrativos con catálogos reales para tipos y estados de móvil.
- Edición administrativa precargada desde botón Editar, sin ingresar ID manualmente.
- Generador de cartillas con narrativas específicas para punto martillo, desalojo, retiro temporal, requerimiento, rondas, colaboración, accidente y ausentismo.
- Narrativas adicionales para robo, extorsión, amenazas, desaparición, agresión y visualización de cámaras.
- Gestión básica de permisos por rol desde Configuración.
- Constructor visual de menú por rol con orden arrastrable.
- Gestión de alcance de datos por rol y módulo.
- Gestión de condiciones por rol.

## Matriz de permisos de lecturas sensibles

Permisos finos que protegen los endpoints de consulta de datos personales (definidos en la auditoría 2026-08-16):

| Endpoint | Permiso requerido |
| --- | --- |
| `GET /api/personal` (listado paginado) | `personal.ver` |
| `GET /api/personal/buscar` | `personal.ver` |
| `GET /api/personal/operativos` | `personal.ver` o `personal.ver_asignado` o `eventos.convocar` o `anuncios.crear` |
| `GET /api/personal/disponibles` | igual que `operativos` |
| `GET /api/personal/catalogos` | `personal.ver` |
| `GET /api/personal/{id}` | propio o `personal.ver` |
| `GET /api/personal/perfil/me` | autenticado (perfil propio) |
| `GET /api/usuarios/{id}/perfil` | propio o `personal.ver` |
| `GET /api/usuarios/{id}/insignias` | propio o `insignias.ver` |
| `GET /api/usuarios/{id}/progreso-insignias` | propio o `insignias.ver` |
| `GET /api/dashboard/resumen` | autenticado (métricas agregadas, no sensibles) |
| Soporte (`/api/soporte/*`) | autenticado; datos limitados al usuario propietario salvo `soporte.listar` o administrador |

Los permisos de escritura del módulo de distribución y configuración se documentan en `docs/AUDITORIA.md` (secciones C1, C2 y M7).

## Pendientes de Equivalencia Completa

Aunque todos los módulos principales ya están migrados y funcionales, quedan mejoras de paridad avanzada:

- Auditoría detallada de cada cambio de configuración.
- Historial visual de versiones con comparación entre versiones.

## Menú dinámico (mi-menu / build_tree)

El menú dinámico que consume el dashboard se deriva de los **permisos del rol** (migración `database/20260817_estructura_menu.sql`):

- **`dbo.modulos_sistema`**: catálogo de módulos con ruta real, icono (glifos del sidebar, `NCHAR(0xNNNN)`) y `estado` (los módulos sin página están desactivados).
- **`dbo.rol_menu_configuracion`**: configuración por rol (visible, orden, grupo, `modulo_padre_id`, renombres). Se reconstruye desde permisos: cada rol ve exactamente lo que su permiso habilita, agrupado igual que el sidebar:
  - Grupos: **Administración** (Personal, Catálogos, Lugares, Rutas, Circuitos, Grados, EAS, Móviles, Asignaciones, Mantenimiento), **Distribución** (Geográfica, Tablero, Dashboard), **Eventos y anuncios** (Eventos, Anuncios).
  - Hojas: Dashboard (página de inicio), Panel de Asistencia, Cartillas, Insignias, Soporte, Configuración, Mi perfil.
- El dashboard renderiza el árbol (`hijos` como enlaces del grupo, hojas como tarjetas) y el Constructor visual de menú (Configuración → Menú) permite renombrar/ocultar/reordenar por rol sobre esta base.
