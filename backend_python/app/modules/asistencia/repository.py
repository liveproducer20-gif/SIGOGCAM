from datetime import date, datetime

from fastapi import HTTPException

from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _row(cursor) -> dict | None:
    rows = _rows(cursor)
    return rows[0] if rows else None


def _audit(cursor, user_id, action, record_id, data=None):
    import json
    cursor.execute(
        """INSERT INTO dbo.auditoria (usuario_id, accion, modulo, tabla_afectada, registro_id, metodo, endpoint, datos_nuevos, fecha_creacion)
           VALUES (?, ?, 'asistencia', 'asistencia_personal', ?, 'SYSTEM', 'panel-asistencia', ?, SYSDATETIME())""",
        user_id, action, str(record_id), json.dumps(data or {}, default=str)
    )


def get_catalogs() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'DISTRITOS' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.nombre
        """)
        districts = _rows(cursor)
        cursor.execute("SELECT id, nombre FROM dbo.turnos WHERE activo = 1 ORDER BY hora_inicio")
        shifts = _rows(cursor)
        return {"distritos": districts, "turnos": shifts}


def get_assigned_personnel(distrito_id: int | None, ruta_id: int | None, turno_id: int, fecha: date) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT nombre FROM dbo.turnos WHERE id = ? AND activo = 1", turno_id)
        shift = _row(cursor)
        if not shift:
            raise HTTPException(404, "Turno no encontrado")
        turno_nombre = shift["nombre"]

        existing = _get_existing_attendance(cursor, fecha, turno_nombre, distrito_id, ruta_id)
        existing_map = {int(a["personal_id"]): a for a in existing}

        where_parts_1 = ["ar.fecha_asignacion = ?", "ar.turno = ?", "ar.deleted_at IS NULL"]
        params_1 = [fecha, turno_nombre]
        if ruta_id:
            where_parts_1.append("ar.ruta_id = ?")
            params_1.append(ruta_id)
        elif distrito_id:
            where_parts_1.append("ar.distrito_id = ?")
            params_1.append(distrito_id)

        where_parts_2 = ["ap.activo = 1"]
        params_2 = []
        if ruta_id:
            where_parts_2.append("ls.ruta_id = ?")
            params_2.append(ruta_id)
        elif distrito_id:
            where_parts_2.append("r.distrito_id = ?")
            params_2.append(distrito_id)

        cursor.execute(f"""
            SELECT DISTINCT ar.agente_id AS personal_id, ar.ruta_id, ar.lugar_id,
                   ar.distrito_id, vp.nombre_completo, vp.cedula,
                   ar.tipo_asignacion, r.nombre AS ruta_nombre, ls.nombre AS lugar_nombre,
                   'ASIGNADO' AS source
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ar.agente_id
            LEFT JOIN dbo.rutas r ON r.id = ar.ruta_id
            LEFT JOIN dbo.lugares_servicio ls ON ls.id = ar.lugar_id
            WHERE {" AND ".join(where_parts_1)}
            UNION
            SELECT DISTINCT ap.personal_id, ap.punto_id AS lugar_id,
                   ls.ruta_id, r.distrito_id, vp.nombre_completo, vp.cedula,
                   ap.tipo_asignacion, r.nombre AS ruta_nombre, ls.nombre AS lugar_nombre,
                   'PUNTO' AS source
            FROM dbo.asignaciones_punto ap
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ap.personal_id
            LEFT JOIN dbo.lugares_servicio ls ON ls.id = ap.punto_id
            LEFT JOIN dbo.rutas r ON r.id = ls.ruta_id
            WHERE {" AND ".join(where_parts_2)}
        """, *params_1, *params_2)
        assigned = _rows(cursor)

        result = []
        for agent in assigned:
            pid = int(agent["personal_id"])
            existing_record = existing_map.get(pid)
            result.append({
                "personal_id": pid,
                "nombre_completo": agent["nombre_completo"],
                "cedula": agent["cedula"],
                "ruta_id": agent["ruta_id"],
                "ruta_nombre": agent["ruta_nombre"],
                "lugar_id": agent["lugar_id"],
                "lugar_nombre": agent["lugar_nombre"],
                "distrito_id": agent["distrito_id"],
                "tipo_asignacion": agent["tipo_asignacion"],
                "estado_asistencia": existing_record["estado_asistencia"] if existing_record else "PENDIENTE",
                "hora_ingreso": str(existing_record["hora_ingreso"]) if existing_record and existing_record.get("hora_ingreso") else None,
                "hora_salida": str(existing_record["hora_salida"]) if existing_record and existing_record.get("hora_salida") else None,
                "observaciones": existing_record["observaciones"] if existing_record else None,
                "asistencia_id": existing_record["id"] if existing_record else None,
                "registrado": existing_record is not None,
            })
        return result


def _get_existing_attendance(cursor, fecha: date, turno: str, distrito_id: int | None = None, ruta_id: int | None = None) -> list[dict]:
    where = ["fecha = ?", "turno = ?", "deleted_at IS NULL"]
    params = [fecha, turno]
    if distrito_id:
        where.append("distrito_id = ?")
        params.append(distrito_id)
    if ruta_id:
        where.append("ruta_id = ?")
        params.append(ruta_id)
    cursor.execute(f"""
        SELECT id, personal_id, distrito_id, ruta_id, lugar_id, fecha, turno,
               hora_ingreso, hora_salida, estado_asistencia, tipo_asignacion,
               observaciones, registrado_por
        FROM dbo.asistencia_personal
        WHERE {" AND ".join(where)}
    """, *params)
    return _rows(cursor)


def register_attendance(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        existing = _get_existing_attendance_single(cursor, data["personal_id"], data["fecha"], data["turno"])
        if existing:
            raise HTTPException(409, "Ya existe registro de asistencia para este agente en esta fecha y turno")

        cursor.execute("""
            INSERT INTO dbo.asistencia_personal
                (personal_id, distrito_id, ruta_id, lugar_id, fecha, turno,
                 hora_ingreso, estado_asistencia, tipo_asignacion, observaciones,
                 registrado_por, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
        """, data["personal_id"], data["distrito_id"], data.get("ruta_id"),
             data.get("lugar_id"), data["fecha"], data["turno"],
             data.get("hora_ingreso"), data["estado_asistencia"],
             data.get("tipo_asignacion"), data.get("observaciones"), user_id)
        record_id = int(cursor.fetchone()[0])
        _audit(cursor, user_id, "REGISTRAR_ASISTENCIA", record_id, data)
        return record_id


def _get_existing_attendance_single(cursor, personal_id: int, fecha: date, turno: str) -> dict | None:
    cursor.execute("""
        SELECT id FROM dbo.asistencia_personal
        WHERE personal_id = ? AND fecha = ? AND turno = ? AND deleted_at IS NULL
    """, personal_id, fecha, turno)
    return _row(cursor)


def batch_register(records: list[dict], user_id: int) -> dict:
    registered = 0
    skipped = 0
    errors = []
    for record in records:
        try:
            register_attendance(record, user_id)
            registered += 1
        except HTTPException as e:
            if e.status_code == 409:
                skipped += 1
            else:
                errors.append({"personal_id": record.get("personal_id"), "error": str(e.detail)})
        except Exception as e:
            errors.append({"personal_id": record.get("personal_id"), "error": str(e)})
    return {"registrados": registered, "omitidos": skipped, "errores": errors}


def update_attendance(asistencia_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.asistencia_personal WHERE id = ? AND deleted_at IS NULL", asistencia_id)
        if not _row(cursor):
            raise HTTPException(404, "Registro de asistencia no encontrado")

        sets = []
        params = []
        if data.get("estado_asistencia"):
            sets.append("estado_asistencia = ?")
            params.append(data["estado_asistencia"])
        if data.get("hora_ingreso"):
            sets.append("hora_ingreso = ?")
            params.append(data["hora_ingreso"])
        if data.get("hora_salida"):
            sets.append("hora_salida = ?")
            params.append(data["hora_salida"])
        if data.get("observaciones") is not None:
            sets.append("observaciones = ?")
            params.append(data["observaciones"])
        if not sets:
            return
        sets.append("fecha_actualizacion = SYSDATETIME()")
        params.append(asistencia_id)
        cursor.execute(f"UPDATE dbo.asistencia_personal SET {', '.join(sets)} WHERE id = ?", *params)
        _audit(cursor, user_id, "ACTUALIZAR_ASISTENCIA", asistencia_id, data)


def delete_attendance(asistencia_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE dbo.asistencia_personal SET deleted_at = SYSDATETIME(), fecha_actualizacion = SYSDATETIME()
            WHERE id = ? AND deleted_at IS NULL
        """, asistencia_id)
        if cursor.rowcount == 0:
            raise HTTPException(404, "Registro de asistencia no encontrado")
        _audit(cursor, user_id, "ELIMINAR_ASISTENCIA", asistencia_id)


