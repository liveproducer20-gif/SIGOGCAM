from datetime import date

from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_any_permission, require_permission
from app.modules.distribucion_geografica import repository
from app.modules.distribucion_geografica.models import (
    AssignmentInput, AssignmentUpdate, PlaceLocationInput, PointInput,
    HierarchicalTraceInput, RouteInput, RouteTraceInput, SectorInput,
)


router = APIRouter(tags=["distribucion-geografica"])


@router.get("/distribucion-geografica/catalogos")
def get_catalogs(user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.catalogs())


@router.get("/distritos")
def get_districts(user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.catalogs()["distritos"])


@router.get("/distritos/{district_id}/rutas")
def get_routes(district_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.routes_by_district(district_id))


@router.get("/distritos/{district_id}/circuitos")
def get_circuits(district_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.circuits_by_district(district_id))


@router.get("/circuitos/{circuit_id}/rutas")
def get_routes_by_circuit(circuit_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.routes_by_circuit(circuit_id))


@router.post("/distritos/{district_id}/rutas", status_code=201)
def post_route(district_id: int, payload: RouteInput, user: dict = Depends(require_permission("distribucion.catalogos"))):
    data = payload.model_dump(); data["distrito_id"] = district_id
    return ok({"id": repository.create_route(data, int(user["id"]))}, "Ruta creada correctamente")


@router.get("/rutas/{route_id}/sectores")
def get_sectors(route_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.sectors_by_route(route_id))


@router.post("/rutas/{route_id}/sectores", status_code=201)
def post_sector(route_id: int, payload: SectorInput, user: dict = Depends(require_permission("distribucion.catalogos"))):
    data = payload.model_dump(); data["ruta_id"] = route_id
    return ok({"id": repository.create_sector(data, int(user["id"]))}, "Sector creado correctamente")


@router.get("/rutas/{route_id}/lugares-servicio")
def get_service_places(route_id: int, distrito_id: int | None = None, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.service_places_by_route(route_id, distrito_id))


@router.get("/distribucion-geografica/rutas/{route_id}/mapa")
def get_route_map(route_id: int, distrito_id: int = Query(...), fecha: date | None = Query(None),
                  circuito_id: int | None = Query(None), turno_id: int | None = Query(None),
                  user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.route_map(route_id, distrito_id, fecha, circuito_id, turno_id))


@router.get("/distribucion-geografica/distrito/{district_id}/mapa-todas")
def get_all_routes_map(district_id: int, fecha: date | None = Query(None), circuito_id: int | None = Query(None),
                       turno_id: int | None = Query(None),
                       user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.all_routes_map(district_id, fecha, circuito_id, turno_id))


@router.get("/distribucion-geografica/mapa")
def get_global_map(fecha: date | None = Query(None), turno_id: int | None = Query(None),
                   user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.global_map(fecha, turno_id))


@router.get("/distribucion-geografica/personal-mapa")
def get_map_personnel(distrito_id: int, fecha: date | None = Query(None), circuito_id: int | None = Query(None),
                      ruta_id: int | None = Query(None), turno_id: int | None = Query(None),
                      user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.personnel_map(distrito_id, fecha, circuito_id, ruta_id, turno_id))


@router.put("/distribucion-geografica/distritos/{district_id}/trazado")
def put_district_trace(district_id: int, payload: HierarchicalTraceInput,
                       user: dict = Depends(require_permission("rutas_geograficas.gestionar"))):
    result = repository.upsert_hierarchical_trace("DISTRITO", district_id, payload.model_dump(), int(user["id"]))
    return ok(result, "Trazado del distrito guardado correctamente")


@router.put("/distribucion-geografica/circuitos/{circuit_id}/trazado")
def put_circuit_trace(circuit_id: int, payload: HierarchicalTraceInput,
                      user: dict = Depends(require_permission("rutas_geograficas.gestionar"))):
    result = repository.upsert_hierarchical_trace("CIRCUITO", circuit_id, payload.model_dump(), int(user["id"]))
    return ok(result, "Trazado del circuito guardado correctamente")


