import json
from datetime import date
from decimal import Decimal

from fastapi import HTTPException

from app.core.db import get_connection


GYE_BOUNDS = (Decimal("-2.45"), Decimal("-1.85"), Decimal("-80.15"), Decimal("-79.70"))


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _row(cursor) -> dict | None:
    rows = _rows(cursor)
    return rows[0] if rows else None


def catalogs() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'DISTRITOS' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.nombre
        """)
        districts = _rows(cursor)
        cursor.execute("SELECT id, nombre, hora_inicio, hora_fin FROM dbo.turnos WHERE activo = 1 ORDER BY hora_inicio")
        shifts = _rows(cursor)
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'TIPOS_SERVICIO_LUGAR' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.orden, cd.nombre
        """)
        service_types = _rows(cursor)
        return {"distritos": districts, "turnos": shifts, "tiposServicio": service_types}


def routes_by_district(district_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id, r.turno_id, r.hora_inicio, r.hora_fin
            FROM dbo.rutas r WHERE r.activo = 1 AND r.distrito_id = ? ORDER BY r.nombre
        """, district_id)
        return _rows(cursor)


def sectors_by_route(route_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT id, nombre, distrito_id, ruta_id FROM dbo.sectores
            WHERE activo = 1 AND ruta_id = ? ORDER BY nombre
        """, route_id)
        return _rows(cursor)


def list_points(filters: dict) -> list[dict]:
    where = ["p.activo = 1", "p.latitud IS NOT NULL", "p.longitud IS NOT NULL"]
    params: list = []
    mapping = {
        "distrito_id": "p.distrito_id", "ruta_id": "p.ruta_id", "turno_id": "p.turno_id",
        "sector_id": "p.sector_id", "estado": "p.estado_operativo",
    }
    for key, column in mapping.items():
        if filters.get(key) not in (None, ""):
            where.append(f"{column} = ?")
            params.append(filters[key])
    if filters.get("agente"):
        where.append("""EXISTS (
            SELECT 1 FROM dbo.asignaciones_punto ap INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ap.personal_id
            WHERE ap.punto_id = p.id AND ap.activo = 1 AND
            (LOWER(vp.nombre_completo) LIKE ? OR LOWER(vp.cedula) LIKE ?)
        )""")
        term = f"%{str(filters['agente']).lower()}%"
        params.extend([term, term])
    sql = f"""
        SELECT p.id, p.nombre, p.ubicacion_especifica, p.direccion,
               p.latitud, p.longitud, p.estado_operativo AS estado,
               p.cantidad_requerida, d.nombre AS distrito, r.nombre AS ruta,
               s.nombre AS sector, t.nombre AS turno, p.hora_inicio, p.hora_fin,
               ts.nombre AS tipo_servicio,
               (SELECT COUNT(*) FROM dbo.asignaciones_punto ap WHERE ap.punto_id=p.id AND ap.activo=1) AS personal_asignado
        FROM dbo.lugares_servicio p
        INNER JOIN dbo.catalogo_detalles d ON d.id=p.distrito_id
        INNER JOIN dbo.rutas r ON r.id=p.ruta_id
        LEFT JOIN dbo.sectores s ON s.id=p.sector_id
        INNER JOIN dbo.turnos t ON t.id=p.turno_id
        INNER JOIN dbo.catalogo_detalles ts ON ts.id=p.tipo_servicio_id
        WHERE {' AND '.join(where)} ORDER BY p.nombre
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


def get_point(point_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT p.id, p.distrito_id, p.ruta_id, p.sector_id, p.tipo_servicio_id, p.turno_id,
                   p.nombre, p.ubicacion_especifica, p.direccion, p.latitud, p.longitud,
                   p.hora_inicio, p.hora_fin, p.cantidad_requerida, p.observacion AS observaciones,
                   p.estado_operativo AS estado, p.activo, d.nombre AS distrito, r.nombre AS ruta,
                   s.nombre AS sector, t.nombre AS turno, ts.nombre AS tipo_servicio
            FROM dbo.lugares_servicio p
            INNER JOIN dbo.catalogo_detalles d ON d.id=p.distrito_id
            INNER JOIN dbo.rutas r ON r.id=p.ruta_id LEFT JOIN dbo.sectores s ON s.id=p.sector_id
            INNER JOIN dbo.turnos t ON t.id=p.turno_id INNER JOIN dbo.catalogo_detalles ts ON ts.id=p.tipo_servicio_id
            WHERE p.id=?
        """, point_id)
        point = _row(cursor)
        if not point:
            raise HTTPException(404, "El punto de servicio no existe")
        cursor.execute("""
            SELECT ap.id, ap.personal_id, vp.nombre_completo AS agente, vp.cedula AS codigo,
                   ap.tipo_asignacion, ap.fecha_inicio, ap.fecha_fin, ap.turno_id, t.nombre AS turno,
                   ap.hora_inicio, ap.hora_fin, ap.funcion, ap.observaciones, ap.estado
            FROM dbo.asignaciones_punto ap INNER JOIN dbo.vw_personal_detalle vp ON vp.id=ap.personal_id
            INNER JOIN dbo.turnos t ON t.id=ap.turno_id WHERE ap.punto_id=? AND ap.activo=1
            ORDER BY vp.nombre_completo
        """, point_id)
        point["asignaciones"] = _rows(cursor)
        return point


