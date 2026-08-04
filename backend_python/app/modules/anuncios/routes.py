from fastapi import APIRouter, Depends

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.anuncios.models import AnnouncementCreate, PublishedUpdate
from app.modules.anuncios.repository import (
    create_announcement,
    delete_announcement,
    list_announcements,
    update_published,
)


router = APIRouter(tags=["anuncios"])


@router.get("")
def listar(user: dict = Depends(current_user)):
    return ok(list_announcements())


@router.post("", status_code=201)
def crear(payload: AnnouncementCreate, user: dict = Depends(current_user)):
    new_id = create_announcement({**payload.model_dump(), "creadoPor": int(user["id"])})
    return {**ok(None, "Anuncio creado correctamente"), "id": new_id}


@router.put("/{announcement_id}/publicado")
def publicado(announcement_id: int, payload: PublishedUpdate, user: dict = Depends(current_user)):
    update_published(announcement_id, payload.publicado)
    return ok(None, "Estado del anuncio actualizado")


@router.delete("/{announcement_id}")
def eliminar(announcement_id: int, user: dict = Depends(current_user)):
    delete_announcement(announcement_id)
    return ok(None, "Anuncio eliminado correctamente")
