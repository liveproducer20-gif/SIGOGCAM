from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.eventos.models import EventCreate, EventStatusUpdate
from app.modules.eventos.repository import (
    create_event,
    delete_event,
    get_event,
    list_events,
    update_status,
    update_event,
)


router = APIRouter(tags=["eventos"])


@router.get("")
def listar(
    personalId: int | None = Query(default=None),
    user: dict = Depends(require_permission("eventos.ver")),
):
    manager = "ADMINISTRADOR" in str(user.get("rolCodigo") or user.get("rol") or "").upper() or any(p in (user.get("permisos") or []) for p in ("eventos.crear","eventos.editar","eventos.eliminar"))
    return ok(list_events(personalId if manager else int(user["id"])))


@router.get("/{event_id}")
def detalle(event_id: int, user: dict = Depends(require_permission("eventos.ver"))):
    event = get_event(event_id)
    if event is None:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    return ok(event)


@router.post("", status_code=201)
def crear(payload: EventCreate, user: dict = Depends(require_permission("eventos.crear"))):
    new_id = create_event({**payload.model_dump(), "creadoPor": int(user["id"])})
    return {**ok(None, "Evento creado correctamente"), "id": new_id}


@router.put("/{event_id}")
def actualizar(event_id: int, payload: EventCreate, user: dict = Depends(require_permission("eventos.editar"))):
    update_event(event_id,payload.model_dump())
    return ok(None,"Evento actualizado correctamente")


@router.put("/{event_id}/estado")
def estado(event_id: int, payload: EventStatusUpdate, user: dict = Depends(require_permission("eventos.editar"))):
    update_status(event_id, payload.estado)
    return ok(None, "Estado actualizado correctamente")


@router.delete("/{event_id}")
def eliminar(event_id: int, user: dict = Depends(require_permission("eventos.eliminar"))):
    delete_event(event_id)
    return ok(None, "Evento eliminado exitosamente")
