# SIGO-GCAM con Docker

Esta configuración inicia SQL Server 2025, restaura la base BITSAC, ejecuta la
API Node.js y publica Flutter Web mediante Nginx.

## Requisitos

- Docker Desktop con contenedores Linux en Windows, o Docker Engine con el
  plugin Compose en Linux.
- CPU x86-64.
- Al menos 4 GB de memoria disponibles para Docker; se recomiendan 8 GB.
- Puertos `8080`, `3000` y `1433` libres, o valores alternativos en `.env`.
- El respaldo `Backup/BITSAC2` y la carpeta `backend/uploads`.

En Windows, abra PowerShell **como Administrador**. Si WSL 2 aún no está
habilitado, ejecute:

```powershell
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
```

Reinicie Windows, actualice WSL e instale Docker Desktop:

```powershell
wsl --update
winget install --id Docker.DockerDesktop -e --accept-package-agreements --accept-source-agreements
```

Abra Docker Desktop una vez y espere a que indique que el motor está activo.

## Preparación inicial

El entorno de trabajo actual ya contiene un `.env` local ignorado por Git. En
una computadora o servidor nuevo:

```powershell
Copy-Item .env.example .env
```

En Linux:

```bash
cp .env.example .env
```

Edite como mínimo `MSSQL_SA_PASSWORD` y `JWT_SECRET`. La contraseña de SQL
Server debe tener al menos ocho caracteres y combinar mayúsculas, minúsculas,
números y símbolos. Para generar un JWT en PowerShell:

```powershell
$bytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
-join ($bytes | ForEach-Object { $_.ToString('x2') })
```

No agregue `.env` al repositorio.

## Iniciar la plataforma

```bash
docker compose up -d
```

La primera ejecución descarga imágenes, compila Flutter y restaura el respaldo,
por lo que puede tardar varios minutos. Direcciones predeterminadas:

- Aplicación Web: `http://localhost:8080`
- API directa: `http://localhost:3000/api`
- Prueba de base: `http://localhost:3000/api/probar-db`
- SQL Server para SSMS: `localhost,1433`, usuario `sa` y la contraseña de `.env`

El acceso normal del navegador usa Nginx; `/api` y `/uploads` se reenvían al
backend sin depender de `localhost` dentro de Flutter.

## Estado y logs

```bash
docker compose ps
docker compose logs -f
docker compose logs -f database
docker compose logs -f database-init
docker compose logs -f backend
docker compose logs -f frontend
```

`database-init` debe aparecer como terminado con código `0`; es un proceso de
una sola ejecución, no un servicio permanente.

## Detener o reiniciar

Detener conservando los datos:

```bash
docker compose down
```

Reiniciar:

```bash
docker compose restart
```

No use `docker compose down -v` salvo que realmente quiera eliminar la base
restaurada. La carpeta `backend/uploads` nunca se elimina mediante Compose.

## Construir y reconstruir

```bash
docker compose build
docker compose up -d --build
docker compose build --no-cache backend frontend
```

Si cambia `SIGO_API_BASE_URL`, debe reconstruir `frontend` porque Flutter usa
esa variable en tiempo de compilación.

## Desarrollo del backend

El override de desarrollo monta el código y usa el modo watch de Node.js:

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

Flutter usa como valor local `http://127.0.0.1:3000/api`. En Chrome conserva
esa dirección y en el emulador Android la convierte automáticamente a
`http://10.0.2.2:3000/api`, por lo que no es necesario cambiar valores entre
ambos destinos. Para un dispositivo físico indique la IP del equipo:

```bash
flutter run --dart-define=SIGO_API_BASE_URL=http://192.168.1.20:3000/api
```

## Ingresar a los contenedores

```bash
docker compose exec backend sh
docker compose exec frontend sh
docker compose exec database bash
```

Consulta SQL desde el contenedor:

```bash
docker compose exec database /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "SU_CLAVE" -C -d BITSAC -Q "SELECT DB_NAME()"
```

Evite escribir contraseñas en historiales de terminal en servidores compartidos.

## Actualizar la plataforma

```bash
git pull --ff-only
docker compose build --pull
docker compose up -d
docker image prune
```

Realice un respaldo antes de actualizar. Para copiar un `.bak` creado dentro de
SQL Server al host puede montar una carpeta de respaldos autorizada o ejecutar
el backup desde SSMS contra `localhost,1433`.

## Restaurar de cero

La restauración es idempotente: si BITSAC existe, no se sobrescribe. Para crear
un entorno vacío desde el respaldo actual:

1. Genere y conserve un respaldo de cualquier dato que necesite.
2. Detenga Compose.
3. Elimine expresamente el volumen `sigo-gcam-sqlserver-data`.
4. Verifique que `Backup/BITSAC2` sea el respaldo correcto.
5. Ejecute nuevamente `docker compose up -d`.

Eliminar el volumen destruye la base del entorno Docker y no tiene reversión sin
un respaldo.

## Producción Linux

- Cambie todas las credenciales y use un gestor de secretos.
- Configure una edición licenciada mediante `MSSQL_PID`.
- No publique `3000` ni `1433` a Internet; restrínjalos mediante firewall o
  elimine esos mapeos y publique únicamente el proxy HTTPS.
- Coloque TLS delante del puerto de frontend.
- Asegure permisos de escritura para `backend/uploads`.
- Automatice respaldos externos de SQL Server y de `backend/uploads`.
- Fije y pruebe las actualizaciones de imágenes antes de desplegarlas.

## Diagnóstico

Validar la configuración resuelta:

```bash
docker compose config
```

Comprobar salud:

```bash
docker compose ps
curl http://localhost:3000/api/probar-db
curl http://localhost:8080/healthz
```

Si `database` se detiene, revise que la contraseña cumpla la política. Si
`database-init` falla al restaurar, confirme que se usa SQL Server 2025 (17.x),
que `Backup/BITSAC2` existe y que Docker puede leerlo.
