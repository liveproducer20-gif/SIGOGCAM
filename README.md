# SIGO-GCAM

Sistema Inteligente de Gestión Operativa para el Cuerpo de Agentes de Control Municipal.

## Arquitectura objetivo

El proyecto se encuentra en proceso de reestructuracion completa para trabajar con:

- Frontend: PHP.
- Backend: Python.
- Base de datos: SQL Server.

La decision tecnologica se tomo porque el equipo de desarrollo y mantenimiento tiene mayor dominio operativo de Python y PHP. La finalidad es mejorar la mantenibilidad, facilitar soporte interno y permitir que los nuevos modulos se desarrollen con herramientas conocidas por el equipo.

## Carpetas principales

```text
backend_python/   API principal en Python
frontend_php/     Interfaz web en PHP
database/         Scripts SQL Server
docs/             Documentacion institucional y tecnica
docker/           Recursos de infraestructura
```

## Backend Python

La API principal queda ubicada en `backend_python`.

Endpoints iniciales:

```text
GET  /api
GET  /api/probar-db
POST /api/auth/login
```

Instalacion de dependencias:

```text
cd backend_python
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
uvicorn app.main:app --host 127.0.0.1 --port 8000 --reload
```

## Frontend PHP

La interfaz web queda ubicada en `frontend_php`.

Ejecucion local:

```text
cd frontend_php
copy .env.example .env
php -S 127.0.0.1:8080 -t public
```

## Estado de migracion

El primer entregable incluye:

- API base.
- Prueba de conexion a SQL Server.
- Inicio de sesión.
- Pantalla principal autenticada.

El resto de modulos se migrara por prioridad funcional:

1. Dashboard y permisos.
2. Cartillas.
3. Eventos y anuncios.
4. Administracion.
5. Personal.
6. Insignias.
7. Soporte.
8. Configuracion.

## Limpieza final

Cuando los modulos tengan paridad funcional comprobada, se retiraran archivos y carpetas de la arquitectura anterior. La referencia al cambio tecnologico se conservara solo en la documentacion de migracion.
