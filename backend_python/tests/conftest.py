"""Fixtures compartidos de la suite de pruebas del backend."""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.middleware.auth import current_user


@pytest.fixture()
def client():
    with TestClient(app) as test_client:
        yield test_client


@pytest.fixture()
def override_user():
    """Sobrescribe la dependencia ``current_user`` con un usuario simulado.

    Uso: ``override_user({"id": 1, "permisos": ["configuracion.ver"], ...})``.
    La sobrescritura se limpia automáticamente al terminar el test.
    """
    def _set(user: dict) -> None:
        app.dependency_overrides[current_user] = lambda: user

    yield _set
    app.dependency_overrides.pop(current_user, None)
