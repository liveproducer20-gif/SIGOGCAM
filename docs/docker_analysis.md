# Contenedores de Desarrollo

La plataforma vigente usa una composición de servicios basada en:

- SQL Server para base de datos.
- API Python con FastAPI.
- Frontend PHP servido por el runtime PHP.

## Servicios

| Servicio | Descripción |
| --- | --- |
| `database` | Instancia SQL Server con base `BITSAC` |
| `database-init` | Inicialización o restauración de base |
| `api` | Backend Python |
| `web` | Frontend PHP |

## Puertos

| Servicio | Puerto |
| --- | --- |
| API | `8000` |
| Web | `8080` en Docker, `8081` en la prueba local actual porque `8080` estaba ocupado |
| SQL Server | `1433` |

## Motivo de la Reestructuración

La migración tecnológica se realizó para mejorar la mantenibilidad del sistema con herramientas dominadas por el equipo: Python en backend y PHP en frontend.
