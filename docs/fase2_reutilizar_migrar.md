# Fase 2: Reestructuración Ejecutada

La fase de reutilización fue reemplazada por una reestructuración completa hacia PHP y Python, conservando la base SQL Server y las reglas de negocio institucionales.

## Motivo

El equipo decidió avanzar con PHP para el frontend y Python para el backend porque son los lenguajes que maneja con mayor soltura para mantenimiento, soporte y evolución del sistema.

## Resultado

- Se creó `frontend_php` para la interfaz web.
- Se creó `backend_python` para la API.
- Se mantuvo SQL Server como fuente de datos.
- Se documentaron los módulos actuales en `docs/MODULOS.md`.
- Se corrigieron problemas de codificación UTF-8 con una migración SQL nueva.

## Estado

La plataforma nueva ya ejecuta los módulos principales y conserva acceso a los datos existentes.
