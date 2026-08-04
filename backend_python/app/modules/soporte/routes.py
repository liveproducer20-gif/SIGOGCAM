from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.soporte.models import TicketCreate, TicketUpdate
from app.modules.soporte.repository import create_ticket, list_tickets, stats, update_ticket


router = APIRouter(tags=["soporte"])


@router.get("/stats")
def estadisticas(user: dict = Depends(current_user)):
    return ok(stats())


@router.get("/tickets")
def tickets(
    buscar: str | None = Query(default=None),
    limite: int = Query(default=50, ge=1, le=200),
    user: dict = Depends(current_user),
):
    return ok(list_tickets(buscar, limite))


@router.post("/tickets", status_code=201)
def crear(payload: TicketCreate, user: dict = Depends(current_user)):
    ticket_id = create_ticket(
        {
            **payload.model_dump(),
            "usuario_id": int(user["id"]),
            "usuario_nombre": user.get("nombreCompleto") or user.get("correo") or "Usuario",
            "rol": user.get("rol"),
            "area": user.get("area"),
        }
    )
    return {**ok(None, "Alerta de soporte creada correctamente"), "id": ticket_id}


@router.put("/tickets/{ticket_id}")
def actualizar(ticket_id: int, payload: TicketUpdate, user: dict = Depends(current_user)):
    update_ticket(ticket_id, payload.model_dump())
    return ok(None, "Alerta de soporte actualizada correctamente")
