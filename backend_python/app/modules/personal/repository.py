from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def list_people(search: str | None = None, limit: int = 200) -> list[dict]:
    params = []
    where = "WHERE 1 = 1"
    if search:
        where += """
          AND (
            LOWER(vd.nombre_completo) LIKE ?
            OR LOWER(vd.cedula) LIKE ?
            OR LOWER(vd.correo_institucional) LIKE ?
          )
        """
        term = f"%{search.lower()}%"
        params.extend([term, term, term])

    sql = f"""
        SELECT TOP ({int(limit)})
            vd.id,
            vd.cedula,
            vd.nombres,
            vd.apellidos,
            vd.nombre_completo,
            vd.correo_institucional,
            CAST(NULL AS NVARCHAR(120)) AS cargo,
            CAST(NULL AS NVARCHAR(120)) AS area,
            CAST(NULL AS NVARCHAR(120)) AS grupo,
            CAST(NULL AS NVARCHAR(120)) AS jornada,
            vd.rol,
            vd.estado_personal,
            vd.activo
        FROM dbo.vw_personal_detalle vd
        {where}
        ORDER BY vd.apellidos, vd.nombres
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


def my_profile(user_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT TOP 1
                vd.id,
                vd.cedula,
                vd.nombres,
                vd.apellidos,
                vd.nombre_completo,
                vd.correo_institucional,
                CAST(NULL AS NVARCHAR(120)) AS cargo,
                CAST(NULL AS NVARCHAR(120)) AS area,
                CAST(NULL AS NVARCHAR(120)) AS grupo,
                CAST(NULL AS NVARCHAR(120)) AS jornada,
                vd.rol,
                vd.estado_personal,
                vd.activo
            FROM dbo.vw_personal_detalle vd
            WHERE vd.id = ?
            """,
            user_id,
        )
        result = _rows(cursor)
        return result[0] if result else None
