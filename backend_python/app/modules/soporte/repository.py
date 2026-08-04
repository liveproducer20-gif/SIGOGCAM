from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def stats() -> dict:
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
            FROM dbo.alertas_soporte
            WHERE ISNULL(activo, 1) = 1
            """
        )
        row = cursor.fetchone()
        return {
            "total": int(row.total or 0),
            "nuevos": int(row.nuevos or 0),
            "en_proceso": int(row.en_proceso or 0),
            "resueltos": int(row.resueltos or 0),
            "urgentes": int(row.urgentes or 0),
        }


def list_tickets(search: str | None = None, limit: int = 50) -> list[dict]:
    params = []
    where = "WHERE ISNULL(a.activo, 1) = 1"
    if search:
        where += " AND (LOWER(a.titulo) LIKE ? OR LOWER(a.descripcion) LIKE ? OR LOWER(a.modulo) LIKE ?)"
        term = f"%{search.lower()}%"
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
    allowed = {key: value for key, value in data.items() if value is not None}
    if not allowed:
        return

    assignments = ", ".join([f"{key} = ?" for key in allowed.keys()])
    values = list(allowed.values())
    values.append(ticket_id)

    with get_connection() as connection:
        cursor = connection.cursor()
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
