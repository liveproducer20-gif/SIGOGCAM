from app.core.db import get_connection


def summary() -> dict:
    """Return dashboard metrics calculated directly by SQL Server."""
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                (SELECT COUNT(*) FROM dbo.personal WHERE ISNULL(activo, 1) = 1) AS agentes_activos,
                (SELECT COUNT(*) FROM dbo.eventos
                 WHERE ISNULL(estado, 'PLANIFICADO') <> 'CANCELADO' AND fecha_fin >= GETDATE()) AS eventos_programados,
                (SELECT COUNT(*) FROM dbo.cartillas_generadas) AS cartillas_generadas,
                (SELECT COUNT(*) FROM dbo.usuario_insignias) AS insignias_otorgadas,
                (SELECT COUNT(*) FROM dbo.alertas_soporte
                 WHERE ISNULL(activo, 1) = 1 AND ISNULL(estado, 'Nuevo') <> 'Resuelto') AS alertas_activas,
                (SELECT COUNT(*) FROM dbo.lugares_servicio
                 WHERE ISNULL(activo, 1) = 1) AS puntos_georreferenciados,
                (SELECT COUNT(*) FROM dbo.rutas WHERE ISNULL(activo, 1) = 1) AS rutas_operativas
            """
        )
        row = cursor.fetchone()
        return {
            "agentesActivos": int(row.agentes_activos or 0),
            "eventosProgramados": int(row.eventos_programados or 0),
            "cartillasGeneradas": int(row.cartillas_generadas or 0),
            "insigniasOtorgadas": int(row.insignias_otorgadas or 0),
            "alertasActivas": int(row.alertas_activas or 0),
            "puntosGeorreferenciados": int(row.puntos_georreferenciados or 0),
            "rutasOperativas": int(row.rutas_operativas or 0),
        }
