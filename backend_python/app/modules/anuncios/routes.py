from fastapi import APIRouter, Depends

from app.core.responses import ok
from app.middleware.auth import require_permission
from app.modules.anuncios.models import AnnouncementCreate, PublishedUpdate
from app.modules.anuncios.repository import (
    create_announcement,
    delete_announcement,
    list_announcements,
    update_published,
    update_announcement,
)


router = APIRouter(tags=["anuncios"])


@router.get("")
def listar(user: dict = Depends(require_permission("anuncios.ver"))):
    manager = "ADMINISTRADOR" in str(user.get("rolCodigo") or user.get("rol") or "").upper() or any(p in (user.get("permisos") or []) for p in ("anuncios.crear","anuncios.editar","anuncios.publicar"))
    return ok(list_announcements(None if manager else int(user["id"])))


@router.post("", status_code=201)
def crear(payload: AnnouncementCreate, user: dict = Depends(require_permission("anuncios.crear"))):
    new_id = create_announcement({**payload.model_dump(), "creadoPor": int(user["id"])})
    return {**ok(None, "Anuncio creado correctamente"), "id": new_id}


@router.put("/{announcement_id}/publicado")
def publicado(announcement_id: int, payload: PublishedUpdate, user: dict = Depends(require_permission("anuncios.publicar"))):
    update_published(announcement_id, payload.publicado)
    return ok(None, "Estado del anuncio actualizado")


@router.put("/{announcement_id}")
def actualizar(announcement_id: int, payload: AnnouncementCreate, user: dict = Depends(require_permission("anuncios.editar"))):
    update_announcement(announcement_id,payload.model_dump())
    return ok(None,"Anuncio actualizado correctamente")


@router.delete("/{announcement_id}")
def eliminar(announcement_id: int, user: dict = Depends(require_permission("anuncios.eliminar"))):
    delete_announcement(announcement_id)
    return ok(None, "Anuncio eliminado correctamente")
