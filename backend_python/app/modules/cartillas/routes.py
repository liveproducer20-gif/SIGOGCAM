from fastapi import APIRouter, Depends, HTTPException

from app.core.responses import ok
from app.middleware.auth import current_user
from app.modules.cartillas.models import CartillaCreate
from app.modules.cartillas.repository import active_eas, operational_catalogs, register_card


router = APIRouter(tags=["cartillas"])


@router.get("/catalogos-operativos")
def catalogos_operativos(user: dict = Depends(current_user)):
    return ok(operational_catalogs())


@router.get("/eas")
def listar_eas(user: dict = Depends(current_user)):
    return ok(active_eas())


@router.post("", status_code=201)
def registrar_cartilla(payload: CartillaCreate, user: dict = Depends(current_user)):
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