def get_attendance_list(distrito_id: int | None, ruta_id: int | None, turno: str | None,
                        fecha_desde: date | None, fecha_hasta: date | None,
                        estado_asistencia: str | None, page: int, limit: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        where = ["ap.deleted_at IS NULL"]
        params = []
        if distrito_id:
            where.append("ap.distrito_id = ?")
            params.append(distrito_id)
        if ruta_id:
            where.append("ap.ruta_id = ?")
            params.append(ruta_id)
        if turno:
            where.append("ap.turno = ?")
            params.append(turno)
        if fecha_desde:
            where.append("ap.fecha >= ?")
            params.append(fecha_desde)
        if fecha_hasta:
            where.append("ap.fecha <= ?")
            params.append(fecha_hasta)
        if estado_asistencia:
            where.append("ap.estado_asistencia = ?")
            params.append(estado_asistencia)

        where_sql = " AND ".join(where)
        cursor.execute(f"SELECT COUNT(*) AS total FROM dbo.asistencia_personal ap WHERE {where_sql}", *params)
        total = int(_row(cursor)["total"])

        offset = (page - 1) * limit
        cursor.execute(f"""
            SELECT ap.id, ap.personal_id, vp.nombre_completo, vp.cedula,
                   ap.distrito_id, d.nombre AS distrito, ap.ruta_id, r.nombre AS ruta,
                   ap.lugar_id, ls.nombre AS lugar,
                   ap.fecha, ap.turno, ap.hora_ingreso, ap.hora_salida,
                   ap.estado_asistencia, ap.tipo_asignacion, ap.observaciones,
                   ap.fecha_creacion
            FROM dbo.asistencia_personal ap
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ap.personal_id
            LEFT JOIN dbo.catalogo_detalles d ON d.id = ap.distrito_id
            LEFT JOIN dbo.rutas r ON r.id = ap.ruta_id
            LEFT JOIN dbo.lugares_servicio ls ON ls.id = ap.lugar_id
            WHERE {where_sql}
            ORDER BY ap.fecha DESC, vp.nombre_completo
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """, *params, offset, limit)
        records = _rows(cursor)

        total_pages = max(1, (total + limit - 1) // limit)
        return {"records": records, "total": total, "page": page, "limit": limit, "total_pages": total_pages}


def get_attendance_stats(distrito_id: int | None, fecha: date, turno: str | None) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        where = ["ap.deleted_at IS NULL", "ap.fecha = ?"]
        params = [fecha]
        if distrito_id:
            where.append("ap.distrito_id = ?")
            params.append(distrito_id)
        if turno:
            where.append("ap.turno = ?")
            params.append(turno)
        where_sql = " AND ".join(where)

        cursor.execute(f"""
            SELECT estado_asistencia, COUNT(*) AS cnt
            FROM dbo.asistencia_personal ap
            WHERE {where_sql}
            GROUP BY ap.estado_asistencia
        """, *params)
        rows = _rows(cursor)
        stats = {r["estado_asistencia"]: int(r["cnt"]) for r in rows}

        total = sum(stats.values())
        presentes = stats.get("PRESENTE", 0) + stats.get("A_TIEMPO", 0)
        atrasos = stats.get("ATRASO", 0) + stats.get("TARDE", 0)
        ausentes = stats.get("AUSENTE", 0)
        novedades = stats.get("PERMISO", 0) + stats.get("VACACIONES", 0) + stats.get("INCAPACIDAD", 0) + stats.get("FRANCO", 0)
        pendientes = stats.get("PENDIENTE", 0)

        return {
            "total": total,
            "presentes": presentes,
            "atrasos": atrasos,
            "ausentes": ausentes,
            "novedades": novedades,
            "pendientes": pendientes,
            "porcentaje_asistencia": round(presentes / total * 100, 1) if total else 0,
        }


def populate_from_distribution(distrito_id: int, ruta_id: int | None, turno_id: int, fecha: date, user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT nombre FROM dbo.turnos WHERE id = ? AND activo = 1", turno_id)
        shift = _row(cursor)
        if not shift:
            raise HTTPException(404, "Turno no encontrado")
        turno_nombre = shift["nombre"]

        existing = _get_existing_attendance(cursor, fecha, turno_nombre, distrito_id, ruta_id)
        existing_ids = {int(a["personal_id"]) for a in existing}

        where = ["ar.fecha_asignacion = ?", "ar.turno = ?", "ar.deleted_at IS NULL"]
        params = [fecha, turno_nombre]
        if ruta_id:
            where.append("ar.ruta_id = ?")
            params.append(ruta_id)
        elif distrito_id:
            where.append("ar.distrito_id = ?")
            params.append(distrito_id)

        cursor.execute(f"""
            SELECT DISTINCT ar.agente_id, ar.distrito_id, ar.ruta_id, ar.lugar_id, ar.tipo_asignacion
            FROM dbo.asignaciones_ruta ar
            WHERE {" AND ".join(where)}
        """, *params)
        assignments = _rows(cursor)

        created = 0
        skipped = 0
        for asig in assignments:
            if int(asig["agente_id"]) in existing_ids:
                skipped += 1
                continue
            cursor.execute("""
                INSERT INTO dbo.asistencia_personal
                    (personal_id, distrito_id, ruta_id, lugar_id, fecha, turno,
                     estado_asistencia, tipo_asignacion, registrado_por, fecha_creacion)
                VALUES (?, ?, ?, ?, ?, ?, 'PENDIENTE', ?, ?, SYSDATETIME())
            """, asig["agente_id"], asig["distrito_id"], asig.get("ruta_id"),
                 asig.get("lugar_id"), fecha, turno_nombre,
                 asig.get("tipo_asignacion"), user_id)
            created += 1
        _audit(cursor, user_id, "POBLAR_DISTRIBUCION", 0, {
            "distrito_id": distrito_id, "ruta_id": ruta_id,
            "turno": turno_nombre, "fecha": str(fecha),
            "creados": created, "omitidos": skipped,
        })
        return {"creados": created, "omitidos": skipped}
