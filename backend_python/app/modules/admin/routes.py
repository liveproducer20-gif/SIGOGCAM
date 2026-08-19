from fastapi import APIRouter, Body, Depends, HTTPException, Query

from app.core.responses import ok
from app.middleware.auth import require_permission
from app.modules.admin import repository as repo


router = APIRouter(tags=["administracion"])


def result_created(item_id: int, message: str) -> dict:
    return {**ok(None, message), "id": item_id}


def circuit_action(action):
    try:
        return action()
    except ValueError as exception:
        raise HTTPException(status_code=422, detail=str(exception)) from exception


@router.get("/referencias")
def referencias(user: dict = Depends(require_permission("administracion.ver"))):
    return ok(repo.admin_references())


@router.get("/eas-estacion")
def eas_estacion(user: dict = Depends(require_permission("administracion.ver"))):
    """Return active EAS for Estacion de Accion Segura district."""
    return ok(repo.list_eas_for_estacion())


@router.get("/eas")
def eas(user: dict = Depends(require_permission("eas.ver"))):
    return ok(repo.list_eas())


@router.post("/eas", status_code=201)
def crear_eas(payload: dict = Body(...), user: dict = Depends(require_permission("eas.crear"))):
    return result_created(repo.create_eas(payload), "EAS creada correctamente")


@router.put("/eas/{item_id}")
def actualizar_eas(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("eas.editar"))):
    repo.update_eas(item_id, payload)
    return ok(None, "EAS actualizada correctamente")


