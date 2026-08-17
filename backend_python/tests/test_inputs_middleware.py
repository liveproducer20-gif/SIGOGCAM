"""Pruebas del middleware de saneamiento de entrada (app/middleware/inputs.py).

Se prueban tanto el sanitizador puro (``_sanitize_value``) como el flujo
completo de ``dispatch`` (reconstrucción del Request con el cuerpo limpio),
sin depender de httpx/TestClient.
"""

import json

import anyio
import pytest
from starlette.requests import Request
from starlette.responses import Response

from app.middleware.inputs import InputSanitizationMiddleware, _sanitize_value


# ---------------------------------------------------------------------------
# _sanitize_value (función pura)
# ---------------------------------------------------------------------------

class TestSanitizeValue:
    def test_elimina_controles_de_strings(self):
        assert _sanitize_value("x\x00y\x1f") == "xy"

    def test_conserva_espacios_y_multilinea(self):
        assert _sanitize_value("  pass word  \nnext") == "  pass word  \nnext"

    def test_recorre_anidados(self):
        data = {"a": "x\x00", "b": ["y\x1f", {"c": "z\x00"}], "d": {"e": "w\x7f"}}
        assert _sanitize_value(data) == {
            "a": "x",
            "b": ["y", {"c": "z"}],
            "d": {"e": "w"},
        }

    def test_conserva_tipos_no_texto(self):
        data = {"n": 3, "f": 1.5, "b": True, "nulo": None, "l": [1, 2]}
        assert _sanitize_value(data) == data


# ---------------------------------------------------------------------------
# Flujo completo de dispatch
# ---------------------------------------------------------------------------

def _make_request(body: bytes, content_type: str = "application/json") -> Request:
    async def receive():
        return {"type": "http.request", "body": body, "more_body": False}

    scope = {
        "type": "http",
        "http_version": "1.1",
        "method": "POST",
        "path": "/api/test",
        "raw_path": b"/api/test",
        "headers": [(b"content-type", content_type.encode("latin-1"))],
        "scheme": "http",
        "server": ("testserver", 80),
        "client": ("testclient", 50000),
        "query_string": b"",
        "root_path": "",
    }
    return Request(scope, receive)


async def _dispatch(body: bytes, content_type: str = "application/json"):
    captured = {}

    async def call_next(request):
        captured["body"] = await request.body()
        captured["request"] = request
        return Response("ok", status_code=200)

    middleware = InputSanitizationMiddleware(lambda scope, receive, send: None)
    response = await middleware.dispatch(_make_request(body, content_type), call_next)
    return response, captured


class TestDispatch:
    def test_sanitiza_cuerpo_json(self):
        async def run():
            body = json.dumps({"nombre": "Ana\x00María\x1f", "pass": " abc "}).encode()
            response, captured = await _dispatch(body)
            assert response.status_code == 200
            parsed = json.loads(captured["body"])
            assert parsed == {"nombre": "AnaMaría", "pass": " abc "}

        anyio.run(run)

    def test_acepta_content_type_con_charset(self):
        async def run():
            body = json.dumps({"a": "x\x00"}).encode()
            _, captured = await _dispatch(body, "application/json; charset=utf-8")
            assert json.loads(captured["body"]) == {"a": "x"}

        anyio.run(run)

    def test_no_toca_content_type_no_json(self):
        async def run():
            body = b"x\x00y\x1f"  # no es JSON: debe pasar intacto
            _, captured = await _dispatch(body, "text/plain")
            assert captured["body"] == b"x\x00y\x1f"

        anyio.run(run)

    def test_json_invalido_pasa_intacto(self):
        async def run():
            body = b'{"mal: '
            _, captured = await _dispatch(body)
            assert captured["body"] == body

        anyio.run(run)

    def test_cuerpo_vacio_no_rompe(self):
        async def run():
            _, captured = await _dispatch(b"")
            assert captured["body"] == b""

        anyio.run(run)

    def test_anidados_y_listas_en_cuerpo_real(self):
        async def run():
            raw = {"items": [{"n": "a\x00"}, {"n": "b"}], "total": 2, "ok": True}
            body = json.dumps(raw).encode()
            _, captured = await _dispatch(body)
            assert json.loads(captured["body"]) == {
                "items": [{"n": "a"}, {"n": "b"}],
                "total": 2,
                "ok": True,
            }

        anyio.run(run)

    def test_unicode_se_conserva(self):
        async def run():
            body = json.dumps({"nombre": "José López ✓"}).encode("utf-8")
            _, captured = await _dispatch(body)
            assert json.loads(captured["body"]) == {"nombre": "José López ✓"}

        anyio.run(run)


class TestRegistroEnApp:
    def test_middleware_registrado_en_aplicacion(self):
        from app.main import app

        clases = [item.cls for item in app.user_middleware]
        assert InputSanitizationMiddleware in clases
