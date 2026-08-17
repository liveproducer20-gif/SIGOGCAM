from fastapi import APIRouter, Depends

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.insignias.repository import user_progress
from app.modules.personal.repository import my_profile


router = APIRouter(tags=["usuarios"])


@router.get("/{user_id}/perfil")
def perfil_usuario(user_id: int, user: dict = Depends(current_user)):
    if int(user["id"]) != user_id:
        require_permission("personal.ver")(user)
    return ok(my_profile(user_id))


@router.get("/{user_id}/insignias")
def insignias_usuario(user_id: int, user: dict = Depends(current_user)):
    if int(user["id"]) != user_id:
        require_permission("insignias.ver")(user)
    return ok(user_progress(user_id))


@router.get("/{user_id}/progreso-insignias")
def progreso_insignias_usuario(user_id: int, user: dict = Depends(current_user)):
    if int(user["id"]) != user_id:
        require_permission("insignias.ver")(user)
    return ok(user_progress(user_id))
