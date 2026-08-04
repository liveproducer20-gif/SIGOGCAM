from fastapi import APIRouter, Depends, HTTPException

from app.core.responses import ok
from app.core.security import create_access_token, verify_password
from app.middleware.auth import current_user
from app.modules.auth.models import LoginRequest
from app.modules.auth.repository import get_permissions_by_role, get_user_by_email
from app.modules.configuracion.repository import build_tree, my_structure


router = APIRouter(tags=["autenticacion"])


@router.post("/login")
def login(payload: LoginRequest):
    user = get_user_by_email(payload.correo)
    if user is None:
        raise HTTPException(status_code=401, detail="Credenciales invalidas")

    password_hash = user.get("password_hash")
    password_ok = False
    if password_hash:
        password_ok = verify_password(payload.password, password_hash)
    else:
        password_ok = payload.password.strip() == str(user.get("cedula") or "").strip()

    if not password_ok:
        raise HTTPException(status_code=401, detail="Credenciales invalidas")

    permisos = get_permissions_by_role(user.get("rol_id"))
    usuario = {
        "id": user["id"],
        "cedula": user.get("cedula") or "",
        "nombres": user.get("nombres") or "",
        "apellidos": user.get("apellidos") or "",
        "nombreCompleto": user.get("nombre_completo") or "",
        "correo": user.get("correo") or "",
        "rolId": user.get("rol_id"),
        "rol": _rol_aplicacion(user.get("rol_codigo") or user.get("rol_nombre") or ""),
        "rolCodigo": user.get("rol_codigo") or "",
        "rolNombre": user.get("rol_nombre") or "",
        "estadoPersonal": user.get("estado_personal") or "",
        "permisos": permisos,
    }
    token = create_access_token(
        {
            "id": int(user["id"]),
            "correo": usuario["correo"],
            "nombres": usuario["nombres"],
            "apellidos": usuario["apellidos"],
            "nombreCompleto": usuario["nombreCompleto"],
            "rol": usuario["rol"],
            "rolId": usuario["rolId"],
            "rolCodigo": usuario["rolCodigo"],
            "permisos": permisos,
        }
    )

    return ok({"usuario": usuario, "token": token}, "Inicio de sesión correcto")


@router.get("/mi-menu")
def mi_menu(user: dict = Depends(current_user)):
    items = my_structure(int(user["id"]))
    return ok(build_tree(items))


def _rol_aplicacion(value: str) -> str:
    normalized = value.strip().upper()
    aliases = {
        "CONSULTA": "USUARIO",
        "AGENTE": "USUARIO",
        "AGENTE MUNICIPAL": "USUARIO",
        "AUDITORIA": "AUDITOR",
    }
    return aliases.get(normalized, normalized)