def summary() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT COUNT(*) AS puntos_registrados,
              SUM(CASE WHEN estado_operativo='CUBIERTO' THEN 1 ELSE 0 END) AS puntos_cubiertos,
              SUM(CASE WHEN estado_operativo='SIN_ASIGNACION' THEN 1 ELSE 0 END) AS puntos_sin_asignacion
            FROM dbo.lugares_servicio WHERE activo=1 AND latitud IS NOT NULL AND longitud IS NOT NULL
        """)
        result = _row(cursor) or {}
        cursor.execute("SELECT COUNT(DISTINCT personal_id) AS personal_asignado FROM dbo.asignaciones_punto WHERE activo=1")
        result.update(_row(cursor) or {})
        cursor.execute("SELECT COUNT(*) AS rutas_activas FROM dbo.rutas WHERE activo=1")
        result.update(_row(cursor) or {})
        return {key: int(value or 0) for key, value in result.items()}


def _validate_relations(cursor, data: dict) -> None:
    lat, lon = Decimal(str(data["latitud"])), Decimal(str(data["longitud"]))
    if not (GYE_BOUNDS[0] <= lat <= GYE_BOUNDS[1] and GYE_BOUNDS[2] <= lon <= GYE_BOUNDS[3]):
        raise HTTPException(422, "Las coordenadas están fuera del área operativa permitida de Guayaquil")
    cursor.execute("SELECT turno_id FROM dbo.rutas WHERE id=? AND distrito_id=? AND activo=1", data["ruta_id"], data["distrito_id"])
    route = cursor.fetchone()
    if not route:
        raise HTTPException(422, "La ruta no pertenece al distrito seleccionado")
    if route[0] is not None and int(route[0]) != int(data["turno_id"]):
        raise HTTPException(422, "El turno del punto no es compatible con el turno de la ruta")
    if data.get("sector_id") is not None:
        cursor.execute("SELECT COUNT(*) FROM dbo.sectores WHERE id=? AND ruta_id=? AND distrito_id=? AND activo=1", data["sector_id"], data["ruta_id"], data["distrito_id"])
        if cursor.fetchone()[0] == 0:
            raise HTTPException(422, "El sector no pertenece a la ruta seleccionada")


def _validate_assignment(cursor, assignment: dict, point_id: int | None = None, assignment_id: int | None = None) -> None:
    cursor.execute("SELECT activo, estado_personal FROM dbo.vw_personal_detalle WHERE id=?", assignment["personal_id"])
    person = cursor.fetchone()
    if not person or not bool(person[0]) or str(person[1]).upper() != "ACTIVO":
        raise HTTPException(422, "El agente seleccionado no se encuentra activo")
    cursor.execute("""
        SELECT TOP 1 p.nombre FROM dbo.asignaciones_punto ap
        INNER JOIN dbo.lugares_servicio p ON p.id=ap.punto_id
        WHERE ap.personal_id=? AND ap.activo=1 AND (? IS NULL OR ap.id<>?)
          AND ap.fecha_inicio <= ISNULL(?, '9999-12-31') AND ISNULL(ap.fecha_fin, '9999-12-31') >= ?
          AND (ap.turno_id = ? OR (ap.hora_inicio < ? AND ap.hora_fin > ?))
    """, assignment["personal_id"], assignment_id, assignment_id, assignment.get("fecha_fin"), assignment["fecha_inicio"], assignment["turno_id"], assignment["hora_fin"], assignment["hora_inicio"])
    conflict = cursor.fetchone()
    if conflict:
        raise HTTPException(409, f"El agente seleccionado ya está asignado al punto {conflict[0]} durante ese horario")
    if point_id:
        cursor.execute("SELECT cantidad_requerida, turno_id FROM dbo.lugares_servicio WHERE id=?", point_id)
        required = cursor.fetchone()
        if required and int(required[1]) != int(assignment["turno_id"]):
            raise HTTPException(409, "El turno de la asignación no es compatible con el turno del punto")
        cursor.execute("SELECT COUNT(*) FROM dbo.asignaciones_punto WHERE punto_id=? AND activo=1 AND (? IS NULL OR id<>?)", point_id, assignment_id, assignment_id)
        if required and cursor.fetchone()[0] >= int(required[0]):
            raise HTTPException(409, "El punto ya alcanzó la cantidad máxima de agentes configurada")


def _audit(cursor, user_id: int, action: str, table: str, record_id: int, before=None, after=None) -> None:
    cursor.execute("""
        INSERT INTO dbo.auditoria (usuario_id, accion, modulo, tabla_afectada, registro_id, metodo, endpoint, datos_anteriores, datos_nuevos)
        VALUES (?, ?, N'distribucion', ?, ?, ?, ?, ?, ?)
    """, user_id, action, table, str(record_id), "POST" if action == "CREAR" else "PUT", "/api/distribucion-geografica", json.dumps(before, default=str, ensure_ascii=False) if before else None, json.dumps(after, default=str, ensure_ascii=False) if after else None)


def create_point(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        _validate_relations(cursor, data)
        cursor.execute("SELECT id FROM dbo.lugares_servicio WHERE activo=1 AND latitud=? AND longitud=?", data["latitud"], data["longitud"])
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe un punto registrado en las mismas coordenadas")
        assignments = data.pop("asignaciones", [])
        if len(assignments) > int(data["cantidad_requerida"]):
            raise HTTPException(409, "La cantidad de agentes supera el máximo configurado para el punto")
        seen = set()
        for assignment in assignments:
            if int(assignment["turno_id"]) != int(data["turno_id"]):
                raise HTTPException(409, "El turno de la asignación no es compatible con el turno del punto")
            key = (assignment["personal_id"], assignment["fecha_inicio"], assignment["turno_id"])
            if key in seen:
                raise HTTPException(409, "No se puede agregar dos veces al mismo agente, fecha y turno")
            seen.add(key)
            _validate_assignment(cursor, assignment)
        state = "CUBIERTO" if assignments else "SIN_ASIGNACION"
        cursor.execute("""
            INSERT INTO dbo.lugares_servicio
              (nombre, ubicacion_especifica, direccion, distrito_id, ruta_id, sector_id, tipo_servicio_id,
               latitud, longitud, turno_id, hora_inicio, hora_fin, cantidad_requerida, observacion,
               estado_operativo, activo, creado_por, fecha_creacion)
            OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, SYSDATETIME())
        """, data["nombre"], data["ubicacion_especifica"], data["direccion"], data["distrito_id"], data["ruta_id"], data["sector_id"], data["tipo_servicio_id"], data["latitud"], data["longitud"], data["turno_id"], data["hora_inicio"], data["hora_fin"], data["cantidad_requerida"], data.get("observaciones"), state, user_id)
        point_id = int(cursor.fetchone()[0])
        for assignment in assignments:
            _insert_assignment(cursor, point_id, assignment, user_id)
        _audit(cursor, user_id, "CREAR", "lugares_servicio", point_id, after={**data, "estado": state, "asignaciones": assignments})
        return point_id


def update_point(point_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        _validate_relations(cursor, data)
        before = get_point(point_id)
        cursor.execute("SELECT id FROM dbo.lugares_servicio WHERE activo=1 AND id<>? AND latitud=? AND longitud=?", point_id, data["latitud"], data["longitud"])
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe un punto registrado en las mismas coordenadas")
        cursor.execute("""
            UPDATE dbo.lugares_servicio SET nombre=?, ubicacion_especifica=?, direccion=?, distrito_id=?, ruta_id=?,
              sector_id=?, tipo_servicio_id=?, latitud=?, longitud=?, turno_id=?, hora_inicio=?, hora_fin=?,
              cantidad_requerida=?, observacion=?, estado_operativo=?, actualizado_por=?, fecha_actualizacion=SYSDATETIME()
            WHERE id=? AND activo=1
        """, data["nombre"], data["ubicacion_especifica"], data["direccion"], data["distrito_id"], data["ruta_id"], data["sector_id"], data["tipo_servicio_id"], data["latitud"], data["longitud"], data["turno_id"], data["hora_inicio"], data["hora_fin"], data["cantidad_requerida"], data.get("observaciones"), data["estado"], user_id, point_id)
        if cursor.rowcount == 0:
            raise HTTPException(404, "El punto de servicio no existe")
        _audit(cursor, user_id, "EDITAR", "lugares_servicio", point_id, before, data)


def deactivate_point(point_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("UPDATE dbo.lugares_servicio SET activo=0, actualizado_por=?, fecha_actualizacion=SYSDATETIME() WHERE id=? AND activo=1", user_id, point_id)
        if cursor.rowcount == 0:
            raise HTTPException(404, "El punto de servicio no existe")
        cursor.execute("UPDATE dbo.asignaciones_punto SET activo=0, estado='INACTIVA', actualizado_por=?, fecha_actualizacion=SYSDATETIME() WHERE punto_id=? AND activo=1", user_id, point_id)
        _audit(cursor, user_id, "DESACTIVAR", "lugares_servicio", point_id)


def _insert_assignment(cursor, point_id: int, data: dict, user_id: int) -> int:
    cursor.execute("""
        INSERT INTO dbo.asignaciones_punto
          (punto_id, personal_id, tipo_asignacion, fecha_inicio, fecha_fin, turno_id, hora_inicio, hora_fin,
           funcion, observaciones, estado, activo, creado_por, fecha_creacion)
        OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVA', 1, ?, SYSDATETIME())
    """, point_id, data["personal_id"], data["tipo_asignacion"], data["fecha_inicio"], data.get("fecha_fin"), data["turno_id"], data["hora_inicio"], data["hora_fin"], data.get("funcion"), data.get("observaciones"), user_id)
    return int(cursor.fetchone()[0])


def add_assignment(point_id: int, data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        _validate_assignment(cursor, data, point_id)
        assignment_id = _insert_assignment(cursor, point_id, data, user_id)
        cursor.execute("UPDATE dbo.lugares_servicio SET estado_operativo='CUBIERTO', fecha_actualizacion=SYSDATETIME() WHERE id=?", point_id)
        _audit(cursor, user_id, "ASIGNAR", "asignaciones_punto", assignment_id, after=data)
        return assignment_id


def update_assignment(assignment_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT punto_id FROM dbo.asignaciones_punto WHERE id=? AND activo=1", assignment_id)
        found = cursor.fetchone()
        if not found:
            raise HTTPException(404, "La asignación no existe")
        _validate_assignment(cursor, data, int(found[0]), assignment_id)
        cursor.execute("""
            UPDATE dbo.asignaciones_punto SET personal_id=?, tipo_asignacion=?, fecha_inicio=?, fecha_fin=?, turno_id=?,
              hora_inicio=?, hora_fin=?, funcion=?, observaciones=?, estado=?, actualizado_por=?, fecha_actualizacion=SYSDATETIME()
            WHERE id=?
        """, data["personal_id"], data["tipo_asignacion"], data["fecha_inicio"], data.get("fecha_fin"), data["turno_id"], data["hora_inicio"], data["hora_fin"], data.get("funcion"), data.get("observaciones"), data["estado"], user_id, assignment_id)
        _audit(cursor, user_id, "EDITAR_ASIGNACION", "asignaciones_punto", assignment_id, after=data)


def remove_assignment(assignment_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT punto_id FROM dbo.asignaciones_punto WHERE id=? AND activo=1", assignment_id)
        found = cursor.fetchone()
        if not found:
            raise HTTPException(404, "La asignación no existe")
        point_id = int(found[0])
        cursor.execute("UPDATE dbo.asignaciones_punto SET activo=0, estado='INACTIVA', actualizado_por=?, fecha_actualizacion=SYSDATETIME() WHERE id=?", user_id, assignment_id)
        cursor.execute("""UPDATE dbo.lugares_servicio SET estado_operativo=CASE WHEN EXISTS
            (SELECT 1 FROM dbo.asignaciones_punto WHERE punto_id=? AND activo=1) THEN 'CUBIERTO' ELSE 'SIN_ASIGNACION' END,
            fecha_actualizacion=SYSDATETIME() WHERE id=?""", point_id, point_id)
        _audit(cursor, user_id, "RETIRAR", "asignaciones_punto", assignment_id)


def create_route(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.rutas WHERE distrito_id=? AND LOWER(nombre)=LOWER(?) AND activo=1", data["distrito_id"], data["nombre"])
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe una ruta con ese nombre en el distrito")
        cursor.execute("INSERT INTO dbo.rutas (nombre, distrito_id, turno_id, hora_inicio, hora_fin, activo, fecha_creacion) OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?, 1, SYSDATETIME())", data["nombre"], data["distrito_id"], data.get("turno_id"), data.get("hora_inicio"), data.get("hora_fin"))
        item_id = int(cursor.fetchone()[0]); _audit(cursor, user_id, "CREAR", "rutas", item_id, after=data); return item_id


def create_sector(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.rutas WHERE id=? AND distrito_id=? AND activo=1", data["ruta_id"], data["distrito_id"])
        if not cursor.fetchone():
            raise HTTPException(422, "La ruta no pertenece al distrito seleccionado")
        cursor.execute("SELECT id FROM dbo.sectores WHERE ruta_id=? AND LOWER(nombre)=LOWER(?) AND activo=1", data["ruta_id"], data["nombre"])
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe un sector con ese nombre en la ruta")
        cursor.execute("INSERT INTO dbo.sectores (distrito_id, ruta_id, nombre, activo, creado_por, fecha_creacion) OUTPUT INSERTED.id VALUES (?, ?, ?, 1, ?, SYSDATETIME())", data["distrito_id"], data["ruta_id"], data["nombre"], user_id)
        item_id = int(cursor.fetchone()[0]); _audit(cursor, user_id, "CREAR", "sectores", item_id, after=data); return item_id


def person_assignments(person_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT ap.id, ap.punto_id, p.nombre AS punto, ap.fecha_inicio, ap.fecha_fin, t.nombre AS turno,
            ap.hora_inicio, ap.hora_fin, ap.funcion, ap.estado FROM dbo.asignaciones_punto ap
            INNER JOIN dbo.lugares_servicio p ON p.id=ap.punto_id INNER JOIN dbo.turnos t ON t.id=ap.turno_id
            WHERE ap.personal_id=? AND ap.activo=1 ORDER BY ap.fecha_inicio DESC""", person_id)
        return _rows(cursor)
