import json

from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _columns(connection, table_name: str) -> set[str]:
    cursor = connection.cursor()
    cursor.execute(
        """
        SELECT COLUMN_NAME
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ?
        """,
        table_name,
    )
    return {row.COLUMN_NAME for row in cursor.fetchall()}


def _table_exists(connection, table_name: str) -> bool:
    cursor = connection.cursor()
    cursor.execute(
        """
        SELECT 1
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = ?
        """,
        table_name,
    )
    return cursor.fetchone() is not None


def register_card(data: dict) -> dict:
    with get_connection() as connection:
        columns = _columns(connection, "cartillas_generadas")
        names = ["usuario_id", "causa", "contenido", "fecha_creacion"]
        values = [data["usuario_id"], data.get("causa"), data["contenido"]]
        marks = ["?", "?", "?", "GETDATE()"]

        if "tipo" in columns:
            names[3:3] = ["tipo", "subtipo", "datos_json"]
            values.extend(
                [
                    data.get("tipo"),
                    data.get("subtipo"),
                    json.dumps(data.get("datos"), ensure_ascii=False)
                    if data.get("datos") is not None
                    else None,
                ]
            )
            marks[3:3] = ["?", "?", "?"]

        cursor = connection.cursor()
        cursor.execute(
            f"""
            INSERT INTO dbo.cartillas_generadas ({", ".join(names)})
            OUTPUT INSERTED.id
            VALUES ({", ".join(marks)})
            """,
            *values,
        )
        cartilla_id = cursor.fetchone()[0]

        cursor.execute(
            """
            UPDATE dbo.personal
            SET total_cartillas_generadas = ISNULL(total_cartillas_generadas, 0) + 1
            OUTPUT INSERTED.total_cartillas_generadas
            WHERE id = ?
            """,
            data["usuario_id"],
        )
        updated = cursor.fetchone()
        if updated is None:
            raise ValueError("Usuario no encontrado")

        total = int(updated[0] or 0)
        insignia = _unlock_badge(connection, data["usuario_id"], total)

        return {
            "cartillaId": cartilla_id,
            "total_cartillas_generadas": total,
            "insignia_desbloqueada": insignia,
        }


def _unlock_badge(connection, user_id: int, total: int) -> dict | None:
    cursor = connection.cursor()
    cursor.execute(
        """
        SELECT TOP 1 id, titulo, descripcion, icono
        FROM dbo.insignias
        WHERE activo = 1
          AND meta_cartillas = ?
        ORDER BY id
        """,
        total,
    )
    badge = cursor.fetchone()
    if badge is None:
        return None

    cursor.execute(
        """
        SELECT TOP 1 id
        FROM dbo.usuario_insignias
        WHERE usuario_id = ?
          AND insignia_id = ?
        """,
        user_id,
        badge.id,
    )
    if cursor.fetchone() is not None:
        return None

    cursor.execute(
        """
        INSERT INTO dbo.usuario_insignias (
            usuario_id,
            insignia_id,
            total_cartillas_al_desbloquear,
            fecha_desbloqueo
        )
        VALUES (?, ?, ?, GETDATE())
        """,
        user_id,
        badge.id,
        total,
    )

    return {
        "titulo": badge.titulo,
        "mensaje": badge.descripcion,
        "icono": badge.icono,
    }


def operational_catalogs() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT p.id, p.nombres, p.apellidos,
                   LTRIM(RTRIM(CONCAT(ISNULL(g.nombre + ' ', ''), p.nombres, ' ', p.apellidos))) AS nombre_completo
            FROM dbo.personal p
            LEFT JOIN dbo.grados g ON g.id = p.grado_id
            WHERE ISNULL(p.activo, 1) = 1
            ORDER BY p.apellidos, p.nombres
            """
        )
        personal = _rows(cursor)

        cursor.execute(
            """
            SELECT id, numero_movil, placa, kilometraje_actual
            FROM dbo.moviles
            WHERE ISNULL(activo, 1) = 1
            ORDER BY numero_movil
            """
        )
        moviles = _rows(cursor)

        return {"personal": personal, "moviles": moviles}


def active_eas() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        if _table_exists(connection, "eas"):
            cursor.execute(
                """
                SELECT id, codigo, nombre, direccion, activo
                FROM dbo.eas
                WHERE ISNULL(activo, 1) = 1
                ORDER BY codigo, nombre
                """
            )
        else:
            cursor.execute(
                """
                SELECT id, codigo, nombre, direccion, activo
                FROM dbo.eas_estaciones
                WHERE ISNULL(activo, 1) = 1
                ORDER BY codigo, nombre
                """
            )
        return _rows(cursor)


def get_temp_cp(user_id: int) -> dict:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("SELECT TOP 1 nombre_cp FROM dbo.cartilla_temp_cp WHERE usuario_id=? ORDER BY id DESC",user_id)
        row=cursor.fetchone(); return {"nombreCp":row.nombre_cp if row else ""}


def save_temp_cp(user_id: int, name: str) -> None:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("DELETE FROM dbo.cartilla_temp_cp WHERE usuario_id=?",user_id)
        cursor.execute("INSERT INTO dbo.cartilla_temp_cp(usuario_id,nombre_cp,fecha_creacion) VALUES(?,?,SYSDATETIME())",user_id,name)


def police_servers(eas_id: int | None = None) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("SELECT id,eas_id,nombre,activo FROM dbo.servidores_policiales WHERE activo=1 AND (? IS NULL OR eas_id=?) ORDER BY nombre",eas_id,eas_id)
        return _rows(cursor)


def create_police_server(eas_id: int, name: str) -> int:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("INSERT INTO dbo.servidores_policiales(eas_id,nombre,activo,fecha_creacion) OUTPUT INSERTED.id VALUES(?,?,1,SYSDATETIME())",eas_id,name)
        return int(cursor.fetchone()[0])


def eas_addresses(eas_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("SELECT id,eas_id,direccion,activo FROM dbo.eas_direcciones WHERE eas_id=? AND ISNULL(activo,1)=1 ORDER BY direccion",eas_id)
        return _rows(cursor)


def create_eas_address(eas_id: int, address: str) -> int:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("INSERT INTO dbo.eas_direcciones(eas_id,direccion,activo,fecha_creacion) OUTPUT INSERTED.id VALUES(?,?,1,SYSDATETIME())",eas_id,address)
        return int(cursor.fetchone()[0])


def eas_mobile_assignments() -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("""SELECT a.id,a.eas_id,e.codigo AS eas_codigo,e.nombre AS eas_nombre,a.movil_id,m.numero_movil,m.placa
                          FROM dbo.movil_eas_asignaciones a INNER JOIN dbo.eas_estaciones e ON e.id=a.eas_id
                          INNER JOIN dbo.moviles m ON m.id=a.movil_id WHERE a.activo=1 ORDER BY e.codigo,m.numero_movil""")
        return _rows(cursor)


def control_chief() -> dict:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("SELECT TOP 1 valor FROM dbo.configuracion_institucional WHERE clave IN ('JEFE_CONTROL_MUNICIPAL','jefe_control_municipal') ORDER BY id DESC")
        row=cursor.fetchone(); return {"nombre":row.valor if row else "Jefe de Control Municipal"}
