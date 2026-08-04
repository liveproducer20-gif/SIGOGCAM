from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def list_events(user_id: int | None = None) -> list[dict]:
    params = []
    where = ""
    if user_id:
        where = """
            WHERE EXISTS (
                SELECT 1 FROM dbo.evento_personal ep
                WHERE ep.evento_id = e.id
                  AND ep.personal_id = ?
            )
        """
        params.append(user_id)

    sql = f"""
        SELECT
            e.id,
            e.titulo,
            e.fecha_inicio,
            e.fecha_fin,
            e.lugar,
            e.descripcion,
            e.prioridad,
            CONVERT(NVARCHAR(MAX), e.imagen_url) AS imagen_url,
            e.pdf_nombre,
            CONVERT(NVARCHAR(MAX), e.pdf_url) AS pdf_url,
            e.notificar,
            CASE
                WHEN e.estado = 'CANCELADO' THEN 'CANCELADO'
                WHEN GETDATE() BETWEEN e.fecha_inicio AND e.fecha_fin THEN 'EN_CURSO'
                WHEN GETDATE() > e.fecha_fin THEN 'FINALIZADO'
                ELSE 'PLANIFICADO'
            END AS estado,
            e.creado_por,
            p.nombre_completo AS creado_por_nombre,
            te.id AS tipo_evento_id,
            te.nombre AS tipo_evento,
            (
                SELECT COUNT(1)
                FROM dbo.evento_personal ep
                WHERE ep.evento_id = e.id
            ) AS convocados,
            (
                SELECT COUNT(1)
                FROM dbo.evento_personal ep
                LEFT JOIN dbo.catalogo_detalles ec ON ec.id = ep.estado_convocatoria_id
                WHERE ep.evento_id = e.id
                  AND (
                    ep.fecha_actualizacion IS NOT NULL
                    OR UPPER(ISNULL(ec.codigo, '')) IN ('VISTO', 'CONFIRMADO', 'ASISTIO')
                  )
            ) AS confirmados
        FROM dbo.eventos e
        INNER JOIN dbo.catalogo_detalles te ON te.id = e.tipo_evento_id
        INNER JOIN dbo.vw_personal_detalle p ON p.id = e.creado_por
        {where}
        ORDER BY e.fecha_inicio DESC
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


def get_event(event_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT TOP 1
                e.id,
                e.titulo,
                e.fecha_inicio,
                e.fecha_fin,
                e.lugar,
                e.descripcion,
                e.prioridad,
                CONVERT(NVARCHAR(MAX), e.imagen_url) AS imagen_url,
                e.pdf_nombre,
                CONVERT(NVARCHAR(MAX), e.pdf_url) AS pdf_url,
                e.notificar,
                e.estado,
                e.creado_por,
                te.id AS tipo_evento_id,
                te.nombre AS tipo_evento
            FROM dbo.eventos e
            INNER JOIN dbo.catalogo_detalles te ON te.id = e.tipo_evento_id
            WHERE e.id = ?
            """,
            event_id,
        )
        rows = _rows(cursor)
        if not rows:
            return None
        event = rows[0]
        cursor.execute(
            """
            SELECT ep.personal_id,
                   p.nombre_completo,
                   CAST(NULL AS NVARCHAR(120)) AS cargo,
                   CAST(NULL AS NVARCHAR(120)) AS area,
                   CAST(NULL AS NVARCHAR(120)) AS grupo
            FROM dbo.evento_personal ep
            INNER JOIN dbo.vw_personal_detalle p ON p.id = ep.personal_id
            WHERE ep.evento_id = ?
            ORDER BY p.apellidos, p.nombres
            """,
            event_id,
        )
        event["personal"] = _rows(cursor)
        return event


def create_event(data: dict) -> int:
    with get_connection() as connection:
        status_id = _catalog_detail_id(connection, "ESTADOS_EVENTO", "PLANIFICADO")
        call_status_id = _catalog_detail_id(connection, "ESTADOS_CONVOCATORIA", "CONVOCADO")
        if status_id is None or call_status_id is None:
            raise ValueError("No existen catalogos requeridos para crear el evento")

        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.eventos (
                titulo,
                tipo_evento_id,
                fecha_inicio,
                fecha_fin,
                lugar,
                descripcion,
                estado_evento_id,
                estado,
                creado_por,
                prioridad,
                imagen_url,
                pdf_nombre,
                pdf_url,
                notificar,
                fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, 'PLANIFICADO', ?, ?, ?, ?, ?, GETDATE())
            """,
            data["titulo"],
            data["tipoEventoId"],
            data["fechaInicio"],
            data["fechaFin"],
            data["lugar"],
            data.get("descripcion"),
            status_id,
            data["creadoPor"],
            data.get("prioridad"),
            data.get("imagenUrl"),
            data.get("pdfNombre"),
            data.get("pdfUrl"),
            1 if data.get("notificar", True) else 0,
        )
        event_id = int(cursor.fetchone()[0])
        for person_id in data.get("personalIds") or []:
            cursor.execute(
                """
                INSERT INTO dbo.evento_personal (
                    evento_id,
                    personal_id,
                    estado_convocatoria_id,
                    fecha_convocatoria
                )
                VALUES (?, ?, ?, GETDATE())
                """,
                event_id,
                int(person_id),
                call_status_id,
            )
        return event_id


def update_status(event_id: int, status: str) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.eventos
            SET estado = ?,
                fecha_actualizacion = GETDATE()
            WHERE id = ?
            """,
            status,
            event_id,
        )


def delete_event(event_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM dbo.evento_personal WHERE evento_id = ?", event_id)
        cursor.execute("DELETE FROM dbo.eventos WHERE id = ?", event_id)


def _catalog_detail_id(connection, catalog_code: str, detail_code: str) -> int | None:
    cursor = connection.cursor()
    cursor.execute(
        """
        SELECT TOP 1 d.id
        FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id = d.catalogo_id
        WHERE c.codigo = ?
          AND d.codigo = ?
          AND c.estado = 1
          AND d.estado = 1
        """,
        catalog_code,
        detail_code,
    )
    row = cursor.fetchone()
    return int(row.id) if row else None
