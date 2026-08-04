from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def list_badges() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT id, codigo, titulo, descripcion, meta_cartillas, categoria, icono, activo
            FROM dbo.insignias
            WHERE ISNULL(activo, 1) = 1
            ORDER BY meta_cartillas, id
            """
        )
        return _rows(cursor)


def user_progress(user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT TOP 1
                vd.id,
                vd.nombre_completo,
                ISNULL(p.total_cartillas_generadas, 0) AS total_cartillas_generadas
            FROM dbo.vw_personal_detalle vd
            LEFT JOIN dbo.personal p ON p.id = vd.id
            WHERE vd.id = ?
            """,
            user_id,
        )
        user = cursor.fetchone()
        total = int(getattr(user, "total_cartillas_generadas", 0) or 0) if user else 0

        cursor.execute(
            """
            SELECT i.id, i.codigo, i.titulo, i.descripcion, i.meta_cartillas, i.categoria, i.icono,
                   ui.fecha_desbloqueo
            FROM dbo.insignias i
            LEFT JOIN dbo.usuario_insignias ui
              ON ui.insignia_id = i.id
             AND ui.usuario_id = ?
            WHERE ISNULL(i.activo, 1) = 1
            ORDER BY i.meta_cartillas, i.id
            """,
            user_id,
        )
        badges = _rows(cursor)
        for badge in badges:
            goal = int(badge["meta_cartillas"] or 0)
            badge["desbloqueada"] = badge.get("fecha_desbloqueo") is not None or total >= goal
            badge["progreso"] = min(total, goal)
            badge["porcentaje"] = 100 if goal <= 0 else min(100, round((total / goal) * 100, 2))

        next_badge = next((badge for badge in badges if not badge["desbloqueada"]), None)
        return {
            "total_cartillas_generadas": total,
            "desbloqueadas": len([badge for badge in badges if badge["desbloqueada"]]),
            "pendientes": len([badge for badge in badges if not badge["desbloqueada"]]),
            "siguiente": next_badge,
            "insignias": badges,
        }


def ranking(limit: int = 10) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            f"""
            SELECT TOP ({int(limit)})
                p.id,
                p.nombre_completo,
                p.rol,
                CAST(NULL AS NVARCHAR(120)) AS grupo,
                ISNULL(per.total_cartillas_generadas, 0) AS total_cartillas_generadas,
                (
                    SELECT TOP 1 i.titulo
                    FROM dbo.usuario_insignias ui
                    INNER JOIN dbo.insignias i ON i.id = ui.insignia_id
                    WHERE ui.usuario_id = p.id
                    ORDER BY i.meta_cartillas DESC
                ) AS insignia_mayor
            FROM dbo.vw_personal_detalle p
            LEFT JOIN dbo.personal per ON per.id = p.id
            WHERE ISNULL(p.activo, 1) = 1
            ORDER BY ISNULL(per.total_cartillas_generadas, 0) DESC, p.nombre_completo
            """
        )
        rows = _rows(cursor)
        for index, row in enumerate(rows, start=1):
            row["posicion"] = index
        return rows
