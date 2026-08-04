from app.core.db import get_connection


def get_user_by_email(correo: str) -> dict | None:
    sql = """
        SELECT TOP 1
            vd.id,
            vd.cedula,
            vd.correo_institucional AS correo,
            vd.nombres,
            vd.apellidos,
            vd.nombre_completo,
            vd.estado_personal,
            p.password_hash,
            r.id AS rol_id,
            r.nombre AS rol_nombre,
            r.codigo AS rol_codigo
        FROM dbo.vw_personal_detalle vd
        LEFT JOIN dbo.personal p ON p.id = vd.id
        LEFT JOIN dbo.roles r ON r.id = p.rol_id
        WHERE LOWER(vd.correo_institucional) = ?
          AND (vd.activo = 1 OR vd.activo = '1')
        ORDER BY vd.id
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, correo)
        row = cursor.fetchone()
        if row is None:
            return None
        columns = [column[0] for column in cursor.description]
        return dict(zip(columns, row))


def get_permissions_by_role(rol_id: int | None) -> list[str]:
    if rol_id is None:
        return []

    sql = """
        SELECT DISTINCT p.codigo
        FROM dbo.roles r
        INNER JOIN dbo.rol_permiso rp ON rp.rol_id = r.id
        INNER JOIN dbo.permisos p ON p.id = rp.permiso_id
        WHERE r.id = ?
          AND r.activo = 1
          AND p.activo = 1
        ORDER BY p.codigo
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, rol_id)
        return [row.codigo for row in cursor.fetchall()]
