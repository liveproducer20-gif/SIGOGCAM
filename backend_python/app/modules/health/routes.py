from fastapi import APIRouter

from app.core.db import get_connection
from app.core.responses import ok


router = APIRouter(tags=["salud"])


@router.get("")
def api_root():
    return ok(
        {
            "servicio": "SIGO-GCAM API",
            "version": "2.0.0",
            "rutas": [
                "/api/auth",
                "/api/catalogos",
                "/api/admin",
                "/api/personal",
                "/api/eventos",
                "/api/anuncios",
                "/api/cartillas",
                "/api/insignias",
                "/api/usuarios",
                "/api/soporte",
                "/api/configuracion",
                "/api/probar-db",
            ],
        },
        "API SIGO-GCAM funcionando correctamente",
    )


@router.get("/probar-db")
def probar_db():
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT DB_NAME() AS baseDatos")
        row = cursor.fetchone()
        return ok({"baseDatos": row.baseDatos}, "Conexion correcta con SQL Server")

