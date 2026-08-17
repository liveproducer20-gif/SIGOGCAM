from datetime import date, time

from fastapi import APIRouter, Depends, HTTPException, Query, Request

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.distribucion_tablero import repository
from app.modules.distribucion_tablero.models import (
    AgentSearchInput,
    ChangeAgentInput,
    CleanAssignmentsInput,
    ConfirmAssignmentInput,
    RandomAssignmentInput,
    RandomDraftInput,
    RouteRequirementInput,
    SaveDistributionInput,
    SubstituteAgentInput,
)


router = APIRouter(tags=["distribucion-tablero"])


@router.get("/distribucion-tablero/tablero")
def board_data(
    distrito_id: int = Query(..., gt=0),
    turno_id: int = Query(..., gt=0),
    fecha: date | None = Query(default=None),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_board_data(distrito_id, turno_id, fecha))


@router.get("/distribucion-tablero/resumen-distritos")
def district_summaries(
    fecha: date = Query(...),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_district_distribution_summaries(fecha))


@router.get("/distribucion-tablero/rutas/{route_id}/lugares")
def route_places(
    route_id: int,
    turno_id: int = Query(..., gt=0),
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_route_places(route_id, turno_id))


@router.get("/distribucion-tablero/disponibilidad")
def board_availability(
    distrito_id: int = Query(..., gt=0),
    turno_id: int = Query(..., gt=0),
    excluidos: str = "",
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    excluded = {int(item) for item in excluidos.split(",") if item.strip().isdigit()}
    return ok(repository.get_board_availability(distrito_id, turno_id, excluded))


@router.post("/distribucion-tablero/asignacion-aleatoria")
def random_draft(
    payload: RandomDraftInput,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    return ok(repository.generate_draft_assignments(payload.model_dump()))


@router.post("/distribucion-tablero/distribuciones", status_code=201)
def save_distribution(
    payload: SaveDistributionInput,
    request: Request,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    result = repository.save_distribution(payload.model_dump(), int(user["id"]), request.client.host if request.client else None)
    return ok(result, "Distribucion guardada correctamente")


@router.get("/distribucion-tablero/distribuciones/{distribution_id}")
def distribution_detail(
    distribution_id: int,
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_distribution(distribution_id))


@router.put("/distribucion-tablero/distribuciones/{distribution_id}")
def update_distribution(
    distribution_id: int,
    payload: SaveDistributionInput,
    request: Request,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    result = repository.update_distribution(
        distribution_id, payload.model_dump(), int(user["id"]), request.client.host if request.client else None
    )
    return ok(result, "Distribucion actualizada correctamente")


@router.delete("/distribucion-tablero/distribuciones/{distribution_id}")
def delete_distribution(
    distribution_id: int,
    request: Request,
    user: dict = Depends(require_permission("tablero_distribucion.eliminar")),
):
    repository.delete_distribution(distribution_id, int(user["id"]), request.client.host if request.client else None)
    return ok(None, "Distribucion eliminada correctamente")


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
        sectores=[sector.model_dump() for sector in payload.sectores],
        user_id=int(user["id"]),
    )
    return ok(result, "Requerimiento de personal actualizado")


@router.post("/distribucion-tablero/agentes-disponibles")
def agents_for_modal(
    payload: AgentSearchInput,
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    data = payload.model_dump()
    data["excluidos"] = data.get("excluidos", [])
    return ok(repository.get_agents_for_modal(data))


@router.post("/distribucion-tablero/cambiar-agente")
def change_agent(
    payload: ChangeAgentInput,
    request: Request,
    user: dict = Depends(require_permission("tablero_distribucion.asignar")),
):
    ip = request.client.host if request.client else None
    result = repository.validate_and_change_agent(
        payload.model_dump(), int(user["id"]), ip
    )
    return ok(result, "Agente cambiado correctamente")


@router.get("/distribucion-tablero/dashboard")
def distributions_dashboard(
    user: dict = Depends(require_permission("tablero_distribucion.ver")),
):
    return ok(repository.get_distributions_dashboard())


@router.delete("/distribucion-tablero/dashboard/{turno_id}")
def delete_distribution_from_dashboard(
    turno_id: int,
    fecha_distribucion: str = Query(...),
    request: Request = None,
    user: dict = Depends(require_permission("tablero_distribucion.eliminar")),
):
    import re as _re
    from datetime import date as _date
    fecha = _date.fromisoformat(fecha_distribucion) if _re.match(r'^\d{4}-\d{2}-\d{2}$', fecha_distribucion) else None
    if not fecha:
        raise HTTPException(422, "Fecha de distribucion invalida")

    ip = request.client.host if request and request.client else None
    deleted = repository.delete_distribution_group(turno_id, fecha, int(user["id"]), ip)
    return ok(None, f"{deleted} distribucion(es) eliminada(s) correctamente")