@router.put("/distribucion-geografica/rutas/{route_id}/trazado")
def put_route_trace(route_id: int, payload: RouteTraceInput,
                    user: dict = Depends(require_permission("rutas_geograficas.gestionar"))):
    result = repository.upsert_route_trace(route_id, payload.model_dump(), int(user["id"]))
    return ok(result, "Trazado asignado correctamente" if result["creado"] else "Trazado actualizado correctamente")


@router.put("/distribucion-geografica/lugares/{place_id}/ubicacion")
def put_place_location(place_id: int, payload: PlaceLocationInput,
                       user: dict = Depends(require_permission("distribucion.editar"))):
    return ok(repository.update_place_location(place_id, payload.model_dump(), int(user["id"])), "Ubicación guardada correctamente")


@router.delete("/distribucion-geografica/lugares/{place_id}/ubicacion")
def delete_place_location(place_id: int, user: dict = Depends(require_permission("distribucion.editar"))):
    return ok(repository.remove_place_location(place_id, int(user["id"])), "Ubicación eliminada correctamente")


@router.get("/distribucion-geografica/puntos")
def points(distrito_id: int | None = None, ruta_id: int | None = None, turno_id: int | None = None,
           estado: str | None = None, agente: str | None = None,
           user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.list_points(locals()))


@router.get("/distribucion-geografica/puntos/{point_id}")
def point(point_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.get_point(point_id))


@router.post("/distribucion-geografica/puntos", status_code=201)
def post_point(payload: PointInput, user: dict = Depends(require_permission("distribucion.crear"))):
    data = payload.model_dump()
    point_id = repository.create_point(data, int(user["id"]))
    message = "Punto georreferenciado y personal asignado correctamente." if payload.asignaciones else "Punto georreferenciado creado correctamente."
    return ok({"id": point_id}, message)


@router.put("/distribucion-geografica/puntos/{point_id}")
def put_point(point_id: int, payload: PointInput, user: dict = Depends(require_permission("distribucion.editar"))):
    repository.update_point(point_id, payload.model_dump(exclude={"asignaciones"}), int(user["id"]))
    return ok(None, "Punto georreferenciado actualizado correctamente")


@router.delete("/distribucion-geografica/puntos/{point_id}")
def delete_point(point_id: int, user: dict = Depends(require_permission("distribucion.desactivar"))):
    repository.deactivate_point(point_id, int(user["id"]))
    return ok(None, "Punto georreferenciado desactivado correctamente")


@router.get("/distribucion-geografica/resumen")
def get_summary(user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.summary())


@router.get("/personal/{person_id}/asignaciones")
def person_assignments(person_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.person_assignments(person_id))


@router.post("/distribucion-geografica/puntos/{point_id}/asignaciones", status_code=201)
def post_assignment(point_id: int, payload: AssignmentInput, user: dict = Depends(require_permission("distribucion.asignar"))):
    item_id = repository.add_assignment(point_id, payload.model_dump(), int(user["id"]))
    return ok({"id": item_id}, "Personal asignado correctamente")


@router.put("/distribucion-geografica/asignaciones/{assignment_id}")
def put_assignment(assignment_id: int, payload: AssignmentUpdate, user: dict = Depends(require_permission("distribucion.asignar"))):
    repository.update_assignment(assignment_id, payload.model_dump(), int(user["id"]))
    return ok(None, "Asignación actualizada correctamente")


@router.delete("/distribucion-geografica/asignaciones/{assignment_id}")
def delete_assignment(assignment_id: int, user: dict = Depends(require_permission("distribucion.asignar"))):
    repository.remove_assignment(assignment_id, int(user["id"]))
    return ok(None, "Agente retirado del punto correctamente")


# ===================================================================
# CONSOLIDADO: rutas geográficas, lugares de servicio y asignaciones
# de punto (antes módulo v2: routes_geo.py). Permisos finos.
# ===================================================================


@router.get("/rutas-geograficas")
def listar_rutas_geograficas(distrito_id: int | None = Query(default=None), user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.list_rutas_geograficas(distrito_id))


