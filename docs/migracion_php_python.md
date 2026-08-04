# Reestructuracion tecnologica SIGO-GCAM

## Decision

El sistema SIGO-GCAM sera reestructurado completamente para trabajar con:

- PHP en el frontend.
- Python en el backend.
- SQL Server como base de datos institucional.

La decision se toma porque el equipo de desarrollo y mantenimiento maneja con mayor dominio los lenguajes Python y PHP. Este cambio permite mejorar la mantenibilidad del sistema, facilitar la incorporacion de nuevos modulos y reducir la dependencia de tecnologias que no forman parte del flujo principal del equipo.

## Alcance

La reestructuracion no es un cambio visual menor. Es una migracion completa de arquitectura:

- La interfaz web sera renderizada desde PHP.
- La API sera desarrollada en Python.
- Las reglas de negocio se trasladaran al backend Python.
- La base de datos se mantiene como fuente principal de informacion.
- La documentacion conservara la referencia historica del cambio tecnologico.

## Estructura nueva

```text
backend_python/
  app/
    core/
    middleware/
    modules/

frontend_php/
  app/
    Core/
    Modules/
  public/
  views/

database/
docs/
```

## Regla de limpieza final

Cuando cada modulo tenga paridad funcional, se retiraran del proyecto las carpetas y archivos de la arquitectura anterior. La unica referencia al cambio tecnologico debe quedar en la documentacion institucional de migracion.

## Orden de implementacion

1. Backend Python base.
2. Conexion a SQL Server.
3. Autenticación y sesiones.
4. Frontend PHP base.
5. Dashboard y permisos.
6. Cartillas.
7. Eventos y anuncios.
8. Administracion.
9. Insignias.
10. Soporte.
11. Configuracion de roles y permisos.
12. Limpieza final de rastros tecnicos no utilizados.

## Criterio de modulo terminado

Un modulo se considera migrado cuando:

- Funciona desde PHP.
- Consume la API Python.
- Usa la base SQL Server real.
- Conserva los permisos actuales.
- Conserva los datos existentes.
- No depende de la arquitectura anterior.
- Tiene validacion funcional basica.

## Primer entregable

El primer entregable queda definido como:

- API Python con `/api`.
- API Python con `/api/probar-db`.
- API Python con `/api/auth/login`.
- Frontend PHP con pantalla de inicio de sesión.
- Frontend PHP con dashboard inicial autenticado.

Despues de validar este punto se migra el resto de modulos.
