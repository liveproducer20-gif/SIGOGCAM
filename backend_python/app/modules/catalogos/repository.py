from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def list_catalogs() -> list[dict]:
    sql = """
        SELECT id, codigo, nombre
        FROM dbo.catalogos
        WHERE estado = 1
        ORDER BY nombre
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql)
        return _rows(cursor)


def list_details_by_code(codigo: str) -> list[dict]:
    sql = """
        SELECT
            d.id,
            d.codigo,
            d.nombre,
            d.descripcion,
            d.orden
        FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
        WHERE c.codigo = ?
          AND c.estado = 1
          AND d.estado = 1
        ORDER BY d.orden, d.nombre
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, codigo)
        return _rows(cursor)

