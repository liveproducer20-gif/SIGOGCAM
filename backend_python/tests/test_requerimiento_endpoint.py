"""Regresión: PUT /api/distribucion-tablero/sectores/requerimiento.

El stepper de requeridos del tablero usa este endpoint. Antes devolvía 500
porque el repositorio recibía objetos Pydantic en lugar de dicts
(TypeError: 'SectorRequirementInput' object is not subscriptable).
"""

from app.modules.distribucion_tablero import repository

BODY = {
    "ruta_id": 1016,
    "sectores": [{"sector_id": 2031, "cantidad_agentes_requeridos": 2}],
}


def test_requerimiento_200_con_permiso(client, override_user, monkeypatch):
    override_user({"id": 1, "rolCodigo": "ADMINISTRADOR", "permisos": ["tablero_distribucion.configurar"]})
    recorded = {}

    def fake_update(route_id, sectores, user_id):
        recorded["route_id"] = route_id
        recorded["sectores"] = sectores
        recorded["user_id"] = user_id
        return {"sectores_actualizados": len(sectores)}

    monkeypatch.setattr(repository, "update_sector_requirements", fake_update)
    response = client.put("/api/distribucion-tablero/sectores/requerimiento", json=BODY)
    assert response.status_code == 200
    assert response.json()["datos"] == {"sectores_actualizados": 1}

    # El repositorio debe recibir dicts planos (no modelos Pydantic).
    assert recorded["route_id"] == 1016
    assert recorded["user_id"] == 1
    assert len(recorded["sectores"]) == 1
    sector = recorded["sectores"][0]
    assert isinstance(sector, dict), f"se esperaba un dict, llegó {type(sector).__name__}"
    assert sector == {"sector_id": 2031, "cantidad_agentes_requeridos": 2}


def test_requerimiento_403_sin_permiso(client, override_user):
    override_user({"id": 1, "rolCodigo": "AGENTE", "permisos": ["tablero_distribucion.ver"]})
    response = client.put("/api/distribucion-tablero/sectores/requerimiento", json=BODY)
    assert response.status_code == 403


def test_requerimiento_422_con_datos_invalidos(client, override_user):
    override_user({"id": 1, "rolCodigo": "ADMINISTRADOR", "permisos": ["tablero_distribucion.configurar"]})
    response = client.put(
        "/api/distribucion-tablero/sectores/requerimiento",
        json={"ruta_id": 1016, "sectores": [{"sector_id": 2031, "cantidad_agentes_requeridos": -1}]},
    )
    assert response.status_code == 422
