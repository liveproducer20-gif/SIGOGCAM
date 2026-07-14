# BITSAC - SIGO-GCAM

Sistema Inteligente de Gesti\u00f3n Operativa para el Cuerpo de Agentes de Control Municipal de Guayaquil.

## Estructura del Proyecto

```
BITSAC/
  backend/          API REST (Node.js + Express 5 + SQL Server)
  mobile/           App m\u00f3vil multiplataforma (Flutter/Dart)
  database/         Migraciones SQL y seeds
  scripts/          Scripts utilitarios
  patch/            Parches para la app m\u00f3vil
```

## Requisitos

- Node.js >= 18
- SQL Server (local o remoto)
- ODBC Driver 18 for SQL Server
- Flutter SDK 3.44+ (para mobile)

## Inicio R\u00e1pido (Backend)

```bash
cd backend
cp .env.example .env   # Configurar variables de entorno
npm install
npm start              # Inicia en http://localhost:3000
```

## Inicio con Docker

La plataforma completa (SQL Server, API y Flutter Web) puede iniciarse con:

```bash
docker compose up -d
```

Consulte [README_DOCKER.md](README_DOCKER.md) para la instalación, operación,
respaldos, actualización y recomendaciones de producción.

## Base de Datos

Ejecutar los scripts en `database/` en orden cronol\u00f3gico (formato YYYYMMDD).

## M\u00f3dulos

- Autenticaci\u00f3n JWT + RBAC
- Gesti\u00f3n de Personal
- Eventos y Convocatorias
- Anuncios y Notificaciones
- Cartillas de Novedades
- Insignias (Gamificaci\u00f3n)
- Administraci\u00f3n (Cat\u00e1logos, Roles, M\u00f3viles, EAS)
