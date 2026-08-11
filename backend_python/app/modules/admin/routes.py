from fastapi import APIRouter, Body, Depends, HTTPException

from app.core.responses import ok
from app.middleware.auth import require_permission
from app.modules.admin import repository as repo


router = APIRouter(tags=["administracion"])


def result_created(item_id: int, message: str) -> dict:
    return {**ok(None, message), "id": item_id}


@router.get("/referencias")
def referencias(user: dict = Depends(require_permission("administracion.ver"))):
    return ok(repo.admin_references())


@router.get("/eas")
def eas(user: dict = Depends(require_permission("eas.ver"))):
    return ok(repo.list_eas())


@router.post("/eas", status_code=201)
def crear_eas(payload: dict = Body(...), user: dict = Depends(require_permission("eas.crear"))):
    return result_created(repo.create_eas(payload), "EAS creada correctamente")


@router.put("/eas/{item_id}")
def actualizar_eas(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("eas.editar"))):
    repo.update_eas(item_id, payload)
    return ok(None, "EAS actualizada correctamente")


@router.delete("/eas/{item_id}")
def eliminar_eas(item_id: int, user: dict = Depends(require_permission("eas.estado"))):
    repo.delete_eas(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/moviles")
def moviles(user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_units())


@router.post("/moviles", status_code=201)
def crear_movil(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.crear"))):
    return result_created(repo.create_mobile_unit(payload), "Móvil creado correctamente")


@router.put("/moviles/{item_id}")
def actualizar_movil(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.editar"))):
    repo.update_mobile_unit(item_id, payload)
    return ok(None, "Móvil actualizado correctamente")


@router.delete("/moviles/{item_id}")
def eliminar_movil(item_id: int, user: dict = Depends(require_permission("moviles.estado"))):
    repo.delete_mobile_unit(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/rutas")
def rutas(user: dict = Depends(require_permission("rutas.ver"))):
    return ok(repo.list_routes())


@router.post("/rutas", status_code=201)
def crear_ruta(payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_route(payload), "Ruta creada correctamente")


@router.put("/rutas/{item_id}")
def actualizar_ruta(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_route(item_id, payload)
    return ok(None, "Ruta actualizada correctamente")


@router.delete("/rutas/{item_id}")
def eliminar_ruta(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_route(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/lugares-servicio")
def lugares(user: dict = Depends(require_permission("lugares_servicio.ver"))):
    return ok(repo.list_service_places())


@router.post("/lugares-servicio", status_code=201)
def crear_lugar(payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.crear"))):
    return result_created(repo.create_service_place(payload), "Lugar creado correctamente")


@router.post("/lugares-servicio/importar")
def importar_lugares(payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.crear"))):
    try:
        result = repo.import_service_places(payload.get("filas", []), bool(payload.get("confirmar", False)))
    except ValueError as exception:
        raise HTTPException(status_code=422, detail=str(exception)) from exception
    message = "Importación completada" if payload.get("confirmar") else "Archivo validado correctamente"
    return ok(result, message)


@router.put("/lugares-servicio/{item_id}")
def actualizar_lugar(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("lugares_servicio.editar"))):
    repo.update_service_place(item_id, payload)
    return ok(None, "Lugar actualizado correctamente")


@router.delete("/lugares-servicio/{item_id}")
def eliminar_lugar(item_id: int, user: dict = Depends(require_permission("lugares_servicio.estado"))):
    repo.delete_service_place(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/grados")
def grados(user: dict = Depends(require_permission("personal.ver"))):
    return ok(repo.list_grades())


@router.post("/grados", status_code=201)
def crear_grado(payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_grade(payload), "Grado creado correctamente")


@router.put("/grados/{item_id}")
def actualizar_grado(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_grade(item_id, payload)
    return ok(None, "Grado actualizado correctamente")


@router.delete("/grados/{item_id}")
def eliminar_grado(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_grade(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/catalogos")
def catalogos(user: dict = Depends(require_permission("catalogos.ver"))):
    return ok(repo.list_catalogs_admin())


@router.get("/catalogos/{codigo}")
def detalles(codigo: str, user: dict = Depends(require_permission("catalogos.ver"))):
    return ok(repo.list_catalog_details(codigo.upper()))


@router.post("/catalogos/{codigo}", status_code=201)
def crear_detalle(codigo: str, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.crear"))):
    return result_created(repo.create_catalog_detail(codigo.upper(), payload), "Detalle creado correctamente")


@router.put("/catalogos/detalles/{item_id}")
def actualizar_detalle(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("catalogos.editar"))):
    repo.update_catalog_detail(item_id, payload)
    return ok(None, "Detalle actualizado correctamente")


@router.delete("/catalogos/detalles/{item_id}")
def eliminar_detalle(item_id: int, user: dict = Depends(require_permission("catalogos.estado"))):
    repo.delete_catalog_detail(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/movil-eas-asignaciones")
def asignaciones(user: dict = Depends(require_permission("moviles.asignar"))):
    return ok(repo.list_mobile_assignments())


@router.post("/movil-eas-asignaciones", status_code=201)
def crear_asignacion(payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    return result_created(repo.create_mobile_assignment(payload), "Asignación creada correctamente")


@router.put("/movil-eas-asignaciones/{item_id}")
def actualizar_asignacion(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.asignar"))):
    repo.update_mobile_assignment(item_id, payload)
    return ok(None, "Asignación actualizada correctamente")


@router.delete("/movil-eas-asignaciones/{item_id}")
def eliminar_asignacion(item_id: int, user: dict = Depends(require_permission("moviles.asignar"))):
    repo.delete_mobile_assignment(item_id)
    return ok(None, "Registro eliminado correctamente")


@router.get("/dashboard/mantenimiento")
def mantenimiento(user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_maintenance())


@router.get("/moviles/{item_id}/mantenimientos")
def mantenimientos_movil(item_id: int, user: dict = Depends(require_permission("moviles.ver"))):
    return ok(repo.list_mobile_maintenance(item_id))


@router.post("/moviles/{item_id}/mantenimientos", status_code=201)
def crear_mantenimiento(item_id: int, payload: dict = Body(...), user: dict = Depends(require_permission("moviles.editar"))):
    return result_created(repo.create_mobile_maintenance(item_id, payload), "Mantenimiento registrado correctamente")
