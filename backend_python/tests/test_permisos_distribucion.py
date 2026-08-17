"""Control de acceso del módulo de distribución geográfica.

Cubre el hallazgo C2 corregido (consolidación v1+v2): cada mutación exige su
permiso fino y las lecturas solo ``distribucion.ver``.

Se prueba un caso por endpoint:
- sin el permiso fino -> 403
- con el permiso fino -> 200/201 (repositorio mockeado, sin BD)
- lecturas sin ``distribucion.ver`` -> 403
"""

import pytest

from app.modules.distribucion_geografica import repository

TRACE = {"geojson": {"type": "FeatureCollection", "features": []}}
ROUTE_TRACE = {"distrito_id": 1, "geojson": {"type": "FeatureCollection", "features": []}}
LOC = {"distrito_id": 1, "ruta_id": 1, "latitud": "-2.1", "longitud": "-79.9"}
POINT = {
    "distrito_id": 1, "ruta_id": 1, "nombre": "Punto Norte", "ubicacion_especifica": "Centro",
    "direccion": "Av. Principal", "latitud": "-2.1", "longitud": "-79.9",
    "tipo_servicio_id": 1, "turno_id": 1, "cantidad_requerida": 1,
}
ASSIGN = {"personal_id": 1, "fecha_inicio": "2026-08-17", "turno_id": 1,
          "hora_inicio": "08:00:00", "hora_fin": "16:00:00"}

# (método, path, body, permisos que SÍ habilitan la mutación, repo a mockear, status con permiso)
MUTACIONES = [
    ("POST", "/api/distritos/1/rutas", {"distrito_id": 1, "nombre": "Ruta Norte", "turno_id": 1},
     ["distribucion.catalogos"], "create_route", 201),
    ("POST", "/api/rutas/1/sectores", {"distrito_id": 1, "ruta_id": 1, "nombre": "Sector A"},
     ["distribucion.catalogos"], "create_sector", 201),
    ("PUT", "/api/distribucion-geografica/distritos/1/trazado", TRACE,
     ["rutas_geograficas.gestionar"], "upsert_hierarchical_trace", 200),
    ("PUT", "/api/distribucion-geografica/circuitos/1/trazado", TRACE,
     ["rutas_geograficas.gestionar"], "upsert_hierarchical_trace", 200),
    ("PUT", "/api/distribucion-geografica/rutas/1/trazado", ROUTE_TRACE,
     ["rutas_geograficas.gestionar"], "upsert_route_trace", 200),
    ("PUT", "/api/distribucion-geografica/lugares/1/ubicacion", LOC,
     ["distribucion.editar"], "update_place_location", 200),
    ("DELETE", "/api/distribucion-geografica/lugares/1/ubicacion", None,
     ["distribucion.editar"], "remove_place_location", 200),
    ("POST", "/api/distribucion-geografica/puntos", POINT,
     ["distribucion.crear"], "create_point", 201),
    ("PUT", "/api/distribucion-geografica/puntos/1", POINT,
     ["distribucion.editar"], "update_point", 200),
    ("DELETE", "/api/distribucion-geografica/puntos/1", None,
     ["distribucion.desactivar"], "deactivate_point", 200),
    ("POST", "/api/distribucion-geografica/puntos/1/asignaciones", ASSIGN,
     ["distribucion.asignar"], "add_assignment", 201),
    ("PUT", "/api/distribucion-geografica/asignaciones/1", ASSIGN,
     ["distribucion.asignar"], "update_assignment", 200),
    ("DELETE", "/api/distribucion-geografica/asignaciones/1", None,
     ["distribucion.asignar"], "remove_assignment", 200),
    # Consolidado v2
    ("POST", "/api/rutas-geograficas", {"nombre": "RutaGeo", "distrito_id": 1},
     ["rutas_geograficas.gestionar", "distribucion.catalogos"], "create_ruta_geografica", 201),
    ("PUT", "/api/rutas-geograficas/1", {"nombre": "RutaGeo"},
     ["rutas_geograficas.gestionar", "distribucion.catalogos"], "update_ruta_geografica", 200),
    ("DELETE", "/api/rutas-geograficas/1", None,
     ["rutas_geograficas.gestionar", "distribucion.catalogos"], "delete_ruta_geografica", 200),
    ("POST", "/api/lugares-servicio", {"nombre": "Lugar 1", "ruta_id": 1, "distrito_id": 1},
     ["distribucion.catalogos", "distribucion.crear"], "create_lugar_servicio", 201),
    ("PUT", "/api/lugares-servicio/1", {"nombre": "Lugar 1"},
     ["distribucion.editar", "distribucion.catalogos"], "update_lugar_servicio", 200),
    ("DELETE", "/api/lugares-servicio/1", None,
     ["distribucion.desactivar"], "delete_lugar_servicio", 200),
    ("POST", "/api/lugares-servicio/1/asignaciones", {"personal_id": 1, "tipo_asignacion": "FIJA"},
     ["distribucion.asignar"], "create_asignacion_punto", 201),
    ("DELETE", "/api/asignaciones-punto/1", None,
     ["distribucion.asignar"], "delete_asignacion_punto", 200),
]

