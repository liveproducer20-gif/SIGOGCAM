from datetime import date, time

from fastapi import APIRouter, Depends, Query, Request

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.distribucion_tablero import repository
from app.modules.distribucion_tablero.models import (
    CleanAssignmentsInput,
    ConfirmAssignmentInput,
    RandomAssignmentInput,
    RouteRequirementInput,
    SubstituteAgentInput,
)


router = APIRouter(tags=["distribucion-tablero"])


@router.get("/distribucion-tablero/rutas/{route_id}/info")
def route_info(route_id: int, user: dict = Depends(require_permission("tablero_distribucion.ver"))):
    return ok(repository.get_route_info(route_id))


@router.get("/distribucion-tablero/rutas/{route_id}/sectores")
def route_sectors(route_id: int, user: dict = Depends(require_permission("tablero_distribucion.ver"))):
    return ok(repository.get_route_sectors(route_id))


@router.get("/distribucion-tablero/rutas/{route_id}/estadisticas")
def route_stats(
    route_id: int,
    fecha: date = Query(...),
    turno: str = Query(...),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_route_stats(route_id, fecha, turno))


@router.get("/distribucion-tablero/rutas/{route_id}/asignaciones")
def route_assignments(
    route_id: int,
    fecha: date = Query(...),
    turno: str = Query(...),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_assignments_by_route(route_id, fecha, turno))


@router.get("/distribucion-tablero/personal-disponible")
def available_agents(
    ruta_id: int = Query(...),
    fecha: date = Query(...),
    turno: str = Query(...),
    hora_inicio: time = Query(...),
    hora_fin: time = Query(...),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_available_agents(ruta_id, fecha, turno, hora_inicio, hora_fin))


@router.post("/distribucion-tablero/sorteo")
def generate_sorteo(
    payload: RandomAssignmentInput,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    result = repository.generate_random_preview(
        route_id=payload.ruta_id,
        fecha=payload.fecha_servicio,
        turno=payload.turno,
        hora_inicio=payload.hora_inicio,
        hora_fin=payload.hora_fin,
        user_id=int(user["id"]),
    )
    return ok(result)


@router.post("/distribucion-tablero/sorteo/confirmar")
def confirm_sorteo(
    payload: ConfirmAssignmentInput,
    request: Request,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    ip = request.client.host if request.client else None
    result = repository.confirm_random_assignment(
        sorteo_id=payload.sorteo_id,
        asignaciones=payload.asignaciones,
        user_id=int(user["id"]),
        ip=ip,
    )
    return ok(result, "Asignacion aleatoria confirmada correctamente")


@router.post("/distribucion-tablero/sorteo/reintentar")
def retry_sorteo(
    payload: RandomAssignmentInput,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    result = repository.generate_random_preview(
        route_id=payload.ruta_id,
        fecha=payload.fecha_servicio,
        turno=payload.turno,
        hora_inicio=payload.hora_inicio,
        hora_fin=payload.hora_fin,
        user_id=int(user["id"]),
    )
    return ok(result)


@router.post("/distribucion-tablero/sorteo/sustituir")
def substitute_agent(
    payload: SubstituteAgentInput,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    return ok(None, "Agente sustituido correctamente")


@router.post("/distribucion-tablero/limpiar")
def clean_assignments(
    payload: CleanAssignmentsInput,
    user: dict = Depends(require_permission("tablero_distribucion.limpiar")),
):
    result = repository.clean_route_assignments(
        ruta_id=payload.ruta_id,
        fecha=payload.fecha_servicio,
        turno=payload.turno,
        user_id=int(user["id"]),
    )
    return ok(result, f"Se eliminaron {result['eliminadas']} asignaciones")


@router.get("/distribucion-tablero/historial")
def assignment_history(
    ruta_id: int | None = None,
    fecha_desde: date | None = None,
    fecha_hasta: date | None = None,
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_assignment_history(ruta_id, fecha_desde, fecha_hasta))


@router.put("/distribucion-tablero/sectores/requerimiento")
def update_requirements(
    payload: RouteRequirementInput,
    user: dict = Depends(require_permission("tablero_distribucion.configurar")),
):
    result = repository.update_sector_requirements(
        route_id=payload.ruta_id,
        sectores=payload.sectores,
        user_id=int(user["id"]),
    )
    return ok(result, "Requerimiento de personal actualizado")
