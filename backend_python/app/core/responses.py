from typing import Any


def ok(datos: Any = None, mensaje: str = "Operacion correcta") -> dict:
    return {
        "ok": True,
        "mensaje": mensaje,
        "datos": datos,
    }


def fail(mensaje: str, datos: Any = None) -> dict:
    return {
        "ok": False,
        "mensaje": mensaje,
        "datos": datos,
    }

