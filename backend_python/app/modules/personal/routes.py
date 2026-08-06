from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.personal.models import PersonalInput
from app.modules.personal.repository import list_people, my_profile, get_person, create_person, update_person, delete_person, catalogs_for_personal


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


@router.get("/catalogos")
def get_catalogs(user: dict = Depends(current_user)):
    return ok(catalogs_for_personal())


@router.get("/{person_id}")
def get_person_by_id(person_id: int, user: dict = Depends(current_user)):
    return ok(get_person(person_id))


@router.post("", status_code=201)
def create_person_endpoint(payload: PersonalInput, user: dict = Depends(require_permission("personal.crear"))):
    person_id = create_person(payload.model_dump(), int(user["id"]))
    return {**ok(None, "Personal creado correctamente"), "id": person_id}


@router.put("/{person_id}")
def update_person_endpoint(person_id: int, payload: PersonalInput, user: dict = Depends(require_permission("personal.editar"))):
    update_person(person_id, payload.model_dump(), int(user["id"]))
    return ok(None, "Personal actualizado correctamente")


@router.delete("/{person_id}")
def delete_person_endpoint(person_id: int, user: dict = Depends(require_permission("personal.editar"))):
    delete_person(person_id, int(user["id"]))
    return ok(None, "Personal eliminado correctamente")
