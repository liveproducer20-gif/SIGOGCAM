from fastapi import APIRouter, Depends

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.configuracion.repository import (
    all_permissions,
    all_modules,
    build_tree,
    current_version,
    data_scopes,
    delete_role_condition,
    menu_configuration,
    my_structure,
    role_conditions,
    roles_configuration,
    save_data_scope,
    save_menu_configuration,
    save_role_condition,
    update_role_permissions,
)


router = APIRouter(tags=["configuracion"])


@router.get("/mi-estructura")
def mi_estructura(user: dict = Depends(current_user)):
    items = my_structure(int(user["id"]))
    return ok(build_tree(items))


@router.get("/roles")
def roles(user: dict = Depends(current_user)):
    return ok(roles_configuration())


@router.get("/version")
def version(user: dict = Depends(current_user)):
    return ok(current_version())


@router.get("/permisos")
def permisos(user: dict = Depends(current_user)):
    return ok(all_permissions())


@router.put("/roles/{role_id}/permisos")
def guardar_permisos(role_id: int, payload: dict, user: dict = Depends(current_user)):
    update_role_permissions(role_id, payload.get("permisoIds") or [])
    return ok(None, "Permisos del rol actualizados correctamente")


@router.get("/modulos")
def modulos(user: dict = Depends(current_user)):
    return ok(all_modules())


@router.get("/roles/{role_id}/menu")
def menu_rol(role_id: int, user: dict = Depends(current_user)):
    return ok(menu_configuration(role_id))


@router.put("/roles/{role_id}/menu")
def guardar_menu_rol(role_id: int, payload: dict, user: dict = Depends(current_user)):
    save_menu_configuration(role_id, payload.get("items") or [])
    return ok(None, "Menú del rol actualizado correctamente")


@router.get("/roles/{role_id}/alcance")
def alcance_rol(role_id: int, user: dict = Depends(current_user)):
    return ok(data_scopes(role_id))


@router.post("/roles/{role_id}/alcance", status_code=201)
def guardar_alcance_rol(role_id: int, payload: dict, user: dict = Depends(current_user)):
    item_id = save_data_scope(role_id, payload)
    return {**ok(None, "Alcance de datos guardado correctamente"), "id": item_id}


@router.get("/roles/{role_id}/condiciones")
def condiciones_rol(role_id: int, user: dict = Depends(current_user)):
    return ok(role_conditions(role_id))


@router.post("/roles/{role_id}/condiciones", status_code=201)
def guardar_condicion_rol(role_id: int, payload: dict, user: dict = Depends(current_user)):
    item_id = save_role_condition(role_id, payload)
    return {**ok(None, "Condición guardada correctamente"), "id": item_id}


@router.delete("/roles/{role_id}/condiciones/{condition_id}")
def eliminar_condicion_rol(role_id: int, condition_id: int, user: dict = Depends(current_user)):
    delete_role_condition(role_id, condition_id)
    return ok(None, "Condición desactivada correctamente")
