from app.core.db import get_connection
from app.core.sanitize import escape_like


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def stats(user_id: int | None = None) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT
                COUNT(1) AS total,
                SUM(CASE WHEN estado = 'Nuevo' THEN 1 ELSE 0 END) AS nuevos,
                SUM(CASE WHEN estado = 'En proceso' THEN 1 ELSE 0 END) AS en_proceso,
                SUM(CASE WHEN estado = 'Resuelto' THEN 1 ELSE 0 END) AS resueltos,
                SUM(CASE WHEN prioridad IN ('Crítica', 'Critica', 'Alta') THEN 1 ELSE 0 END) AS urgentes
                ,SUM(CASE WHEN prioridad IN ('Crítica','Critica') THEN 1 ELSE 0 END) AS criticas
                ,SUM(CASE WHEN prioridad='Alta' THEN 1 ELSE 0 END) AS altas
                ,SUM(CASE WHEN prioridad='Media' THEN 1 ELSE 0 END) AS medias
                ,SUM(CASE WHEN prioridad='Baja' THEN 1 ELSE 0 END) AS bajas
                ,AVG(CASE WHEN fecha_primera_respuesta IS NOT NULL THEN DATEDIFF(MINUTE,fecha_creacion,fecha_primera_respuesta) END) AS promedio_minutos
            FROM dbo.alertas_soporte
            WHERE ISNULL(activo, 1) = 1 AND (? IS NULL OR usuario_id=?)
            """
            , user_id, user_id
        )
        row = cursor.fetchone()
        return {
            "total": int(row.total or 0),
            "nuevos": int(row.nuevos or 0),
            "en_proceso": int(row.en_proceso or 0),
            "resueltos": int(row.resueltos or 0),
            "urgentes": int(row.urgentes or 0),
            "criticas": int(row.criticas or 0),
            "altas": int(row.altas or 0),
            "medias": int(row.medias or 0),
            "bajas": int(row.bajas or 0),
            "promedio_minutos": int(row.promedio_minutos or 0),
        }


def list_tickets(search: str | None = None, limit: int = 50, user_id: int | None = None) -> list[dict]:
    params = []
    where = "WHERE ISNULL(a.activo, 1) = 1"
    if user_id is not None:
        where += " AND a.usuario_id=?"
        params.append(user_id)
    if search:
        where += " AND (LOWER(a.titulo) LIKE ? ESCAPE '\\' OR LOWER(a.descripcion) LIKE ? ESCAPE '\\' OR LOWER(a.modulo) LIKE ? ESCAPE '\\')"
        term = f"%{escape_like(search.lower())}%"
        params.extend([term, term, term])

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            f"""
            SELECT TOP ({int(limit)})
                a.id,
                a.codigo_alerta,
                a.titulo,
                a.descripcion,
                a.usuario_id,
                a.usuario_nombre,
                a.rol,
                a.area,
                a.modulo,
                a.prioridad,
                a.estado,
                a.imagen,
                a.fecha_creacion,
                a.fecha_actualizacion,
                a.asignado_a,
                a.asignado_nombre,
                a.fecha_resolucion
            FROM dbo.alertas_soporte a
            {where}
            ORDER BY a.fecha_creacion DESC
            """,
            *params,
        )
        return _rows(cursor)


def ticket_detail(ticket_id: int, user_id: int | None = None) -> dict | None:
    rows = _query_ticket(ticket_id, user_id)
    if not rows:
        return None
    ticket = rows[0]
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("""SELECT id,usuario_id,usuario_nombre,rol,comentario,es_interno,fecha_creacion
                          FROM dbo.alertas_soporte_comentarios WHERE alerta_id=? ORDER BY fecha_creacion""",ticket_id)
        ticket["comentarios"]=_rows(cursor)
        cursor.execute("""SELECT id,usuario_id,usuario_nombre,accion,valor_anterior,valor_nuevo,fecha_creacion
                          FROM dbo.alertas_soporte_historial WHERE alerta_id=? ORDER BY fecha_creacion DESC""",ticket_id)
        ticket["historial"]=_rows(cursor)
    return ticket


def _query_ticket(ticket_id: int, user_id: int | None) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("""SELECT * FROM dbo.alertas_soporte WHERE id=? AND activo=1 AND (? IS NULL OR usuario_id=?)""",ticket_id,user_id,user_id)
        return _rows(cursor)


def add_comment(ticket_id: int, data: dict) -> int:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("""INSERT INTO dbo.alertas_soporte_comentarios(alerta_id,usuario_id,usuario_nombre,rol,comentario,es_interno,fecha_creacion)
                          OUTPUT INSERTED.id VALUES(?,?,?,?,?,?,SYSDATETIME())""",
                       ticket_id,data["usuario_id"],data["usuario_nombre"],data.get("rol"),data["comentario"],1 if data.get("es_interno") else 0)
        comment_id=int(cursor.fetchone()[0])
        cursor.execute("""INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_id,usuario_nombre,accion,valor_anterior,valor_nuevo,fecha_creacion)
                          VALUES(?,?,?,'Comentario',NULL,?,SYSDATETIME())""",ticket_id,data["usuario_id"],data["usuario_nombre"],data["comentario"])
        return comment_id


def create_ticket(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.alertas_soporte (
                titulo,
                descripcion,
                usuario_id,
                usuario_nombre,
                rol,
                area,
                modulo,
                prioridad,
                estado,
                imagen,
                fecha_creacion,
                fecha_actualizacion,
                activo
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Nuevo', ?, SYSDATETIME(), SYSDATETIME(), 1)
            """,
            data["titulo"],
            data["descripcion"],
            data["usuario_id"],
            data["usuario_nombre"],
            data.get("rol"),
            data.get("area"),
            data["modulo"],
            data.get("prioridad") or "Media",
            data.get("imagen"),
        )
        ticket_id = int(cursor.fetchone()[0])
        cursor.execute(
            """
            UPDATE dbo.alertas_soporte
            SET codigo_alerta = CONCAT('ALT-', YEAR(fecha_creacion), '-', RIGHT('000000' + CONVERT(VARCHAR(20), id), 6))
            WHERE id = ?
            """,
            ticket_id,
        )
        return ticket_id


def update_ticket(ticket_id: int, data: dict) -> None:
    updated_by = data.pop("actualizado_por", None)
    allowed = {key: value for key, value in data.items() if value is not None}
    if not allowed:
        return

    assignments = ", ".join([f"{key} = ?" for key in allowed.keys()])
    values = list(allowed.values())
    values.append(ticket_id)

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT estado,prioridad,asignado_nombre FROM dbo.alertas_soporte WHERE id=?",ticket_id)
        previous=cursor.fetchone()
        cursor.execute(
            f"""
            UPDATE dbo.alertas_soporte
            SET {assignments},
                fecha_actualizacion = SYSDATETIME(),
                fecha_resolucion = CASE WHEN estado = 'Resuelto' THEN COALESCE(fecha_resolucion, SYSDATETIME()) ELSE fecha_resolucion END
            WHERE id = ?
            """,
            *values,
        )
        if previous:
            cursor.execute("""INSERT INTO dbo.alertas_soporte_historial(alerta_id,usuario_nombre,accion,valor_anterior,valor_nuevo,fecha_creacion)
                              VALUES(?,?,'Actualización',?,?,SYSDATETIME())""",ticket_id,updated_by or "Sistema",
                           f"{previous.estado}|{previous.prioridad}|{previous.asignado_nombre or ''}",
                           f"{data.get('estado') or previous.estado}|{data.get('prioridad') or previous.prioridad}|{data.get('asignado_nombre') or previous.asignado_nombre or ''}")
