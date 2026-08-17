"""Control de acceso del módulo de configuración.

Cubre el hallazgo C1 corregido: las mutaciones exigen ``configuracion.editar``
o ``configuracion.roles.gestionar`` además del ``configuracion.ver`` del router.

Se prueba un caso por endpoint de los permisos finos:
- sin permiso de escritura -> 403 (aunque tenga ``configuracion.ver``)
- con permiso de escritura -> 200/201 (repositorio mockeado, sin BD)
- lecturas con ``configuracion.ver`` -> 200; sin el permiso -> 403
"""

import pytest

from app.modules.configuracion import routes as conf_routes

VER = "configuracion.ver"
ESCRIBIR = ["configuracion.editar", "configuracion.roles.gestionar"]

# (método, path, body, función de repositorio a mockear, status esperado)
MUTACIONES = [
    ("PUT", "/api/configuracion/roles/1/permisos", {"permisoIds": []}, "update_role_permissions", 200),
    ("PUT", "/api/configuracion/roles/1/menu", {"items": []}, "save_menu_configuration", 200),
    ("POST", "/api/configuracion/roles/1/alcance", {}, "save_data_scope", 201),
    ("POST", "/api/configuracion/roles/1/condiciones", {}, "save_role_condition", 201),
    ("DELETE", "/api/configuracion/roles/1/condiciones/1", None, "delete_role_condition", 200),
    ("PUT", "/api/configuracion/roles/1/campos", {"items": []}, "save_role_fields", 200),
    ("POST", "/api/configuracion/roles/1/versiones", {"comentario": "test"}, "create_role_version", 201),
    ("POST", "/api/configuracion/cambios", {"titulo": "test"}, "create_cambio", 201),
    ("DELETE", "/api/configuracion/cambios/1", None, "delete_cambio", 200),
]

# (método, path, función(es) de repositorio a mockear)
LECTURAS = [
    ("GET", "/api/configuracion/roles", ("roles_configuration",)),
    ("GET", "/api/configuracion/version", ("current_version",)),
    ("GET", "/api/configuracion/permisos", ("all_permissions",)),
    ("GET", "/api/configuracion/modulos", ("all_modules",)),
    ("GET", "/api/configuracion/mi-estructura", ("my_structure", "build_tree")),
    ("GET", "/api/configuracion/roles/1/menu", ("menu_configuration",)),
    ("GET", "/api/configuracion/roles/1/alcance", ("data_scopes",)),
    ("GET", "/api/configuracion/roles/1/condiciones", ("role_conditions",)),
    ("GET", "/api/configuracion/roles/1/campos", ("role_fields",)),
    ("GET", "/api/configuracion/roles/1/versiones", ("role_versions",)),
    ("GET", "/api/configuracion/auditoria", ("configuration_audit",)),
    ("GET", "/api/configuracion/campos-sistema", ("system_fields",)),
    ("GET", "/api/configuracion/cambios", ("list_cambios",)),
]


def _usuario(permisos):
    return {"id": 1, "nombre": "Test", "rolCodigo": "CONSULTA", "permisos": permisos}


class TestMutaciones:
    """Un test por endpoint: la mutación exige permiso de escritura."""

    @pytest.mark.parametrize("method,path,body,repo,status_ok", MUTACIONES, ids=[m[1] for m in MUTACIONES])
    def test_mutacion_sin_permiso_escritura_devuelve_403(self, client, override_user, method, path, body, repo, status_ok):
        # Solo lectura: antes del fix C1 esto pasaba; ahora debe ser 403.
        override_user(_usuario([VER]))
        response = client.request(method, path, json=body)
        assert response.status_code == 403

    @pytest.mark.parametrize("method,path,body,repo,status_ok", MUTACIONES, ids=[m[1] for m in MUTACIONES])
    def test_mutacion_con_editar_devuelve_status_ok(self, client, override_user, monkeypatch, method, path, body, repo, status_ok):
        monkeypatch.setattr(conf_routes, repo, lambda *a, **k: 1)
        override_user(_usuario([VER, "configuracion.editar"]))
        response = client.request(method, path, json=body)
        assert response.status_code == status_ok

    @pytest.mark.parametrize("method,path,body,repo,status_ok", MUTACIONES, ids=[m[1] for m in MUTACIONES])
    def test_mutacion_con_roles_gestionar_devuelve_status_ok(self, client, override_user, monkeypatch, method, path, body, repo, status_ok):
        monkeypatch.setattr(conf_routes, repo, lambda *a, **k: 1)
        override_user(_usuario([VER, "configuracion.roles.gestionar"]))
        response = client.request(method, path, json=body)
        assert response.status_code == status_ok

    def test_mutacion_sin_permiso_alguno_devuelve_403(self, client, override_user):
        override_user(_usuario([]))
        response = client.put("/api/configuracion/roles/1/permisos", json={"permisoIds": []})
        assert response.status_code == 403


class TestLecturas:
    """Las lecturas del módulo se mantienen accesibles con solo ``configuracion.ver``."""

    @pytest.mark.parametrize("method,path,repos", LECTURAS, ids=[r[1] for r in LECTURAS])
    def test_lectura_sin_ver_devuelve_403(self, client, override_user, method, path, repos):
        override_user(_usuario([]))
        response = client.request(method, path)
        assert response.status_code == 403

    @pytest.mark.parametrize("method,path,repos", LECTURAS, ids=[r[1] for r in LECTURAS])
    def test_lectura_con_ver_devuelve_200(self, client, override_user, monkeypatch, method, path, repos):
        for repo in repos:
            monkeypatch.setattr(conf_routes, repo, lambda *a, _r=repo, **k: [] if _r != "build_tree" else {"items": []})
        override_user(_usuario([VER]))
        response = client.request(method, path)
        assert response.status_code == 200


class TestBypassAdministrador:
    """Documenta el comportamiento actual (hallazgo A7): rol ADMINISTRADOR pasa sin permisos."""

    def test_administrador_sin_permisos_puede_mutar(self, client, override_user, monkeypatch):
        monkeypatch.setattr(conf_routes, "update_role_permissions", lambda *a, **k: None)
        override_user({"id": 1, "rolCodigo": "ADMINISTRADOR", "permisos": []})
        response = client.put("/api/configuracion/roles/1/permisos", json={"permisoIds": []})
        assert response.status_code == 200
