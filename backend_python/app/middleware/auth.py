from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt

from app.core.config import settings


bearer = HTTPBearer(auto_error=False)


def current_user(credentials: HTTPAuthorizationCredentials | None = Depends(bearer)) -> dict:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status_code=401, detail="Sesion no autorizada")

    try:
        payload = jwt.decode(
            credentials.credentials,
            settings.jwt_secret,
            algorithms=[settings.jwt_algorithm],
        )
    except JWTError:
        raise HTTPException(status_code=401, detail="Sesion expirada o invalida") from None

    return payload


def require_permission(permission: str):
    def checker(user: dict = Depends(current_user)) -> dict:
        permissions = user.get("permisos") or []
        role = str(user.get("rolCodigo") or user.get("rol") or "").upper()
        if "ADMINISTRADOR" not in role and permission not in permissions:
            raise HTTPException(status_code=403, detail="No tiene permiso para esta accion")
        return user

    return checker


def require_any_permission(*permissions: str):
    """Permite el acceso si el usuario tiene al menos uno de los permisos indicados."""

    def checker(user: dict = Depends(current_user)) -> dict:
        user_permissions = set(user.get("permisos") or [])
        role = str(user.get("rolCodigo") or user.get("rol") or "").upper()
        if "ADMINISTRADOR" not in role and not user_permissions.intersection(permissions):
            raise HTTPException(status_code=403, detail="No tiene permiso para esta accion")
        return user

    return checker
