from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.personal.repository import list_people, my_profile


router = APIRouter(tags=["personal"])


@router.get("/perfil/me")
def perfil(user: dict = Depends(current_user)):
    return ok(my_profile(int(user["id"])))


@router.get("")
def listar_personal(
    buscar: str | None = Query(default=None),
    user: dict = Depends(current_user),
):
    return ok(list_people(buscar))


@router.get("/buscar")
def buscar_personal(q: str | None = Query(default=None), user: dict = Depends(current_user)):
    return ok(list_people(q))


@router.get("/operativos")
def operativos(user: dict = Depends(current_user)):
    return ok(list_people())


@router.get("/disponibles")
def disponibles(user: dict = Depends(current_user)):
    return ok(list_people())
