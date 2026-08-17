from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_any_permission, require_permission
from app.modules.distribucion_geografica.repository_geo import (
    list_rutas_geograficas, get_ruta_geografica, get_ruta_geografica_by_ruta,
    create_ruta_geografica, update_ruta_geografica, delete_ruta_geografica,
    list_lugares_servicio, get_lugar_servicio, create_lugar_servicio,
    update_lugar_servicio, delete_lugar_servicio,
    get_distritos, get_rutas_por_distrito, get_lugares_por_ruta,
    get_asignaciones_punto, create_asignacion_punto, delete_asignacion_punto,
)

router = APIRouter(tags=["distribucion-v2"], dependencies=[Depends(require_permission("distribucion.ver"))])


# ===================================================================
# CATÁLOGOS
# ===================================================================

@router.get("/distritos")
def distritos(user: dict = Depends(current_user)):
    return ok(get_distritos())


@router.get("/distritos/{distrito_id}/rutas")
def rutas_por_distrito(distrito_id: int, user: dict = Depends(current_user)):
    return ok(get_rutas_por_distrito(distrito_id))


@router.get("/rutas/{ruta_id}/lugares-servicio")
def lugares_por_ruta(ruta_id: int, user: dict = Depends(current_user)):
    return ok(get_lugares_por_ruta(ruta_id))


# ===================================================================
# RUTAS GEOGRÁFICAS
# ===================================================================

@router.get("/rutas-geograficas")
def listar_rutas_geograficas(distrito_id: int | None = Query(default=None), user: dict = Depends(current_user)):
    return ok(list_rutas_geograficas(distrito_id))


@router.get("/rutas-geograficas/{ruta_geo_id}")
def obtener_ruta_geografica(ruta_geo_id: int, user: dict = Depends(current_user)):
    item = get_ruta_geografica(ruta_geo_id)
    if not item:
        return {"ok": False, "mensaje": "Ruta geográfica no encontrada"}
    return ok(item)


@router.get("/rutas/{ruta_id}/geografia")
def obtener_geografia_por_ruta(ruta_id: int, user: dict = Depends(current_user)):
    item = get_ruta_geografica_by_ruta(ruta_id)
    if not item:
        return {"ok": False, "mensaje": "No existe trazado geográfico para esta ruta"}
    return ok(item)


@router.post("/rutas-geograficas", status_code=201)
def crear_ruta_geografica(payload: dict, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    item_id = create_ruta_geografica(payload, int(user["id"]))
    return {**ok(None, "Ruta geográfica creada correctamente"), "id": item_id}


@router.put("/rutas-geograficas/{ruta_geo_id}")
def actualizar_ruta_geografica(ruta_geo_id: int, payload: dict, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    update_ruta_geografica(ruta_geo_id, payload, int(user["id"]))
    return ok(None, "Ruta geográfica actualizada correctamente")


@router.delete("/rutas-geograficas/{ruta_geo_id}")
def eliminar_ruta_geografica(ruta_geo_id: int, user: dict = Depends(require_any_permission("rutas_geograficas.gestionar", "distribucion.catalogos"))):
    delete_ruta_geografica(ruta_geo_id, int(user["id"]))
    return ok(None, "Ruta geográfica eliminada correctamente")


# ===================================================================
# LUGARES DE SERVICIO
# ===================================================================

@router.get("/lugares-servicio")
def listar_lugares_servicio(ruta_id: int | None = Query(default=None), distrito_id: int | None = Query(default=None), user: dict = Depends(current_user)):
    return ok(list_lugares_servicio(ruta_id, distrito_id))


@router.get("/lugares-servicio/{lugar_id}")
def obtener_lugar_servicio(lugar_id: int, user: dict = Depends(current_user)):
    item = get_lugar_servicio(lugar_id)
    if not item:
        return {"ok": False, "mensaje": "Lugar de servicio no encontrado"}
    return ok(item)


@router.post("/lugares-servicio", status_code=201)
def crear_lugar_servicio(payload: dict, user: dict = Depends(require_any_permission("distribucion.catalogos", "distribucion.crear"))):
    item_id = create_lugar_servicio(payload, int(user["id"]))
    return {**ok(None, "Lugar de servicio creado correctamente"), "id": item_id}


@router.put("/lugares-servicio/{lugar_id}")
def actualizar_lugar_servicio(lugar_id: int, payload: dict, user: dict = Depends(require_any_permission("distribucion.editar", "distribucion.catalogos"))):
    update_lugar_servicio(lugar_id, payload, int(user["id"]))
    return ok(None, "Lugar de servicio actualizado correctamente")


@router.delete("/lugares-servicio/{lugar_id}")
def eliminar_lugar_servicio(lugar_id: int, user: dict = Depends(require_permission("distribucion.desactivar"))):
    delete_lugar_servicio(lugar_id, int(user["id"]))
    return ok(None, "Lugar de servicio eliminado correctamente")


# ===================================================================
# ASIGNACIONES DE PUNTOS
# ===================================================================

@router.get("/lugares-servicio/{punto_id}/asignaciones")
def asignaciones_punto(punto_id: int, user: dict = Depends(current_user)):
    return ok(get_asignaciones_punto(punto_id))


@router.post("/lugares-servicio/{punto_id}/asignaciones", status_code=201)
def crear_asignacion_punto(punto_id: int, payload: dict, user: dict = Depends(require_permission("distribucion.asignar"))):
    item_id = create_asignacion_punto(punto_id, payload, int(user["id"]))
    return {**ok(None, "Asignación creada correctamente"), "id": item_id}


@router.delete("/asignaciones-punto/{asignacion_id}")
def eliminar_asignacion_punto(asignacion_id: int, user: dict = Depends(require_permission("distribucion.asignar"))):
    delete_asignacion_punto(asignacion_id, int(user["id"]))
    return ok(None, "Asignación eliminada correctamente")