@router.get("/rutas-geograficas/{ruta_geo_id}")
def obtener_ruta_geografica(ruta_geo_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    item = repository.get_ruta_geografica(ruta_geo_id)
    if not item:
        return {"ok": False, "mensaje": "Ruta geográfica no encontrada"}
    return ok(item)


@router.get("/rutas/{ruta_id}/geografia")
def obtener_geografia_por_ruta(ruta_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    item = repository.get_ruta_geografica_by_ruta(ruta_id)
    if not item:
        return {"ok": False, "mensaje": "No existe trazado geográfico para esta ruta"}
    return ok(item)


@router.post("/rutas-geograficas", status_code=201)
def crear_ruta_geografica(payload: dict, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    item_id = repository.create_ruta_geografica(payload, int(user["id"]))
    return {**ok(None, "Ruta geográfica creada correctamente"), "id": item_id}


@router.put("/rutas-geograficas/{ruta_geo_id}")
def actualizar_ruta_geografica(ruta_geo_id: int, payload: dict, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    repository.update_ruta_geografica(ruta_geo_id, payload, int(user["id"]))
    return ok(None, "Ruta geográfica actualizada correctamente")


@router.delete("/rutas-geograficas/{ruta_geo_id}")
def eliminar_ruta_geografica(ruta_geo_id: int, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    repository.delete_ruta_geografica(ruta_geo_id, int(user["id"]))
    return ok(None, "Ruta geográfica eliminada correctamente")


@router.get("/lugares-servicio")
def listar_lugares_servicio(ruta_id: int | None = Query(default=None), distrito_id: int | None = Query(default=None), user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.list_lugares_servicio(ruta_id, distrito_id))


@router.get("/lugares-servicio/{lugar_id}")
def obtener_lugar_servicio(lugar_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    item = repository.get_lugar_servicio(lugar_id)
    if not item:
        return {"ok": False, "mensaje": "Lugar de servicio no encontrado"}
    return ok(item)


@router.post("/lugares-servicio", status_code=201)
def crear_lugar_servicio(payload: dict, user: dict = Depends(require_any_permission("distribucion.catalogos", "distribucion.crear"))):
    item_id = repository.create_lugar_servicio(payload, int(user["id"]))
    return {**ok(None, "Lugar de servicio creado correctamente"), "id": item_id}


@router.put("/lugares-servicio/{lugar_id}")
def actualizar_lugar_servicio(lugar_id: int, payload: dict, user: dict = Depends(require_any_permission("distribucion.editar", "distribucion.catalogos"))):
    repository.update_lugar_servicio(lugar_id, payload, int(user["id"]))
    return ok(None, "Lugar de servicio actualizado correctamente")


@router.delete("/lugares-servicio/{lugar_id}")
def eliminar_lugar_servicio(lugar_id: int, user: dict = Depends(require_permission("distribucion.desactivar"))):
    repository.delete_lugar_servicio(lugar_id, int(user["id"]))
    return ok(None, "Lugar de servicio eliminado correctamente")


@router.get("/lugares-servicio/{punto_id}/asignaciones")
def asignaciones_punto(punto_id: int, user: dict = Depends(require_permission("distribucion.ver"))):
    return ok(repository.get_asignaciones_punto(punto_id))


@router.post("/lugares-servicio/{punto_id}/asignaciones", status_code=201)
def crear_asignacion_punto(punto_id: int, payload: dict, user: dict = Depends(require_permission("distribucion.asignar"))):
    item_id = repository.create_asignacion_punto(punto_id, payload, int(user["id"]))
    return {**ok(None, "Asignación creada correctamente"), "id": item_id}


@router.delete("/asignaciones-punto/{asignacion_id}")
def eliminar_asignacion_punto(asignacion_id: int, user: dict = Depends(require_permission("distribucion.asignar"))):
    repository.delete_asignacion_punto(asignacion_id, int(user["id"]))
    return ok(None, "Asignación eliminada correctamente")
