from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.eventos.models import EventCreate, EventStatusUpdate
from app.modules.eventos.repository import (
    create_event,
    delete_event,
    get_event,
    list_events,
    update_status,
)


router = APIRouter(tags=["eventos"])


@router.get("")
def listar(
    personalId: int | None = Query(default=None),
    user: dict = Depends(current_user),
):
    return ok(list_events(personalId))


@router.get("/{event_id}")
def detalle(event_id: int, user: dict = Depends(current_user)):
    event = get_event(event_id)
    if event is None:
        raise HTTPException(status_code=404, detail="Evento no encontrado")
    return ok(event)


@router.post("", status_code=201)
def crear(payload: EventCreate, user: dict = Depends(current_user)):
    new_id = create_event({**payload.model_dump(), "creadoPor": int(user["id"])})
    return {**ok(None, "Evento creado correctamente"), "id": new_id}


@router.put("/{event_id}/estado")
def estado(event_id: int, payload: EventStatusUpdate, user: dict = Depends(current_user)):
    update_status(event_id, payload.estado)
    return ok(None, "Estado actualizado correctamente")


@router.delete("/{event_id}")
def eliminar(event_id: int, user: dict = Depends(current_user)):
    delete_event(event_id)
    return ok(None, "Evento eliminado exitosamente")
