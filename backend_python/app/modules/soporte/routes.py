from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from fastapi import HTTPException
from app.middleware.auth import current_user, require_permission
from app.modules.soporte.models import CommentCreate, TicketCreate, TicketUpdate
from app.modules.soporte.repository import add_comment, create_ticket, list_tickets, stats, ticket_detail, update_ticket


router = APIRouter(tags=["soporte"])


@router.get("/stats")
def estadisticas(user: dict = Depends(current_user)):
    admin = "ADMINISTRADOR" in str(user.get("rolCodigo") or user.get("rol") or "").upper() or "soporte.listar" in (user.get("permisos") or [])
    return ok(stats(None if admin else int(user["id"])))


@router.get("/tickets")
def tickets(
    buscar: str | None = Query(default=None),
    limite: int = Query(default=50, ge=1, le=200),
    user: dict = Depends(current_user),
):
    admin = "ADMINISTRADOR" in str(user.get("rolCodigo") or user.get("rol") or "").upper() or "soporte.listar" in (user.get("permisos") or [])
    return ok(list_tickets(buscar, limite, None if admin else int(user["id"])))


@router.get("/tickets/{ticket_id}")
def detalle(ticket_id: int, user: dict = Depends(current_user)):
    admin = "ADMINISTRADOR" in str(user.get("rolCodigo") or user.get("rol") or "").upper() or "soporte.listar" in (user.get("permisos") or [])
    item=ticket_detail(ticket_id,None if admin else int(user["id"]))
    if item is None: raise HTTPException(status_code=404,detail="Alerta no encontrada")
    if not admin: item["comentarios"]=[x for x in item["comentarios"] if not x.get("es_interno")]
    return ok(item)


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
    if "ADMINISTRADOR" not in str(user.get("rolCodigo") or user.get("rol") or "").upper() and "soporte.listar" not in (user.get("permisos") or []): raise HTTPException(status_code=403,detail="No tiene permiso para administrar alertas")
    update_ticket(ticket_id, {**payload.model_dump(),"actualizado_por":user.get("nombreCompleto") or user.get("correo")})
    return ok(None, "Alerta de soporte actualizada correctamente")


@router.post("/tickets/{ticket_id}/comentarios", status_code=201)
def comentar(ticket_id: int, payload: CommentCreate, user: dict = Depends(require_permission("soporte.comentar"))):
    new_id=add_comment(ticket_id,{**payload.model_dump(),"usuario_id":int(user["id"]),"usuario_nombre":user.get("nombreCompleto") or user.get("correo"),"rol":user.get("rol")})
    return {**ok(None,"Comentario registrado correctamente"),"id":new_id}