@router.delete("/eas/{item_id}")
def eliminar_eas(item_id: int, user: dict = Depends(require_permission("eas.estado"))):
    repo.delete_eas(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/moviles")
def moviles(user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_units())


@router.post("/moviles", status_code=201)
def crear_movil(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.crear"))):
    return result_created(repo.create_mobile_unit(payload), "Móvil creado correctamente")


@router.put("/moviles/{item_id}")
def actualizar_movil(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.editar"))):
    repo.update_mobile_unit(item_id, payload)
    return ok(None, "Móvil actualizado correctamente")


@router.delete("/moviles/{item_id}")
def eliminar_movil(item_id: int, user: dict = Depends(require_permission("moviles.estado"))):
    repo.delete_mobile_unit(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/rutas")
def rutas(user: dict = Depends(require_permission("rutas.ver"))):
    return ok(repo.list_routes())


@router.get("/rutas/{item_id}/turnos")
def ruta_turnos(item_id: int, user: dict = Depends(require_permission("rutas.ver"))):
    """Return the enabled turn IDs for a specific route."""
    from app.core.db import get_connection as _gc
    with _gc() as connection:
        cursor = connection.cursor()
        turnos = repo.get_route_turnos(cursor, item_id)
    return ok({"turnosIds": turnos})


@router.get("/rutas/{item_id}/turnos/{turno_id}/lugares")
def count_places_by_turn(item_id: int, turno_id: int, user: dict = Depends(require_permission("rutas.ver"))):
    """Count how many active places are linked to a specific turn in a route."""
    from app.core.db import get_connection as _gc
    with _gc() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT COUNT(*)
            FROM dbo.lugares_servicio ls
            INNER JOIN dbo.lugar_turnos lt ON lt.lugar_servicio_id = ls.id AND lt.turno_id = ?
            WHERE ls.ruta_id = ? AND ls.activo = 1
        """, turno_id, item_id)
        count = int(cursor.fetchone()[0])
    return ok({"lugaresVinculados": count})


@router.post("/rutas", status_code=201)
def crear_ruta(payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_route(payload), "Ruta creada correctamente")


@router.post("/rutas/importar")
def importar_rutas(payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    try:
        result = repo.import_routes(payload.get("filas", []), bool(payload.get("confirmar", False)), payload.get("accionesExistentes"))
    except ValueError as exception:
        raise HTTPException(status_code=422, detail=str(exception)) from exception
    message = "Importación completada" if payload.get("confirmar") else "Archivo validado correctamente"
    return ok(result, message)


@router.put("/rutas/{item_id}")
def actualizar_ruta(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_route(item_id, payload)
    return ok(None, "Ruta actualizada correctamente")


@router.delete("/rutas/{item_id}")
def eliminar_ruta(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_route(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/circuitos")
def circuitos(
    distrito_id: int | None = None,
    buscar: str | None = None,
    user: dict = Depends(require_permission("circuitos.ver")),
):
    return ok(repo.list_circuits(distrito_id, buscar))


@router.get("/circuitos/rutas-disponibles")
def rutas_disponibles(
    distrito_id: int = Query(..., gt=0),
    circuito_id: int | None = Query(default=None),
    user: dict = Depends(require_permission("circuitos.ver")),
):
    """Return routes available for a circuit: unassigned + routes of the given circuit."""
    return ok(repo.get_available_routes_for_circuit(distrito_id, circuito_id))


@router.get("/circuitos/{item_id}")
def circuito(item_id: int, user: dict = Depends(require_permission("circuitos.ver"))):
    return circuit_action(lambda: ok(repo.get_circuit(item_id)))


@router.post("/circuitos", status_code=201)
def crear_circuito(payload: dict = Body(...), user: dict = Depends(require_permission("circuitos.crear"))):
    return circuit_action(lambda: result_created(repo.create_circuit(payload), "Circuito creado correctamente"))


@router.post("/circuitos/{item_id}/rutas/importar")
def importar_rutas_circuito(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("circuitos.rutas"))):
    def action():
        result = repo.import_routes(
            payload.get("filas", []), bool(payload.get("confirmar", False)),
            payload.get("accionesExistentes"), item_id,
        )
        message = "Importación completada" if payload.get("confirmar") else "Archivo validado correctamente"
        return ok(result, message)
    return circuit_action(action)


@router.put("/circuitos/{item_id}")
def actualizar_circuito(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("circuitos.editar"))):
    def action():
        repo.update_circuit(item_id, payload)
        return ok(None, "Circuito actualizado correctamente")
    return circuit_action(action)


@router.put("/circuitos/{item_id}/rutas")
def gestionar_rutas_circuito(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("circuitos.rutas"))):
    def action():
        repo.replace_circuit_routes(item_id, payload.get("rutaIds") or [])
        return ok(None, "Rutas del circuito actualizadas correctamente")
    return circuit_action(action)


@router.delete("/circuitos/{item_id}")
def eliminar_circuito(item_id: int, user: dict = Depends(require_permission("circuitos.eliminar"))):
    def action():
        repo.delete_circuit(item_id)
        return ok(None, "Circuito eliminado correctamente")
    return circuit_action(action)


@router.get("/lugares-servicio")
def lugares(user: dict = Depends(require_permission("lugares_servicio.ver"))):
    return ok(repo.list_service_places())


@router.post("/lugares-servicio", status_code=201)
def crear_lugar(payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.crear"))):
    return result_created(repo.create_service_place(payload), "Lugar creado correctamente")


@router.post("/lugares-servicio/importar")
def importar_lugares(payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.crear"))):
    try:
        result = repo.import_service_places(
            payload.get("filas", []),
            bool(payload.get("confirmar", False)),
            payload.get("accionesExistentes"),
        )
    except ValueError as exception:
        raise HTTPException(status_code=422, detail=str(exception)) from exception
    message = "Importación completada" if payload.get("confirmar") else "Archivo validado correctamente"
    return ok(result, message)


@router.post("/lugares-servicio/eliminar-por-alcance")
def eliminar_lugares_por_alcance(payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.estado"))):
    try:
        deleted = repo.delete_service_places_by_scope(payload.get("rutaId"), payload.get("circuitoId"))
    except ValueError as exception:
        raise HTTPException(status_code=422, detail=str(exception)) from exception
    return ok({"eliminados": deleted}, f"{deleted} lugar(es) eliminado(s) correctamente")


@router.put("/lugares-servicio/{item_id}")
def actualizar_lugar(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.editar"))):
    repo.update_service_place(item_id, payload)
    return ok(None, "Lugar actualizado correctamente")


@router.delete("/lugares-servicio/{item_id}")
def eliminar_lugar(item_id: int, user: dict = Depends(require_permission("lugares_servicio.estado"))):
    repo.delete_service_place(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/grados")
def grados(user: dict = Depends(require_permission("personal.ver"))):
    return ok(repo.list_grades())


@router.post("/grados", status_code=201)
def crear_grado(payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_grade(payload), "Grado creado correctamente")


@router.put("/grados/{item_id}")
def actualizar_grado(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_grade(item_id, payload)
    return ok(None, "Grado actualizado correctamente")


@router.delete("/grados/{item_id}")
def eliminar_grado(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_grade(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/catalogos")
def catalogos(user: dict = Depends(require_permission("catalogos.ver"))):
    return ok(repo.list_catalogs_admin())


@router.get("/catalogos/{codigo}")
def detalles(codigo: str, user: dict = Depends(require_permission("catalogos.ver"))):
    return ok(repo.list_catalog_details(codigo.upper()))


@router.post("/catalogos/{codigo}", status_code=201)
def crear_detalle(codigo: str, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_catalog_detail(codigo.upper(), payload), "Detalle creado correctamente")


@router.put("/catalogos/detalles/{item_id}")
def actualizar_detalle(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_catalog_detail(item_id, payload)
    return ok(None, "Detalle actualizado correctamente")


@router.delete("/catalogos/detalles/{item_id}")
def eliminar_detalle(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_catalog_detail(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/movil-eas-asignaciones")
def asignaciones(user: dict = Depends(require_permission("moviles.asignar"))):
    return ok(repo.list_mobile_assignments())


@router.get("/movil-eas-asignaciones/lugar-eas-id")
def eas_id_from_route(ruta_id: int, user: dict = Depends(require_permission("moviles.asignar"))):
    """Return the EAS station ID for a given route."""
    from app.core.db import get_connection
    with get_connection() as conn:
        cursor = conn.cursor()
        eas_id = repo._resolve_eas_from_route(cursor, ruta_id)
        return ok({"eas_id": eas_id})


@router.get("/movil-eas-asignaciones/lugares-por-ruta")
def lugares_por_ruta(ruta_id: int, user: dict = Depends(require_permission("moviles.asignar"))):
    """Return active service places for a given route."""
    from app.core.db import get_connection
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, nombre FROM dbo.lugares_servicio WHERE ruta_id=? AND activo=1 ORDER BY nombre",
            ruta_id,
        )
        return ok([{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()])


@router.get("/movil-eas-asignaciones/rutas-eas")
def rutas_eas(user: dict = Depends(require_permission("moviles.asignar"))):
    """Return routes in the EAS district for the assignment form."""
    from app.core.db import get_connection
    with get_connection() as conn:
        cursor = conn.cursor()
        cursor.execute(
            "SELECT id, nombre FROM dbo.rutas WHERE distrito_id=1143 AND activo=1 ORDER BY nombre"
        )
        return ok([{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()])


@router.post("/movil-eas-asignaciones/importar-preview")
def preview_import(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    """Validate CSV rows and return results without saving."""
    rows = payload.get("rows", [])
    results = repo.preview_assignments_csv(rows)
    valid = sum(1 for r in results if r["valido"])
    return ok({"filas": results, "total": len(results), "validos": valid, "rechazados": len(results) - valid})


@router.post("/movil-eas-asignaciones/importar-confirm")
def confirm_import(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    """Import validated rows."""
    rows = payload.get("rows", [])
    result = repo.import_assignments_csv(rows, user_id=user.get("id"))
    return ok(result, f"{result['creados']} asignaciones creadas correctamente")


@router.post("/movil-eas-asignaciones", status_code=201)
def crear_asignacion(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    return result_created(repo.create_mobile_assignment(payload), "Asignación creada correctamente")


@router.put("/movil-eas-asignaciones/{item_id}")
def actualizar_asignacion(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    repo.update_mobile_assignment(item_id, payload)
    return ok(None, "Asignación actualizada correctamente")


@router.delete("/movil-eas-asignaciones/{item_id}")
def eliminar_asignacion(item_id: int, user: dict = Depends(require_permission("moviles.asignar"))):
    repo.delete_mobile_assignment(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/dashboard/mantenimiento")
def mantenimiento(user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_maintenance())


@router.get("/moviles/{item_id}/mantenimientos")
def mantenimientos_movil(item_id: int, user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_maintenance(item_id))


@router.post("/moviles/{item_id}/mantenimientos", status_code=201)
def crear_mantenimiento(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.editar"))):
    return result_created(repo.create_mobile_maintenance(item_id, payload), "Mantenimiento registrado correctamente")
