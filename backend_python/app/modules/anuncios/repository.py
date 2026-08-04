from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def list_announcements(user_id: int | None = None) -> list[dict]:
    params = []
    where = ""
    if user_id:
        where = """
            WHERE a.publicado = 1
              AND (a.fecha_expiracion IS NULL OR a.fecha_expiracion >= GETDATE())
              AND (
                NOT EXISTS (
                    SELECT 1 FROM dbo.anuncio_personal audiencia
                    WHERE audiencia.anuncio_id = a.id
                )
                OR EXISTS (
                    SELECT 1 FROM dbo.anuncio_personal asignado
                    WHERE asignado.anuncio_id = a.id
                      AND asignado.personal_id = ?
                )
              )
        """
        params.append(user_id)

    sql = f"""
        SELECT
            a.id,
            a.titulo,
            CONVERT(NVARCHAR(MAX), a.descripcion) AS descripcion,
            a.prioridad,
            a.imagen_nombre,
            CONVERT(NVARCHAR(MAX), a.imagen_url) AS imagen_url,
            a.fecha_publicacion,
            a.fecha_expiracion,
            a.publicado,
            a.notificar,
            a.creado_por,
            STUFF((
                SELECT ',' + CONVERT(NVARCHAR(20), ap.personal_id)
                FROM dbo.anuncio_personal ap
                WHERE ap.anuncio_id = a.id
                FOR XML PATH(''), TYPE
            ).value('.', 'NVARCHAR(4000)'), 1, 1, '') AS personal_ids
        FROM dbo.anuncios a
        {where}
        ORDER BY a.fecha_publicacion DESC, a.id DESC
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


def create_announcement(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.anuncios (
                titulo,
                descripcion,
                prioridad,
                fecha_publicacion,
                fecha_expiracion,
                publicado,
                notificar,
                creado_por,
                imagen_nombre,
                imagen_url
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, GETDATE(), ?, ?, ?, ?, ?, ?)
            """,
            data["titulo"],
            data["descripcion"],
            data.get("prioridad") or "Normal",
            data.get("fechaExpiracion"),
            1 if data.get("publicado", True) else 0,
            1 if data.get("notificar", True) else 0,
            data.get("creadoPor"),
            data.get("imagenNombre"),
            data.get("imagenUrl"),
        )
        announcement_id = int(cursor.fetchone()[0])
        _save_people(connection, announcement_id, data.get("personalIds") or [])
        return announcement_id


def update_published(announcement_id: int, published: bool) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.anuncios
            SET publicado = ?,
                fecha_actualizacion = GETDATE()
            WHERE id = ?
            """,
            1 if published else 0,
            announcement_id,
        )


def delete_announcement(announcement_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM dbo.anuncio_personal WHERE anuncio_id = ?", announcement_id)
        cursor.execute("DELETE FROM dbo.anuncios WHERE id = ?", announcement_id)


def _save_people(connection, announcement_id: int, people_ids: list[int]) -> None:
    cursor = connection.cursor()
    cursor.execute("DELETE FROM dbo.anuncio_personal WHERE anuncio_id = ?", announcement_id)
    for person_id in people_ids:
        cursor.execute(
            "INSERT INTO dbo.anuncio_personal (anuncio_id, personal_id) VALUES (?, ?)",
            announcement_id,
            int(person_id),
        )
