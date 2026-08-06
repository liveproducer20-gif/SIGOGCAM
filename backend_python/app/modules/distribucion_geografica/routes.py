from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.distribucion_geografica import repository
from app.modules.distribucion_geografica.models import AssignmentInput, AssignmentUpdate, PointInput, RouteInput, SectorInput


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


@router.get("/distribucion-geografica/puntos")
def points(distrito_id: int | None = None, ruta_id: int | None = None, turno_id: int | None = None,
           sector_id: int | None = None, estado: str | None = None, agente: str | None = None,
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
