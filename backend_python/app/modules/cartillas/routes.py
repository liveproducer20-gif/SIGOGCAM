from fastapi import APIRouter, Body, Depends, HTTPException, Query

from app.core.responses import ok
from app.middleware.auth import require_permission
from app.modules.cartillas.models import CartillaCreate
from app.modules.cartillas.repository import active_eas, control_chief, create_eas_address, create_police_server, eas_addresses, eas_mobile_assignments, get_temp_cp, operational_catalogs, police_servers, register_card, save_temp_cp


router = APIRouter(tags=["cartillas"])


@router.get("/catalogos-operativos")
def catalogos_operativos(user: dict = Depends(require_permission("cartillas.ver"))):
    return ok(operational_catalogs())


@router.get("/eas")
def listar_eas(user: dict = Depends(require_permission("cartillas.ver"))):
    return ok(active_eas())


@router.post("", status_code=201)
def registrar_cartilla(payload: CartillaCreate, user: dict = Depends(require_permission("cartillas.generar"))):
    if not payload.contenido.strip():
        raise HTTPException(status_code=400, detail="El contenido de la cartilla es obligatorio")

    result = register_card(
        {
            "usuario_id": int(user["id"]),
            "causa": payload.causa.strip() if payload.causa else None,
            "contenido": payload.contenido.strip(),
            "tipo": payload.tipo.strip().upper() if payload.tipo else None,
            "subtipo": payload.subtipo.strip().upper() if payload.subtipo else None,
            "datos": payload.datos,
        }
    )
    return {
        **ok(None, "Cartilla generada correctamente"),
        **result,
        "advertencia": None,
    }


@router.get("/temp/cp")
def temp_cp(user: dict = Depends(require_permission("cartillas.ver"))): return ok(get_temp_cp(int(user["id"])))

@router.put("/temp/cp")
def guardar_temp_cp(payload: dict=Body(...),user:dict=Depends(require_permission("cartillas.generar"))): save_temp_cp(int(user["id"]),str(payload.get("nombreCp") or "")); return ok(None,"CP temporal guardado")

@router.get("/servidores-policiales")
def servidores(easId:int|None=Query(default=None),user:dict=Depends(require_permission("cartillas.ver"))): return ok(police_servers(easId))

@router.post("/servidores-policiales",status_code=201)
def crear_servidor(payload:dict=Body(...),user:dict=Depends(require_permission("cartillas.generar"))): return {**ok(None,"Servidor registrado"),"id":create_police_server(int(payload["easId"]),str(payload["nombre"]))}

@router.get("/jefe-control-municipal")
def jefe(user:dict=Depends(require_permission("cartillas.ver"))): return ok(control_chief())

@router.get("/eas-direcciones")
def direcciones(easId:int=Query(...),user:dict=Depends(require_permission("cartillas.ver"))): return ok(eas_addresses(easId))

@router.post("/eas-direcciones",status_code=201)
def crear_direccion(payload:dict=Body(...),user:dict=Depends(require_permission("cartillas.generar"))): return {**ok(None,"Dirección registrada"),"id":create_eas_address(int(payload["easId"]),str(payload["direccion"]))}

@router.get("/asignaciones-eas-moviles")
def asignaciones(user:dict=Depends(require_permission("cartillas.ver"))): return ok(eas_mobile_assignments())
