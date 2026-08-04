# Limpieza final de la reestructuracion

## Criterio

La limpieza final se ejecutara cuando los modulos hayan sido migrados y validados en la nueva arquitectura PHP y Python.

El objetivo es que el proyecto final conserve solamente:

- `backend_python`
- `frontend_php`
- `database`
- `docker`
- `docs`
- archivos de configuracion necesarios para despliegue

## Elementos a retirar al completar la paridad

```text
backend/
mobile/
```

Tambien se retiraran archivos de configuracion asociados a herramientas que ya no formen parte de la arquitectura final.

## Motivo del cambio

El sistema se reestructura porque el equipo maneja mejor Python y PHP. Con esto se busca mejorar el mantenimiento, acelerar correcciones y facilitar la evolucion del sistema por parte del equipo interno.

## Regla de seguridad

No se eliminara una carpeta funcional hasta que exista un reemplazo validado en la nueva arquitectura. Esto evita perder modulos activos durante la transicion.
