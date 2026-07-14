# Informe de análisis para Docker

Fecha del análisis: 2026-07-14.

## Arquitectura identificada

SIGO-GCAM contiene una API REST Node.js/Express, un cliente Flutter
multiplataforma y una base SQL Server. Flutter tiene destinos Android, iOS,
Windows, Linux, macOS y Web. Docker ejecuta el destino Web; las aplicaciones
móviles y de escritorio se siguen compilando con Flutter fuera de Docker.

La API escucha en el puerto `3000`, usa ODBC Driver 18, JWT y SQL Server. Los
archivos cargados se guardan en `backend/uploads`, mientras que sus rutas se
registran en la base. El cliente usa `SIGO_API_BASE_URL` mediante
`String.fromEnvironment`; localmente conserva `http://127.0.0.1:3000/api` y la
imagen Web se compila con `/api` para usar el proxy de Nginx.

El archivo `Backup/BITSAC2` es un respaldo SQL Server válido de unos 59 MB. Fue
generado por SQL Server 17.x y sus nombres lógicos son `BITSAC` y `BITSAC_log`.
Por ese motivo, la imagen de base debe ser SQL Server 2025 (17.x); SQL Server
2022 no puede restaurar un respaldo creado por una versión posterior.

## Servicios dockerizados

| Servicio | Responsabilidad | Persistencia |
| --- | --- | --- |
| `database` | SQL Server 2025 | Volumen `sigo-gcam-sqlserver-data` |
| `database-init` | Restauración idempotente y `DBCC CHECKDB` | Usa el volumen de SQL Server y termina |
| `backend` | API Express con Node.js 24 LTS y ODBC 18 | Bind mount `backend/uploads` |
| `frontend` | Flutter Web release servido por Nginx | Imagen inmutable |

Nginx publica la interfaz y reenvía `/api` y `/uploads` al backend. Los cuatro
servicios usan una red bridge privada. Los `healthcheck` y las dependencias
condicionales evitan iniciar la API antes de terminar la restauración.

El builder Web parte de la imagen Cirrus Flutter `3.44.0` disponible en GHCR y
fija el tag oficial Flutter `3.44.4` antes de resolver paquetes. Esto es
necesario porque el proyecto exige Dart `3.12.2` y GHCR todavía no publica un
tag de imagen `3.44.4` independiente.

## Archivos creados

- `.env.example` y `.env` local ignorado por Git.
- `.gitattributes`.
- `docker-compose.yml` y `docker-compose.dev.yml`.
- `backend/Dockerfile` y `backend/.dockerignore`.
- `mobile/Dockerfile`, `mobile/.dockerignore`, `mobile/nginx.conf` y
  `mobile/proxy_params`.
- `docker/database/init-database.sh` y
  `docker/database/restore-database.sql`.
- `README_DOCKER.md` y este informe.

## Archivos modificados

- `backend/index.js`: permite configurar `trust proxy`, necesario para conservar
  la IP del cliente detrás de Nginx y para que `express-rate-limit` funcione de
  manera correcta.
- `README.md`: enlaza la documentación Docker.

No se modificaron controladores, servicios, repositorios, consultas ni reglas de
negocio.

## Variables y valores que ya eran configurables

- Backend: `PORT`, `DB_DRIVER`, `DB_SERVER`, `DB_DATABASE`, `DB_USER`,
  `DB_PASSWORD`, opciones TLS/ODBC, `DB_CONNECTION_TIMEOUT`, `JWT_SECRET` y
  `JSON_LIMIT`.
- Flutter: `SIGO_API_BASE_URL`, definida en tiempo de compilación.
- Docker: puertos publicados, imagen/edición SQL Server, respaldo, base, JWT y
  límites se centralizan en `.env`.

Las referencias `localhost` restantes pertenecen a scripts de diagnóstico o a
valores predeterminados para desarrollo local; no intervienen en los
contenedores de producción.

## Riesgos y mitigaciones

1. **Datos sensibles en Git.** `Backup/BITSAC2` ya está versionado y contiene
   datos reales. El Dockerfile no lo incorpora a ninguna imagen, pero debe
   retirarse del historial antes de publicar el repositorio fuera de un entorno
   autorizado. En producción debe entregarse por un canal cifrado.
2. **Licencia SQL Server.** `MSSQL_PID=Developer` solo es válido para desarrollo
   y pruebas. Un despliegue productivo debe usar una edición/licencia válida.
3. **Arquitectura.** Las imágenes Linux de SQL Server están soportadas en
   servidores x86-64; no se debe asumir soporte en ARM.
4. **TLS.** Nginx sirve HTTP dentro de esta solución. En Internet debe colocarse
   un proxy TLS o balanceador delante y restringir los puertos `3000` y `1433`.
5. **Secretos.** `.env` está ignorado por Git. Producción debe usar secretos
   únicos, rotación y permisos de archivo restrictivos.
6. **Volúmenes.** `docker compose down -v` borra la base. Los respaldos externos
   son obligatorios antes de actualizaciones.
7. **Cargas.** `backend/uploads` es un bind mount para conservar y transportar
   los archivos existentes. El usuario del contenedor debe tener escritura en
   esa ruta en Linux.
8. **URL de Flutter.** `SIGO_API_BASE_URL` queda embebida al compilar. Un cambio
   requiere reconstruir `frontend`; el valor `/api` evita depender del dominio.

## Resultado esperado

Con Docker disponible, `docker compose up -d` restaura la base solo cuando no
existe, inicia la API, publica Flutter Web en `http://localhost:8080` y conserva
la base y los archivos cargados entre reinicios.
