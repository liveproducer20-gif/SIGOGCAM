"""Pruebas de autenticación: login, fallback por cédula y tokens JWT.

El login se prueba con el repositorio mockeado (sin depender de la BD); la
validación de tokens se prueba contra endpoints protegidos reales.
"""

from datetime import datetime, timedelta, timezone

import pytest
from jose import jwt as jose_jwt

from app.core.config import settings
from app.core.security import create_access_token, hash_password
from app.modules.auth import routes as auth_routes
from app.modules.auth.routes import get_permissions_by_role, get_user_by_email


def _fake_user(**overrides):
    user = {
        "id": 1,
        "cedula": "0910000010",
        "nombres": "Usuario",
        "apellidos": "Prueba",
        "nombre_completo": "Usuario Prueba",
        "correo": "admin@bitsac.local",
        "estado_personal": "ACTIVO",
        "rol_id": 1,
        "rol_nombre": "Administrador",
        "rol_codigo": "ADMINISTRADOR",
        "password_hash": hash_password("ClaveSegura123!"),
    }
    user.update(overrides)
    return user


@pytest.fixture()
def mock_login(monkeypatch):
    def _mock(user):
        monkeypatch.setattr(auth_routes, "get_user_by_email", lambda correo: user)
        monkeypatch.setattr(auth_routes, "get_permissions_by_role", lambda rol_id: ["*"])

    return _mock


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------

class TestLogin:
    def test_login_ok(self, client, mock_login):
        mock_login(_fake_user())
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local", "password": "ClaveSegura123!"})
        assert response.status_code == 200
        body = response.json()
        assert body.get("ok") is True
        assert body["datos"]["token"]
        assert body["datos"]["usuario"]["correo"] == "admin@bitsac.local"

    def test_login_password_incorrecta(self, client, mock_login):
        mock_login(_fake_user())
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local", "password": "incorrecta"})
        assert response.status_code == 401

    def test_login_correo_desconocido(self, client, mock_login):
        mock_login(None)
        response = client.post("/api/auth/login", json={"correo": "nadie@bitsac.local", "password": "x"})
        assert response.status_code == 401

    def test_login_correo_formato_invalido(self, client):
        response = client.post("/api/auth/login", json={"correo": "sin-arroba", "password": "x"})
        assert response.status_code == 422

    def test_login_sin_password(self, client):
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local"})
        assert response.status_code == 422

    def test_login_normaliza_mayusculas_y_espacios(self, client, mock_login):
        mock_login(_fake_user())
        response = client.post(
            "/api/auth/login",
            json={"correo": "  ADMIN@BITSAC.LOCAL  ", "password": "ClaveSegura123!"},
        )
        assert response.status_code == 200

    # --- Fallback por cédula (hallazgo C3: cuenta sin password_hash) ---

    def test_login_fallback_cedula(self, client, mock_login):
        # Sin password_hash: la contraseña es la cédula (comportamiento actual C3).
        mock_login(_fake_user(password_hash=None))
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local", "password": "0910000010"})
        assert response.status_code == 200

    def test_login_fallback_cedula_incorrecta(self, client, mock_login):
        mock_login(_fake_user(password_hash=None))
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local", "password": "9999999999"})
        assert response.status_code == 401

    def test_login_hash_sha256_rechazado(self, client, mock_login):
        # Hash sha256 (de antes del fix A5): bcrypt debe rechazarlo.
        mock_login(_fake_user(password_hash="5e884898da28047151d0e56f8dc6292773603d0d6aabbdd62a11ef721d1542d8"))
        response = client.post("/api/auth/login", json={"correo": "admin@bitsac.local", "password": "ClaveSegura123!"})
        assert response.status_code == 401


# ---------------------------------------------------------------------------
# Tokens
# ---------------------------------------------------------------------------

@pytest.fixture()
def mock_mi_menu(monkeypatch):
    monkeypatch.setattr(auth_routes, "my_structure", lambda user_id: [])
    monkeypatch.setattr(auth_routes, "build_tree", lambda items: {"items": items})


def _valid_token():
    return create_access_token({"id": 1, "correo": "admin@bitsac.local", "permisos": ["*"], "rolCodigo": "ADMINISTRADOR"})


class TestTokens:
    def test_sin_token(self, client, mock_mi_menu):
        response = client.get("/api/auth/mi-menu")
        assert response.status_code == 401

    def test_token_invalido(self, client, mock_mi_menu):
        response = client.get("/api/auth/mi-menu", headers={"Authorization": "Bearer abc.def.ghi"})
        assert response.status_code == 401

    def test_token_manipulado(self, client, mock_mi_menu):
        token = _valid_token()[:-2] + ("ab" if _valid_token()[-2:] != "ab" else "cd")
        response = client.get("/api/auth/mi-menu", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 401

    def test_token_expirado(self, client, mock_mi_menu):
        expirado = jose_jwt.encode(
            {"id": 1, "exp": datetime.now(timezone.utc) - timedelta(minutes=1)},
            settings.jwt_secret,
            algorithm=settings.jwt_algorithm,
        )
        response = client.get("/api/auth/mi-menu", headers={"Authorization": f"Bearer {expirado}"})
        assert response.status_code == 401

    def test_token_valido(self, client, mock_mi_menu):
        response = client.get("/api/auth/mi-menu", headers={"Authorization": f"Bearer {_valid_token()}"})
        assert response.status_code == 200

    def test_token_firmado_con_secreto_diferente(self, client, mock_mi_menu):
        token = jose_jwt.encode({"id": 1, "exp": datetime.now(timezone.utc) + timedelta(minutes=5)},
                                "otro-secreto-distinto", algorithm="HS256")
        response = client.get("/api/auth/mi-menu", headers={"Authorization": f"Bearer {token}"})
        assert response.status_code == 401

    def test_scheme_no_bearer(self, client, mock_mi_menu):
        response = client.get("/api/auth/mi-menu", headers={"Authorization": f"Basic {_valid_token()}"})
        assert response.status_code == 401
