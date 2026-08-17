"""Middleware de saneamiento global de cuerpos JSON.

Elimina caracteres de control (incluidos bytes nulos) de todos los valores de
texto de los cuerpos JSON entrantes, de forma recursiva. Es defensa en
profundidad: la capa de acceso a datos ya parametriza todas las consultas.

Solo procesa cuerpos ``application/json`` (no afecta a subidas de archivos
multipart ni a otros content types). No recorta espacios ni trunca: eso se hace
por campo donde corresponde (p. ej. el correo del login), para no alterar
valores legítimos como contraseñas.
"""

import json

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request

from app.core.sanitize import strip_control_chars


def _sanitize_value(value):
    if isinstance(value, str):
        return strip_control_chars(value)
    if isinstance(value, list):
        return [_sanitize_value(item) for item in value]
    if isinstance(value, dict):
        return {key: _sanitize_value(item) for key, item in value.items()}
    return value


class InputSanitizationMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        content_type = request.headers.get("content-type", "")
        if "application/json" in content_type:
            body = await request.body()
            if body:
                try:
                    data = json.loads(body)
                    cleaned = _sanitize_value(data)
                    new_body = json.dumps(cleaned, ensure_ascii=False).encode("utf-8")

                    async def receive():
                        return {"type": "http.request", "body": new_body, "more_body": False}

                    request = Request(request.scope, receive)
                except (json.JSONDecodeError, UnicodeDecodeError):
                    # Deja pasar el cuerpo original; FastAPI responderá su 422.
                    pass
        return await call_next(request)
