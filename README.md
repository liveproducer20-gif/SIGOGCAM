# SIGO - Sistema Inteligente de Gestión Operativa

**Sistema Inteligente de Gestion Operativa para el Cuerpo de Agentes de Control Municipal de Guayaquil.**

| | |
|---|---|
| **Autor / Desarrollador** | Jorge Luis Calderon Aguirre |
| **Fecha de inicio** | 1 de junio de 2026 |
| **Plataforma** | Flutter (Android, iOS, Web, Windows, Linux, macOS) |
| **Backend** | Node.js + Express 5 + SQL Server 2025 |
| **Orquestacion** | Docker Compose |

---

## Indice

1. [Descripcion del Proyecto](#descripcion-del-proyecto)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Modulos Funcionales](#modulos-funcionales)
4. [Arquitectura Tecnica](#arquitectura-tecnica)
5. [Requisitos](#requisitos)
6. [Instalacion y Arranque](#instalacion-y-arranque)
7. [Configuracion del Entorno](#configuracion-del-entorno)
8. [Base de Datos](#base-de-datos)
9. [API REST](#api-rest)
10. [Desarrollo](#desarrollo)
11. [Docker](#docker)
12. [Scripts Utilitarios](#scripts-utilitarios)
13. [Glosario de Abreviaciones](#glosario-de-abreviaciones)
14. [Licencia](#licencia)

---

## Descripcion del Proyecto

SIGO - Sistema Inteligente de Gestión Operativa es una plataforma integral disenada para la gestion operativa del Cuerpo de Agentes de Control Municipal (GCAM) del canton de Guayaquil. El sistema abarca desde la gestion de personal y cartillas de novedades hasta un sistema de gamificacion con insignias, todo respaldado por una arquitectura robusta y escalable.

**Objetivos principales:**

- Centralizar la operacion diaria del GCAM en una unica plataforma
- Automatizar la generacion de cartillas de novedades (formacion entrante/saliente, rondas, requermientos, etc.)
- Implementar control de acceso basado en roles (RBAC) con permisos granulares
- Gamificar la productividad del personal con un sistema de insignias y niveles
- Ofrecer soporte en tiempo real mediante Server-Sent Events (SSE)
- Funcionar multiplataforma: Android, iOS, Web, escritorio

---

## Estructura del Proyecto

```
BITSAC/
├── backend/                    # API REST (Node.js + Express 5 + SQL Server)
│   ├── src/
│   │   ├── config/             # Configuracion de base de datos (ODBC)
│   │   ├── middleware/         # Auth JWT, auditoria, errores, permisos
│   │   ├── routes/             # 12 archivos de rutas API
│   │   ├── controllers/        # 11 controladores
│   │   ├── services/           # 13 servicios de negocio
│   │   ├── repositories/       # 12 repositorios (queries SQL)
│   │   ├── validators/         # Validacion de entrada
│   │   └── utils/              # Utilidades (respuestas estandarizadas)
│   ├── test/                   # Pruebas unitarias
│   ├── uploads/                # Archivos subidos (gitignored)
│   ├── Dockerfile
│   └── package.json
├── mobile/                     # App multiplataforma (Flutter/Dart)
│   ├── lib/
│   │   ├── core/               # API client, autenticacion, temas, widgets base
│   │   ├── features/
│   │   │   ├── spl/            # Splash screen
│   │   │   ├── auth/           # Login y autenticacion
│   │   │   ├── dash/           # Dashboard principal
│   │   │   ├── crt/            # Cartillas de novedades
│   │   │   ├── evt/            # Eventos y convocatorias
│   │   │   ├── ins/            # Insignias (gamificacion)
│   │   │   ├── adm/            # Administracion (RBAC, catalogos, EAS, moviles)
│   │   │   ├── config/         # Editor de configuracion dinamica
│   │   │   ├── profile/        # Perfil de usuario
│   │   │   └── sup/            # Soporte y alertas en tiempo real
│   │   └── shared/             # Utilidades compartidas
│   ├── assets/                 # Imagenes, iconos SVG de insignias
│   ├── test/                   # Pruebas (33 tests)
│   ├── Dockerfile
│   └── pubspec.yaml
├── database/                   # Migraciones SQL (31 scripts, formato YYYYMMDD)
├── docker/                     # Configuracion Docker (init scripts, MSSQL)
├── scripts/                    # Scripts utilitarios
├── docs/                       # Documentacion adicional
├── Backup/                     # Backup de SQL Server (BITSAC2)
├── docker-compose.yml          # Produccion
├── docker-compose.dev.yml      # Desarrollo (hot reload)
├── .env.example                # Plantilla de variables de entorno
├── PLATAFORMA.pdf              # Documentacion de la plataforma
├── PROPUESTA INSTITUCIONAL.pdf # Propuesta institucional
└── README.md
```

---

## Modulos Funcionales

| Modulo | Abreviacion | Descripcion |
|--------|-------------|-------------|
| Splash | `spl` | Pantalla de carga inicial |
| Autenticacion | `auth` | Login, JWT, sesiones |
| Dashboard | `dash` | Panel principal con navegacion |
| Cartillas | `crt` | Generacion de cartillas de novedades (12 tipos) |
| Eventos | `evt` | Gestion de eventos y convocatorias |
| Anuncios | `ann` | Anuncios institucionales con multimedia |
| Insignias | `ins` | Gamificacion con 48 insignias en 10 niveles |
| Administracion | `adm` | Roles, permisos, catalogos, personal, EAS, moviles, rutas, lugares, grados |
| Configuracion | `config` | Editor dinamico de menus, roles y permisos |
| Perfil | `profile` | Gestion del perfil de usuario |
| Soporte | `sup` | Tickets de soporte con SSE (tiempo real) |

### Tipos de Cartillas

| Cartilla | Descripcion |
|----------|-------------|
| Formacion Entrante | Reporte de inicio de jornada |
| Formacion Saliente | Reporte de cierre de jornada |
| Punto Martillo | Operacion de control en puntos estrategicos |
| Rondas Disuasivas | Patrullaje preventivo |
| Requerimiento | Atencion de requerimientos |
| Retiro Temporal | Retiro temporal de unidades |
| Desalojo | Operaciones de desalojo |
| Colaboracion Entidades | Coordinacion con otras entidades |
| Colaboracion Ciudadana | Atencion a la ciudadania |
| Ausentismo | Registro de ausentismo |
| Otras | Cartillas miscelaneas |

### Niveles de Gamificacion

| Nivel | Insignia | Rango de Cartillas |
|-------|----------|-------------------|
| 1 - Amateur | Amateur | 1 - 5 |
| 2 - Operativo | Operativo | 6 - 15 |
| 3 - Profesional | Profesional | 16 - 30 |
| 4 - Avanzado | Avanzado | 31 - 50 |
| 5 - Experto | Experto | 51 - 80 |
| 6 - Elite | Elite | 81 - 120 |
| 7 - Leyenda | Leyenda | 121 - 170 |
| 8 - Supremo | Supremo | 171 - 230 |
| 9 - Mitico | Mitico | 231 - 300 |
| 10 - Maximo | Maximo | 301+ |

---

## Arquitectura Tecnica

```
┌─────────────────────────────────────────────────────────┐
│                    FLUTTER WEB (Nginx)                   │
│                   Puerto: 8080                           │
│  ┌─────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐  │
│  │ Cartillas│  │ Eventos  │  │Insignias │  │  Admin  │  │
│  └─────────┘  └──────────┘  └──────────┘  └─────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │ /api (proxy inverso)
┌───────────────────────┴─────────────────────────────────┐
│                NODE.JS + EXPRESS 5                       │
│                Puerto: 3000                              │
│  ┌────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │
│  │  Auth  │ │ RBAC     │ │ Auditoria│ │  SSE (Live)  │  │
│  │  JWT   │ │ Permisos │ │  Logs    │ │  Soporte     │  │
│  └────────┘ └──────────┘ └──────────┘ └──────────────┘  │
└───────────────────────┬─────────────────────────────────┘
                        │ ODBC / FreeTDS
┌───────────────────────┴─────────────────────────────────┐
│              SQL SERVER 2025                             │
│              Puerto: 1433                                │
│              Base de datos: BITSAC                       │
└─────────────────────────────────────────────────────────┘
```

### Stack Tecnologico

| Capa | Tecnologia | Version |
|------|-----------|---------|
| Frontend | Flutter / Dart | 3.44+ / ^3.12.2 |
| Backend | Node.js / Express | 24 LTS / 5.2.1 |
| Base de Datos | SQL Server | 2025 |
| Autenticacion | JWT (jsonwebtoken) | 9.0.3 |
| hashing | bcrypt | 6.0.0 |
| HTTP Server | Express 5 | 5.2.1 |
| Realtime | Server-Sent Events | Nativo |
| Contenedorizacion | Docker / Compose | - |
| Web Server | Nginx | 1.29.8 |
| ODBC | ODBC Driver 18 / FreeTDS | - |

---

## Requisitos

### Para Desarrollo Local

- **Node.js** >= 18 (recomendado: 24 LTS)
- **SQL Server** 2019+ (local o remoto)
- **ODBC Driver 18** for SQL Server
- **Flutter SDK** >= 3.44
- **Dart SDK** >= 3.12.2
- **Git**

### Para Docker

- **Docker Desktop** (Windows/macOS) o **Docker Engine** (Linux)
- **Docker Compose** v2+
- **WSL2** (requerido en Windows)

---

## Instalacion y Arranque

### Opcion 1: Docker (Recomendado)

```bash
# 1. Clonar el repositorio
git clone <url-del-repositorio> BITSAC
cd BITSAC

# 2. Configurar variables de entorno
cp .env.example .env
# Editar .env con MSSQL_SA_PASSWORD y JWT_SECRET seguros

# 3. Levantar todos los servicios
docker compose up -d

# 4. Verificar estado
docker compose ps

# 5. Acceder
# Frontend:  http://localhost:8080
# Backend:   http://localhost:3000/api
# SQL Server: localhost:1433
```

### Opcion 2: Desarrollo Local

```bash
# --- Backend ---
cd backend
cp .env.example .env
# Configurar .env con los datos de conexion a SQL Server
npm install
npm start                  # http://localhost:3000

# --- Frontend ( Flutter) ---
cd mobile
flutter pub get
flutter run                 # Ejecuta en navegador o emulador

# --- Base de Datos ---
# Ejecutar los scripts en database/ en orden cronologico
```

### Opcion 3: Docker con Hot Reload (Desarrollo)

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

Esto monta el codigo fuente del backend con `node --watch` para recarga automatica.

---

## Configuracion del Entorno

### Variables de Entorno Principales (.env)

| Variable | Descripcion | Ejemplo |
|----------|-------------|---------|
| `MSSQL_SA_PASSWORD` | Password del SA de SQL Server | `MiClaveSegura123!` |
| `JWT_SECRET` | Secreto para firmar tokens JWT (min 32 bytes) | `openssl rand -hex 32` |
| `DB_DATABASE` | Nombre de la base de datos | `BITSAC` |
| `FRONTEND_PORT` | Puerto del frontend | `8080` |
| `BACKEND_PORT` | Puerto del backend | `3000` |
| `DB_PORT` | Puerto de SQL Server | `1433` |
| `JSON_LIMIT` | Limite de payload JSON | `25mb` |

### Variables del Backend (backend/.env)

| Variable | Descripcion | Default |
|----------|-------------|---------|
| `PORT` | Puerto del servidor | `3000` |
| `DB_DRIVER` | Driver ODBC | `ODBC Driver 18 for SQL Server` |
| `DB_SERVER` | Servidor SQL Server | `localhost\SQLEXPRESS` |
| `DB_DATABASE` | Base de datos | `BITSAC` |
| `DB_ENCRYPT` | Cifrado de conexion | `no` |
| `DB_TRUSTED_CONNECTION` | Conexion de confianza | `Yes` |
| `DB_TRUST_SERVER_CERTIFICATE` | Confiar en certificado | `Yes` |
| `DB_CONNECTION_TIMEOUT` | Timeout de conexion (seg) | `15` |
| `JWT_SECRET` | Secreto JWT | *(requerido)* |

---

## Base de Datos

### Esquema

La base de datos `BITSAC` contiene tablas para:

- **RBAC:** `roles`, `permisos`, `role_permisos`, `usuarios_roles`
- **Personal:** `personal`, `grados`, `cargos`
- **Catalogos:** `distritos`, `tipos_servicio_lugar`, `tipos_movil`, `estados_*`
- **Operaciones:** `rutas`, `lugares_servicio`, `eas`, `moviles`, `asignaciones_eas_moviles`
- **Cartillas:** Tablas de cartillas y flujo de aprobacion
- **Eventos:** `eventos`, `evento_convocados`, `evento_imagenes`
- **Anuncios:** `anuncios`, `anuncio_imagenes`
- **Insignias:** `insignias`, `insignias_usuario`
- **Soporte:** Tablas de tickets y alertas
- **Auditoria:** Logs de auditoria

### Migraciones

Los scripts de migracion se encuentran en `database/` con formato `YYYYMMDD_descripcion.sql`:

```bash
# Ejecutar en orden cronologico:
# 20260705_rbac_audit_seed.sql
# 20260706_announcements_eas.sql
# 20260707_admin_cartilla_utf8.sql
# ... (31 scripts en total)
# 20260714_config_roles_builder.sql
```

### Backup

El archivo `Backup/BITSAC2` contiene un backup completo de SQL Server (~59MB) con datos de prueba.

---

## API REST

### Endpoints Principales

| Prefijo | Modulo | Descripcion |
|---------|--------|-------------|
| `POST /api/auth/login` | Auth | Inicio de sesion |
| `POST /api/auth/refresh` | Auth | Renovacion de token |
| `GET /api/catalogos/*` | Catalogos | Catalogos del sistema |
| `GET/POST /api/admin/*` | Admin | CRUD roles, permisos, EAS, moviles, rutas, lugares, grados |
| `GET/POST /api/personal/*` | Personal | Gestion de personal |
| `GET/POST /api/eventos/*` | Eventos | Gestion de eventos |
| `GET/POST /api/anuncios/*` | Anuncios | Gestion de anuncios |
| `GET/POST /api/cartillas/*` | Cartillas | Generacion y gestion de cartillas |
| `GET/POST /api/insignias/*` | Insignias | Sistema de gamificacion |
| `GET/POST /api/soporte/*` | Soporte | Tickets con SSE |
| `GET /api/configuracion/*` | Config | Menus y roles dinamicos |

### Autenticacion

```bash
# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"usuario": "admin", "contrasena": "password"}'

# Respuesta:
# { "token": "eyJhbGciOiJIUzI1NiIs...", "usuario": { ... } }

# Usar token en requests
curl http://localhost:3000/api/personal \
  -H "Authorization: Bearer <token>"
```

### RBAC (Control de Acceso)

Los permisos siguen el formato `modulo.accion`:

| Permiso | Descripcion |
|---------|-------------|
| `personal.ver` | Ver personal |
| `personal.crear` | Crear personal |
| `cartillas.generar` | Generar cartillas |
| `cartillas.ver` | Ver cartillas |
| `admin.ver` | Ver administracion |
| `moviles.asignar` | Asignar moviles |
| `rutas.ver` | Ver rutas |
| `eas.ver` | Ver EAS |

---

## Desarrollo

### Estructura de una Cartilla

Cada tipo de cartilla sigue un patron comun:

```
mobile/lib/features/crt/wdg/
├── formacion_entrante_redesign.dart   # Formulario completo con preview
├── formacion_saliente_redesign.dart   # Formulario completo con preview
├── punto_martillo_form.dart
├── ronda_disuasiva_form.dart
├── requerimiento_form.dart
├── retiro_temporal_form.dart
├── desalojo_form.dart
├── ausentismo_form.dart
├── colaboracion_entidades_form.dart
├── colaboracion_ciudadana_form.dart
└── otras_cartillas_form.dart
```

### Patron de Formularios

Todos los formularios comparten:

1. **Debounce** de 250ms para actualizacion del preview
2. **Dropdown de EAS** cargado desde API (`GET admin/eas`)
3. **Checkboxes de moviles** cargados desde API (`GET cartillas/asignaciones-eas-moviles`)
4. **Turno automatico** para EAS/RADIOPERADOR (06:00, 14:00, 22:00)
5. **Preview en tiempo real** con formato de WhatsApp

### Ejecutar Pruebas

```bash
cd mobile
flutter test test/crt_text_generator_test.dart test/crt_special_text_generator_test.dart

# 33 tests, 0 errores
```

### Analisis de Codigo

```bash
cd mobile
dart analyze lib/features/crt/
dart analyze lib/features/adm/
dart analyze lib/features/dash/
```

---

## Docker

### Servicios

| Servicio | Imagen | Puerto | Descripcion |
|----------|--------|--------|-------------|
| `database` | SQL Server 2025 | 1433 | Base de datos relacional |
| `database-init` | SQL Server 2025 | - | Restauracion inicial del backup |
| `backend` | Node.js 24 LTS | 3000 | API REST |
| `frontend` | Flutter Web + Nginx | 8080 | Aplicacion web |

### Comandos Utiles

```bash
# Levantar todo
docker compose up -d

# Ver logs
docker compose logs -f backend
docker compose logs -f frontend

# Detener
docker compose down

# Reconstruir
docker compose up --build

# Acceder al container de SQL
docker exec -it SIGO - Sistema Inteligente de Gestión Operativa-database /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U SA -P '<password>' -C

# Verificar salud
docker compose ps
```

### Produccion (Linux)

Para despliegue en produccion, consultar [README_DOCKER.md](README_DOCKER.md) que incluye:

- Instalacion de Docker en Linux
- Configuracion de firewall
- SSL/TLS
- Respaldos automaticos
- Monitoreo
- Optimizaciones de rendimiento

---

## Scripts Utilitarios

| Script | Descripcion |
|--------|-------------|
| `scripts/db_schema_audit.js` | Audita el esquema SQL contra el codigo de la app |
| `scripts/generate_badge_svgs.js` | Genera iconos SVG de insignias |

---

## Glosario de Abreviaciones

| Abreviacion | Significado |
|-------------|-------------|
| BITSAC | Base de Informacion Tecnologica de Seguridad y Accion Centralizada |
| SIGO - Sistema Inteligente de Gestión Operativa | Sistema Inteligente de Gestion Operativa |
| GCAM | Cuerpo de Agentes de Control Municipal |
| EAS | Estacion de Accion Segura |
| RBAC | Role-Based Access Control (Control de Acceso Basado en Roles) |
| JWT | JSON Web Token |
| SSE | Server-Sent Events |
| RT | Retiro Temporal |
| ACM | Agente de Control Municipal |
| CRUD | Create, Read, Update, Delete |

---

## Documentacion Adicional

| Archivo | Contenido |
|---------|-----------|
| [README_DOCKER.md](README_DOCKER.md) | Guia completa de operacion con Docker |
| [PLATAFORMA.pdf](PLATAFORMA.pdf) | Documentacion de la plataforma |
| [PROPUESTA INSTITUCIONAL.pdf](PROPUESTA%20INSTITUCIONAL.pdf) | Propuesta institucional |
| `mobile/BITSAC_GLOSARIO.md` | Glosario tecnico de abreviaciones |
| `docs/docker_analysis.md` | Analisis de arquitectura Docker |
| `docs/fase2_reutilizar_migrar.md` | Planificacion Fase 2 |

---

## Autor

**Jorge Luis Calderon Aguirre**
Desarrollador de Software

Inicio del proyecto: **1 de junio de 2026**

---

## Licencia

Proyecto privado. Todos los derechos reservados. Jorge Luis Calderón Aguirre - Guayaquil, Ecuador.
