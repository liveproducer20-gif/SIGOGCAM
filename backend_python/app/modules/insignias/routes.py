from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.insignias.repository import list_badges, ranking, user_progress


router = APIRouter(tags=["insignias"])


@router.get("")
def listar(user: dict = Depends(current_user)):
    return ok(list_badges())


@router.get("/progreso/me")
def mi_progreso(user: dict = Depends(current_user)):
    return ok(user_progress(int(user["id"])))


@router.get("/ranking")
def listar_ranking(
    limite: int = Query(default=10, ge=1, le=100),
    user: dict = Depends(current_user),
):
    return ok(ranking(limite))
