from fastapi import APIRouter

from app.core.responses import ok
from app.modules.catalogos.repository import list_catalogs, list_details_by_code


router = APIRouter(tags=["catalogos"])


@router.get("")
def catalogos():
    return ok(list_catalogs())


@router.get("/{codigo}")
def detalle_catalogo(codigo: str):
    return {
        **ok(list_details_by_code(codigo)),
        "catalogo": codigo.upper(),
    }