# (método, path)
LECTURAS = [
    ("GET", "/api/distribucion-geografica/catalogos"),
    ("GET", "/api/distritos"),
    ("GET", "/api/distritos/1/rutas"),
    ("GET", "/api/distritos/1/circuitos"),
    ("GET", "/api/circuitos/1/rutas"),
    ("GET", "/api/rutas/1/sectores"),
    ("GET", "/api/rutas/1/lugares-servicio"),
    ("GET", "/api/distribucion-geografica/rutas/1/mapa?distrito_id=1"),
    ("GET", "/api/distribucion-geografica/distrito/1/mapa-todas"),
    ("GET", "/api/distribucion-geografica/mapa"),
    ("GET", "/api/distribucion-geografica/personal-mapa?distrito_id=1"),
    ("GET", "/api/distribucion-geografica/puntos"),
    ("GET", "/api/distribucion-geografica/puntos/1"),
    ("GET", "/api/distribucion-geografica/resumen"),
    ("GET", "/api/personal/1/asignaciones"),
    ("GET", "/api/rutas-geograficas"),
    ("GET", "/api/rutas-geograficas/1"),
    ("GET", "/api/rutas/1/geografia"),
    ("GET", "/api/lugares-servicio"),
    ("GET", "/api/lugares-servicio/1"),
    ("GET", "/api/lugares-servicio/1/asignaciones"),
]


def _usuario(permisos):
    return {"id": 1, "nombre": "Test", "rolCodigo": "CONSULTA", "permisos": permisos}


def _mock_repo(monkeypatch, repo_name, value):
    monkeypatch.setattr(repository, repo_name, lambda *a, **k: value)


class TestMutaciones:
    """Un test por endpoint: la mutación exige su permiso fino."""

    @pytest.mark.parametrize(
        "method,path,body,permisos,repo,status_ok",
        MUTACIONES,
        ids=[f"{m[0]} {m[1]}" for m in MUTACIONES],
    )
    def test_mutacion_sin_permiso_fino_devuelve_403(self, client, override_user, method, path, body, permisos, repo, status_ok):
        # Usuario con solo lectura: antes del fix C2 esto pasaba; ahora debe ser 403.
        override_user(_usuario(["distribucion.ver"]))
        response = client.request(method, path, json=body)
        assert response.status_code == 403

    @pytest.mark.parametrize(
        "method,path,body,permisos,repo,status_ok",
        MUTACIONES,
        ids=[f"{m[0]} {m[1]}" for m in MUTACIONES],
    )
    def test_mutacion_con_permiso_fino_devuelve_status_ok(self, client, override_user, monkeypatch, method, path, body, permisos, repo, status_ok):
        _mock_repo(monkeypatch, repo, {"id": 1, "creado": True} if repo == "upsert_route_trace" else 1)
        # Concede SOLO el primer permiso habilitante (cubre require_any_permission con OR).
        override_user(_usuario(["distribucion.ver", permisos[0]]))
        response = client.request(method, path, json=body)
        assert response.status_code == status_ok

    @pytest.mark.parametrize(
        "method,path,body,permisos,repo,status_ok",
        MUTACIONES,
        ids=[f"{m[0]} {m[1]}" for m in MUTACIONES],
    )
    def test_mutacion_sin_permiso_alguno_devuelve_403(self, client, override_user, method, path, body, permisos, repo, status_ok):
        override_user(_usuario([]))
        response = client.request(method, path, json=body)
        assert response.status_code == 403


class TestLecturas:
    """Las lecturas del módulo se mantienen accesibles con solo ``distribucion.ver``."""

    @pytest.mark.parametrize("method,path", LECTURAS, ids=[p for _, p in LECTURAS])
    def test_lectura_sin_ver_devuelve_403(self, client, override_user, method, path):
        override_user(_usuario([]))
        response = client.request(method, path)
        assert response.status_code == 403

    @pytest.mark.parametrize("method,path", LECTURAS, ids=[p for _, p in LECTURAS])
    def test_lectura_con_ver_devuelve_200(self, client, override_user, monkeypatch, method, path):
        # Mockea los repos de lectura con un valor genérico (sin BD).
        monkeypatch.setattr(repository, "catalogs", lambda *a, **k: {"distritos": [], "rutas": []})
        monkeypatch.setattr(repository, "routes_by_district", lambda *a, **k: [])
        monkeypatch.setattr(repository, "circuits_by_district", lambda *a, **k: [])
        monkeypatch.setattr(repository, "routes_by_circuit", lambda *a, **k: [])
        monkeypatch.setattr(repository, "sectors_by_route", lambda *a, **k: [])
        monkeypatch.setattr(repository, "service_places_by_route", lambda *a, **k: [])
        monkeypatch.setattr(repository, "route_map", lambda *a, **k: {})
        monkeypatch.setattr(repository, "all_routes_map", lambda *a, **k: {})
        monkeypatch.setattr(repository, "global_map", lambda *a, **k: {})
        monkeypatch.setattr(repository, "personnel_map", lambda *a, **k: {})
        monkeypatch.setattr(repository, "list_points", lambda *a, **k: [])
        monkeypatch.setattr(repository, "get_point", lambda *a, **k: {})
        monkeypatch.setattr(repository, "summary", lambda *a, **k: {})
        monkeypatch.setattr(repository, "person_assignments", lambda *a, **k: [])
        monkeypatch.setattr(repository, "list_rutas_geograficas", lambda *a, **k: [])
        monkeypatch.setattr(repository, "get_ruta_geografica", lambda *a, **k: {"id": 1})
        monkeypatch.setattr(repository, "get_ruta_geografica_by_ruta", lambda *a, **k: {"id": 1})
        monkeypatch.setattr(repository, "list_lugares_servicio", lambda *a, **k: [])
        monkeypatch.setattr(repository, "get_lugar_servicio", lambda *a, **k: {"id": 1})
        monkeypatch.setattr(repository, "get_asignaciones_punto", lambda *a, **k: [])
        override_user(_usuario(["distribucion.ver"]))
        response = client.request(method, path)
        assert response.status_code == 200
