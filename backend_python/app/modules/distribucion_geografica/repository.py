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
        service_types.extend([
            {"id": "ENCARGADO_CIRCUITO", "nombre": "Encargado de Circuito"},
            {"id": "ENCARGADO_RUTA", "nombre": "Encargado de Ruta"},
            {"id": "ENCARGADO_DISTRITO", "nombre": "Encargado de Distrito"},
        ])
        return {"distritos": districts, "turnos": shifts, "tiposServicio": service_types}


def circuits_by_district(district_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT c.id, c.nombre, c.hora_inicio, c.hora_fin
            FROM dbo.circuitos c
            WHERE c.activo = 1 AND c.deleted_at IS NULL AND c.distrito_id = ?
            ORDER BY c.nombre
        """, district_id)
        return _rows(cursor)


def routes_by_circuit(circuit_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id, r.turno_id, r.hora_inicio, r.hora_fin
            FROM dbo.circuito_rutas cr
            INNER JOIN dbo.rutas r ON r.id = cr.ruta_id
            WHERE cr.circuito_id = ? AND cr.deleted_at IS NULL AND r.activo = 1
            ORDER BY r.nombre
        """, circuit_id)
        return _rows(cursor)


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
        "estado": "p.estado_operativo",
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
               t.nombre AS turno,
               (SELECT COUNT(*) FROM dbo.asignaciones_punto ap WHERE ap.punto_id=p.id AND ap.activo=1) AS personal_asignado
        FROM dbo.lugares_servicio p
        INNER JOIN dbo.catalogo_detalles d ON d.id=p.distrito_id
        INNER JOIN dbo.rutas r ON r.id=p.ruta_id
        LEFT JOIN dbo.turnos t ON t.id=p.turno_id
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
            SELECT p.id, p.distrito_id, p.ruta_id, p.tipo_servicio_id, p.turno_id,
                   p.nombre, p.ubicacion_especifica, p.direccion, p.latitud, p.longitud,
                   p.cantidad_requerida, p.observacion AS observaciones,
                   p.estado_operativo AS estado, p.activo, d.nombre AS distrito, r.nombre AS ruta,
                   t.nombre AS turno, ts.nombre AS tipo_servicio
            FROM dbo.lugares_servicio p
            INNER JOIN dbo.catalogo_detalles d ON d.id=p.distrito_id
            INNER JOIN dbo.rutas r ON r.id=p.ruta_id
            LEFT JOIN dbo.turnos t ON t.id=p.turno_id LEFT JOIN dbo.catalogo_detalles ts ON ts.id=p.tipo_servicio_id
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
              (nombre, ubicacion_especifica, direccion, distrito_id, ruta_id, tipo_servicio_id,
               latitud, longitud, turno_id, cantidad_requerida, observacion,
               estado_operativo, activo, creado_por, fecha_creacion)
            OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, SYSDATETIME())
        """, data["nombre"], data["ubicacion_especifica"], data["direccion"], data["distrito_id"], data["ruta_id"], data["tipo_servicio_id"], data["latitud"], data["longitud"], data["turno_id"], data["cantidad_requerida"], data.get("observaciones"), state, user_id)
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
              tipo_servicio_id=?, latitud=?, longitud=?, turno_id=?,
              cantidad_requerida=?, observacion=?, estado_operativo=?, actualizado_por=?, fecha_actualizacion=SYSDATETIME()
            WHERE id=? AND activo=1
        """, data["nombre"], data["ubicacion_especifica"], data["direccion"], data["distrito_id"], data["ruta_id"], data["tipo_servicio_id"], data["latitud"], data["longitud"], data["turno_id"], data["cantidad_requerida"], data.get("observaciones"), data["estado"], user_id, point_id)
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


def service_places_by_route(route_id: int, distrito_id: int | None = None) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        where = ["p.ruta_id = ?", "p.activo = 1"]
        params: list = [route_id]
        if distrito_id:
            where.append("p.distrito_id = ?")
            params.append(distrito_id)
        cursor.execute(f"""
            SELECT p.id, p.nombre, p.ubicacion_especifica, p.direccion,
                   p.latitud, p.longitud, p.distrito_id, p.ruta_id,
                   p.tipo_servicio_id, p.turno_id,
                   p.cantidad_requerida, p.estado_operativo AS estado, p.observacion AS observaciones,
                   d.nombre AS distrito, r.nombre AS ruta, t.nombre AS turno,
                   ts.nombre AS tipo_servicio,
                   (SELECT COUNT(*) FROM dbo.asignaciones_punto ap WHERE ap.punto_id=p.id AND ap.activo=1) AS personal_asignado
            FROM dbo.lugares_servicio p
            INNER JOIN dbo.catalogo_detalles d ON d.id=p.distrito_id
            INNER JOIN dbo.rutas r ON r.id=p.ruta_id
            LEFT JOIN dbo.turnos t ON t.id=p.turno_id
            LEFT JOIN dbo.catalogo_detalles ts ON ts.id=p.tipo_servicio_id
            WHERE {' AND '.join(where)} ORDER BY p.nombre
        """, *params)
        return _rows(cursor)


def _validate_route(cursor, route_id: int, district_id: int) -> dict:
    cursor.execute("""
        SELECT r.id, r.nombre, r.distrito_id, r.turno_id, t.nombre AS turno,
               COALESCE(t.hora_inicio, r.hora_inicio) AS hora_inicio,
               COALESCE(t.hora_fin, r.hora_fin) AS hora_fin
        FROM dbo.rutas r LEFT JOIN dbo.turnos t ON t.id=r.turno_id AND t.activo=1
        WHERE r.id=? AND r.distrito_id=? AND r.activo=1
    """, route_id, district_id)
    route = _row(cursor)
    if not route:
        raise HTTPException(422, "La ruta no pertenece al distrito seleccionado")
    return route


def _daily_managers(cursor, fecha_date: date, district_id: int | None = None, route_id: int | None = None,
                    turno_id: int | None = None, circuit_id: int | None = None) -> list[dict]:
    cursor.execute("""
        SELECT de.id, de.tipo_responsabilidad, de.distrito_id, d.nombre AS distrito,
               de.ruta_id, r.nombre AS ruta, de.circuito_id, c.nombre AS circuito, de.agente_id,
               LTRIM(RTRIM(CONCAT(CASE WHEN g.nombre IS NULL THEN '' ELSE g.nombre + ' ' END,
                                  p.nombres, ' ', p.apellidos))) AS agente,
               g.nombre AS grado, dp.fecha_distribucion,
               COALESCE(r.hora_inicio,t.hora_inicio) AS hora_inicio,
               COALESCE(r.hora_fin,t.hora_fin) AS hora_fin,
               coords.latitud, coords.longitud
        FROM dbo.distribucion_encargados de
        INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id
            AND dp.deleted_at IS NULL AND dp.estado<>N'ELIMINADA'
        INNER JOIN dbo.catalogo_detalles d ON d.id=de.distrito_id
        LEFT JOIN dbo.rutas r ON r.id=de.ruta_id
        LEFT JOIN dbo.circuitos c ON c.id=de.circuito_id
        INNER JOIN dbo.turnos t ON t.id=dp.turno_id
        INNER JOIN dbo.personal p ON p.id=de.agente_id
        LEFT JOIN dbo.grados g ON g.id=p.grado_id
        OUTER APPLY (
            SELECT AVG(CAST(ls.latitud AS FLOAT)) AS latitud,
                   AVG(CAST(ls.longitud AS FLOAT)) AS longitud
            FROM dbo.lugares_servicio ls
            WHERE ls.activo=1 AND ls.latitud IS NOT NULL AND ls.longitud IS NOT NULL
              AND ls.distrito_id=de.distrito_id
              AND (de.tipo_responsabilidad=N'ENCARGADO_DISTRITO'
                   OR (de.tipo_responsabilidad=N'ENCARGADO_RUTA' AND ls.ruta_id=de.ruta_id)
                   OR (de.tipo_responsabilidad=N'ENCARGADO_CIRCUITO' AND EXISTS (
                       SELECT 1 FROM dbo.circuito_rutas cr
                       WHERE cr.circuito_id=de.circuito_id AND cr.ruta_id=ls.ruta_id AND cr.deleted_at IS NULL)))
        ) coords
        WHERE dp.fecha_distribucion=? AND de.deleted_at IS NULL
          AND de.requiere_encargado=1 AND de.agente_id IS NOT NULL
          AND (? IS NULL OR de.distrito_id=?)
          AND (? IS NULL OR de.tipo_responsabilidad=N'ENCARGADO_DISTRITO' OR de.ruta_id=?
               OR (de.tipo_responsabilidad=N'ENCARGADO_CIRCUITO' AND EXISTS (
                   SELECT 1 FROM dbo.circuito_rutas cr
                   WHERE cr.circuito_id=de.circuito_id AND cr.ruta_id=? AND cr.deleted_at IS NULL)))
          AND (? IS NULL OR dp.turno_id=?)
          AND (? IS NULL OR de.tipo_responsabilidad=N'ENCARGADO_DISTRITO' OR de.circuito_id=?
               OR (de.tipo_responsabilidad=N'ENCARGADO_RUTA' AND EXISTS (
                   SELECT 1 FROM dbo.circuito_rutas cr
                   WHERE cr.circuito_id=? AND cr.ruta_id=de.ruta_id AND cr.deleted_at IS NULL)))
        ORDER BY de.distrito_id,
                 CASE de.tipo_responsabilidad WHEN N'ENCARGADO_DISTRITO' THEN 0 WHEN N'ENCARGADO_CIRCUITO' THEN 1 ELSE 2 END,
                 de.circuito_id,de.ruta_id,de.id
    """, fecha_date, district_id, district_id, route_id, route_id, route_id, turno_id, turno_id,
         circuit_id, circuit_id, circuit_id)
    managers = _rows(cursor)
    for manager in managers:
        manager["tipo_servicio"] = {
            "ENCARGADO_DISTRITO": "Encargado de Distrito",
            "ENCARGADO_CIRCUITO": "Encargado de Circuito",
            "ENCARGADO_RUTA": "Encargado de Ruta",
        }.get(manager["tipo_responsabilidad"], "Encargado")
        manager["tipo_registro"] = "ENCARGADO"
    return managers


def _validate_district(cursor, district_id: int) -> dict:
    cursor.execute("""
        SELECT d.id,d.nombre FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id AND c.codigo=N'DISTRITOS'
        WHERE d.id=? AND d.estado=1
    """, district_id)
    district = _row(cursor)
    if not district:
        raise HTTPException(422, "El distrito seleccionado no existe o está inactivo")
    return district


def _validate_circuit(cursor, circuit_id: int, district_id: int | None = None) -> dict:
    cursor.execute("""
        SELECT id,nombre,distrito_id FROM dbo.circuitos
        WHERE id=? AND activo=1 AND deleted_at IS NULL AND (? IS NULL OR distrito_id=?)
    """, circuit_id,district_id,district_id)
    circuit = _row(cursor)
    if not circuit:
        raise HTTPException(422, "El circuito no pertenece al distrito seleccionado")
    return circuit


def _level_trace(cursor, level: str, district_id: int, circuit_id: int | None = None,
                 route_id: int | None = None) -> dict | None:
    cursor.execute("""
        SELECT TOP 1 id,nivel_geografico,distrito_id,circuito_id,ruta_id,nombre,descripcion,
               tipo_geometria,geojson,color,grosor,opacidad,estado,fecha_creacion,fecha_actualizacion
        FROM dbo.rutas_geograficas
        WHERE nivel_geografico=? AND distrito_id=? AND activo=1
          AND (? IS NULL OR circuito_id=?) AND (? IS NULL OR ruta_id=?)
        ORDER BY COALESCE(fecha_actualizacion,fecha_creacion) DESC,id DESC
    """, level,district_id,circuit_id,circuit_id,route_id,route_id)
    return _row(cursor)


def _circuit_traces(cursor, district_id: int, circuit_id: int | None = None) -> list[dict]:
    cursor.execute("""
        SELECT c.id AS circuito_id,c.nombre AS circuito,
               rg.id,rg.nivel_geografico,rg.distrito_id,rg.nombre,rg.tipo_geometria,
               rg.geojson,rg.color,rg.grosor,rg.opacidad,rg.estado
        FROM dbo.circuitos c
        LEFT JOIN dbo.rutas_geograficas rg ON rg.circuito_id=c.id
            AND rg.nivel_geografico=N'CIRCUITO' AND rg.activo=1
        WHERE c.distrito_id=? AND c.activo=1 AND c.deleted_at IS NULL
          AND (? IS NULL OR c.id=?)
        ORDER BY c.nombre
    """, district_id,circuit_id,circuit_id)
    result=[]
    for row in _rows(cursor):
        trace = None if row.get("id") is None else {
            key: row.get(key) for key in ("id","nivel_geografico","distrito_id","nombre","tipo_geometria","geojson","color","grosor","opacidad","estado")
        }
        result.append({"circuito_id":int(row["circuito_id"]),"circuito":row["circuito"],"trace":trace})
    return result


def _route_ids_for_scope(cursor, district_id: int, circuit_id: int | None = None,
                         route_id: int | None = None) -> list[int]:
    if route_id is not None:
        _validate_route(cursor,route_id,district_id)
        if circuit_id is not None:
            _validate_circuit(cursor,circuit_id,district_id)
            cursor.execute("SELECT COUNT(*) FROM dbo.circuito_rutas WHERE circuito_id=? AND ruta_id=? AND deleted_at IS NULL",circuit_id,route_id)
            if int(cursor.fetchone()[0]) != 1:
                raise HTTPException(422,"La ruta no pertenece al circuito seleccionado")
        return [route_id]
    if circuit_id is not None:
        _validate_circuit(cursor,circuit_id,district_id)
        cursor.execute("""SELECT r.id FROM dbo.circuito_rutas cr INNER JOIN dbo.rutas r ON r.id=cr.ruta_id
                          WHERE cr.circuito_id=? AND cr.deleted_at IS NULL AND r.activo=1 AND r.distrito_id=? ORDER BY r.nombre""",circuit_id,district_id)
    else:
        cursor.execute("SELECT id FROM dbo.rutas WHERE distrito_id=? AND activo=1 ORDER BY nombre",district_id)
    return [int(row[0]) for row in cursor.fetchall()]


def _personnel_places(cursor, district_id: int, route_ids: list[int], fecha_date: date,
                      turno_id: int | None) -> list[dict]:
    if not route_ids:
        return []
    placeholders=",".join("?" for _ in route_ids)
    cursor.execute(f"""
        SELECT ls.id,ls.nombre,ls.descripcion,ls.direccion_referencial,ls.latitud,ls.longitud,
               ls.estado,ls.estado_operativo,ls.tipo_servicio_id,ts.nombre AS tipo_servicio,
               ls.ruta_id,r.nombre AS route_name,ls.distrito_id,live.distribucion_id,live.agente_id,live.agente,
               live.grado,live.hora_inicio,live.hora_fin,live.estado_asignacion,
               live.turno_id AS asignacion_turno_id,live.turno AS asignacion_turno
        FROM dbo.lugares_servicio ls
        INNER JOIN dbo.rutas r ON r.id=ls.ruta_id AND r.activo=1
        LEFT JOIN dbo.catalogo_detalles ts ON ts.id=ls.tipo_servicio_id
        OUTER APPLY (
            SELECT TOP 1 dp.id AS distribucion_id,dp.turno_id,t.nombre AS turno,dd.agente_id,
                   LTRIM(RTRIM(CONCAT(CASE WHEN g.nombre IS NULL THEN '' ELSE g.nombre+' ' END,p.nombres,' ',p.apellidos))) AS agente,
                   g.nombre AS grado,COALESCE(ar.hora_inicio,t.hora_inicio) AS hora_inicio,
                   COALESCE(ar.hora_fin,t.hora_fin) AS hora_fin,dd.estado AS estado_asignacion
            FROM dbo.distribucion_personal_detalle dd
            INNER JOIN dbo.distribuciones_personal dp ON dp.id=dd.distribucion_id
                AND dp.deleted_at IS NULL AND dp.estado<>N'ELIMINADA'
            LEFT JOIN dbo.personal p ON p.id=dd.agente_id
            LEFT JOIN dbo.grados g ON g.id=p.grado_id
            LEFT JOIN dbo.asignaciones_ruta ar ON ar.id=dd.asignacion_ruta_id AND ar.deleted_at IS NULL
            LEFT JOIN dbo.turnos t ON t.id=dp.turno_id
            WHERE dd.lugar_id=ls.id AND dd.ruta_id=ls.ruta_id AND dd.deleted_at IS NULL
              AND dp.distrito_id=ls.distrito_id AND dp.fecha_distribucion=?
              AND (? IS NULL OR dp.turno_id=?)
            ORDER BY dp.fecha_actualizacion DESC,dp.id DESC,
                     CASE WHEN dd.agente_id IS NULL THEN 1 ELSE 0 END,dd.id DESC
        ) live
        WHERE ls.ruta_id IN ({placeholders}) AND ls.distrito_id=? AND ls.activo=1
        ORDER BY ls.ruta_id,ls.nombre
    """,fecha_date,turno_id,turno_id,*route_ids,district_id)
    places=_rows(cursor)
    for place in places:
        assigned=place.get("agente_id") is not None
        place["estado_mapa"]="INACTIVO" if str(place.get("estado") or "").upper()=="INACTIVO" else ("ASIGNADO" if assigned else "PENDIENTE")
    return places


def route_map(route_id: int, district_id: int, fecha: date | None = None,
              circuit_id: int | None = None, turno_id: int | None = None) -> dict:
    """Return hierarchical geography and personnel for one route."""
    fecha_date=fecha or date.today()
    with get_connection() as connection:
        cursor=connection.cursor()
        _validate_district(cursor,district_id)
        route=_validate_route(cursor,route_id,district_id)
        if circuit_id is not None:
            _route_ids_for_scope(cursor,district_id,circuit_id,route_id)
        else:
            cursor.execute("""SELECT TOP 1 cr.circuito_id FROM dbo.circuito_rutas cr
                              INNER JOIN dbo.circuitos c ON c.id=cr.circuito_id AND c.deleted_at IS NULL AND c.activo=1
                              WHERE cr.ruta_id=? AND cr.deleted_at IS NULL""",route_id)
            found=cursor.fetchone(); circuit_id=int(found[0]) if found else None
        trace=_level_trace(cursor,"RUTA",district_id,route_id=route_id)
        route["tiene_trazado"]=bool(trace); route["trazado"]=trace
        places=_personnel_places(cursor,district_id,[route_id],fecha_date,turno_id)
        managers=_daily_managers(cursor,fecha_date,district_id,route_id,turno_id,circuit_id)
        return {
            "ruta":route,"rutas":[route],"lugares":places,"encargados":managers,
            "trazado_distrito":_level_trace(cursor,"DISTRITO",district_id),
            "trazados_circuitos":_circuit_traces(cursor,district_id,circuit_id),
            "trazados":[] if not trace else [{"route_id":route_id,"route_name":route["nombre"],"trace":trace}],
        }


def _legacy_all_routes_map(district_id: int, fecha: date | None = None) -> dict:
    """Return geography and live personnel data for ALL routes in a district."""
    fecha_date = fecha or date.today()
    with get_connection() as connection:
        cursor = connection.cursor()

        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id, r.turno_id,
                   COALESCE(r.hora_inicio, t.hora_inicio) AS hora_inicio,
                   COALESCE(r.hora_fin, t.hora_fin) AS hora_fin,
                   (SELECT COUNT(*) FROM dbo.lugares_servicio WHERE ruta_id = r.id AND activo = 1) AS lugares
            FROM dbo.rutas r
            LEFT JOIN dbo.turnos t ON t.id = r.turno_id
            WHERE r.distrito_id = ? AND r.activo = 1
            ORDER BY r.nombre
        """, district_id)
        routes = _rows(cursor)

        route_ids = [int(r["id"]) for r in routes]
        if not route_ids:
            return {"rutas": [], "trazados": [], "lugares": [], "encargados": []}

        placeholders = ",".join("?" * len(route_ids))
        cursor.execute(f"""
            SELECT id, ruta_id, nombre, tipo_geometria, geojson, color, grosor, opacidad
            FROM dbo.rutas_geograficas
            WHERE ruta_id IN ({placeholders}) AND distrito_id = ? AND activo=1
        """, *route_ids, district_id)
        traces = _rows(cursor)
        trace_map = {}
        for t in traces:
            rid = int(t["ruta_id"])
            if rid not in trace_map:
                trace_map[rid] = t

        cursor.execute(f"""
            SELECT ls.id, ls.nombre, ls.descripcion, ls.direccion_referencial,
                   ls.latitud, ls.longitud, ls.estado, ls.estado_operativo,
                   ls.tipo_servicio_id, ts.nombre AS tipo_servicio, ls.ruta_id,
                   ls.distrito_id, live.distribucion_id, live.agente_id, live.agente,
                   live.grado, live.hora_inicio, live.hora_fin, live.estado_asignacion
            FROM dbo.lugares_servicio ls
            INNER JOIN dbo.rutas r ON r.id=ls.ruta_id AND r.activo=1
            LEFT JOIN dbo.catalogo_detalles ts ON ts.id = ls.tipo_servicio_id
            OUTER APPLY (
                SELECT TOP 1 dp.id AS distribucion_id, dd.agente_id,
                       LTRIM(RTRIM(CONCAT(CASE WHEN g.nombre IS NULL THEN '' ELSE g.nombre + ' ' END,
                                           p.nombres, ' ', p.apellidos))) AS agente,
                       g.nombre AS grado, COALESCE(ar.hora_inicio, t.hora_inicio) AS hora_inicio,
                       COALESCE(ar.hora_fin, t.hora_fin) AS hora_fin, dd.estado AS estado_asignacion
                FROM dbo.distribucion_personal_detalle dd
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=dd.distribucion_id
                    AND dp.deleted_at IS NULL AND dp.estado <> 'ELIMINADA'
                LEFT JOIN dbo.personal p ON p.id=dd.agente_id
                LEFT JOIN dbo.grados g ON g.id=p.grado_id
                LEFT JOIN dbo.asignaciones_ruta ar ON ar.id=dd.asignacion_ruta_id AND ar.deleted_at IS NULL
                LEFT JOIN dbo.turnos t ON t.id=dp.turno_id
                WHERE dd.lugar_id=ls.id AND dd.ruta_id=ls.ruta_id AND dd.deleted_at IS NULL
                  AND dp.distrito_id=ls.distrito_id AND dp.fecha_distribucion=?
                  AND dp.turno_id=COALESCE(ls.turno_id, r.turno_id)
                ORDER BY dp.fecha_actualizacion DESC, dp.id DESC,
                         CASE WHEN dd.agente_id IS NULL THEN 1 ELSE 0 END, dd.id DESC
            ) live
            WHERE ls.ruta_id IN ({placeholders}) AND ls.distrito_id = ? AND ls.activo = 1
            ORDER BY ls.ruta_id, ls.nombre
        """, fecha_date, *route_ids, district_id)
        places = _rows(cursor)

        dedup = {}
        for place in places:
            pid = int(place["id"])
            if pid not in dedup:
                dedup[pid] = place
        places = list(dedup.values())

        route_name_map = {int(r["id"]): r["nombre"] for r in routes}
        for place in places:
            assigned = place.get("agente_id") is not None
            place["estado_mapa"] = "INACTIVO" if str(place.get("estado") or "").upper() == "INACTIVO" else ("ASIGNADO" if assigned else "PENDIENTE")
            place["route_name"] = route_name_map.get(int(place["ruta_id"]), "")

        all_traces = []
        for route in routes:
            rid = int(route["id"])
            if rid in trace_map:
                all_traces.append({"route_id": rid, "route_name": route["nombre"], "trace": trace_map[rid]})

        managers = _daily_managers(cursor, fecha_date, district_id)
        return {"rutas": routes, "trazados": all_traces, "lugares": places, "encargados": managers}


def all_routes_map(district_id: int, fecha: date | None = None, circuit_id: int | None = None,
                   turno_id: int | None = None) -> dict:
    """Return independent district, circuit and route layers for the selected scope."""
    fecha_date=fecha or date.today()
    with get_connection() as connection:
        cursor=connection.cursor()
        _validate_district(cursor,district_id)
        route_ids=_route_ids_for_scope(cursor,district_id,circuit_id)
        routes=[]
        traces=[]
        if route_ids:
            placeholders=",".join("?" for _ in route_ids)
            cursor.execute(f"""
                SELECT r.id,r.nombre,r.distrito_id,r.turno_id,
                       COALESCE(r.hora_inicio,t.hora_inicio) AS hora_inicio,
                       COALESCE(r.hora_fin,t.hora_fin) AS hora_fin,
                       (SELECT COUNT(*) FROM dbo.lugares_servicio ls WHERE ls.ruta_id=r.id AND ls.activo=1) AS lugares
                FROM dbo.rutas r LEFT JOIN dbo.turnos t ON t.id=r.turno_id
                WHERE r.id IN ({placeholders}) ORDER BY r.nombre
            """,*route_ids)
            routes=_rows(cursor)
            cursor.execute(f"""
                SELECT id,ruta_id,nombre,tipo_geometria,geojson,color,grosor,opacidad,estado
                FROM dbo.rutas_geograficas
                WHERE nivel_geografico=N'RUTA' AND ruta_id IN ({placeholders})
                  AND distrito_id=? AND activo=1 ORDER BY id DESC
            """,*route_ids,district_id)
            trace_map={}
            for trace in _rows(cursor):
                trace_map.setdefault(int(trace["ruta_id"]),trace)
            route_names={int(route["id"]):route["nombre"] for route in routes}
            traces=[{"route_id":rid,"route_name":route_names.get(rid,""),"trace":trace}
                    for rid,trace in trace_map.items()]
        places=_personnel_places(cursor,district_id,route_ids,fecha_date,turno_id)
        route_names={int(route["id"]):route["nombre"] for route in routes}
        for place in places: place["route_name"]=route_names.get(int(place["ruta_id"]),"")
        managers=_daily_managers(cursor,fecha_date,district_id,None,turno_id,circuit_id)
        return {
            "rutas":routes,"trazados":traces,"lugares":places,"encargados":managers,
            "trazado_distrito":_level_trace(cursor,"DISTRITO",district_id),
            "trazados_circuitos":_circuit_traces(cursor,district_id,circuit_id),
        }


def personnel_map(district_id: int, fecha: date | None = None, circuit_id: int | None = None,
                  route_id: int | None = None, turno_id: int | None = None) -> dict:
    """Refresh only point/personnel data; no geographic trace is queried or returned."""
    fecha_date=fecha or date.today()
    with get_connection() as connection:
        cursor=connection.cursor()
        _validate_district(cursor,district_id)
        route_ids=_route_ids_for_scope(cursor,district_id,circuit_id,route_id)
        places=_personnel_places(cursor,district_id,route_ids,fecha_date,turno_id)
        managers=_daily_managers(cursor,fecha_date,district_id,route_id,turno_id,circuit_id)
        if circuit_id is not None and route_id is None:
            allowed=set(route_ids)
            managers=[m for m in managers if m.get("tipo_responsabilidad")=="ENCARGADO_DISTRITO" or int(m.get("ruta_id") or 0) in allowed]
        return {"lugares":places,"encargados":managers}


def global_map(fecha: date | None = None, turno_id: int | None = None) -> dict:
    """Return the complete geographic base and exact-date distribution when no district is selected."""
    fecha_date = fecha or date.today()
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT DISTINCT d.id,d.nombre
            FROM dbo.catalogo_detalles d
            INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id AND c.codigo='DISTRITOS'
            INNER JOIN dbo.rutas r ON r.distrito_id=d.id AND r.activo=1
            WHERE d.estado=1
            ORDER BY d.nombre
        """)
        districts = _rows(cursor)

    combined = {"distritos": districts, "rutas": [], "trazados": [], "trazados_circuitos": [], "trazados_distritos": [], "lugares": [], "encargados": []}
    for district in districts:
        district_data = all_routes_map(int(district["id"]), fecha_date, None, turno_id)
        for route in district_data.get("rutas", []):
            route["distrito"] = district["nombre"]
        for place in district_data.get("lugares", []):
            place["distrito"] = district["nombre"]
        combined["rutas"].extend(district_data.get("rutas", []))
        combined["trazados"].extend(district_data.get("trazados", []))
        combined["trazados_circuitos"].extend(district_data.get("trazados_circuitos", []))
        if district_data.get("trazado_distrito"):
            combined["trazados_distritos"].append({"district_id":district["id"],"district_name":district["nombre"],"trace":district_data["trazado_distrito"]})
        combined["lugares"].extend(district_data.get("lugares", []))
        combined["encargados"].extend(district_data.get("encargados", []))
    return combined


def _trace_coordinates(geojson: dict, trace_type: str) -> list:
    geometry = geojson.get("geometry") if geojson.get("type") == "Feature" else geojson
    expected = "Polygon" if trace_type == "area" else "LineString"
    if not isinstance(geometry, dict) or geometry.get("type") != expected:
        raise HTTPException(422, f"El trazado debe ser un GeoJSON {expected}")
    coordinates = geometry.get("coordinates")
    if trace_type == "area":
        if not isinstance(coordinates, list) or not coordinates or not isinstance(coordinates[0], list):
            raise HTTPException(422, "El área contiene coordenadas inválidas")
        coordinates = coordinates[0]
        if len(coordinates) < 4 or coordinates[0][:2] != coordinates[-1][:2]:
            raise HTTPException(422, "El área debe tener al menos tres puntos y estar cerrada")
    elif not isinstance(coordinates, list) or len(coordinates) < 2:
        raise HTTPException(422, "El trazado debe contener al menos dos puntos")
    for coordinate in coordinates:
        if not isinstance(coordinate, list) or len(coordinate) < 2:
            raise HTTPException(422, "El trazado contiene coordenadas inválidas")
        longitude, latitude = Decimal(str(coordinate[0])), Decimal(str(coordinate[1]))
        if not (GYE_BOUNDS[0] <= latitude <= GYE_BOUNDS[1] and GYE_BOUNDS[2] <= longitude <= GYE_BOUNDS[3]):
            raise HTTPException(422, "El trazado contiene puntos fuera del área operativa permitida")
    return coordinates


def upsert_hierarchical_trace(level: str, target_id: int, data: dict, user_id: int) -> dict:
    level=level.upper()
    if level not in {"DISTRITO","CIRCUITO"}:
        raise HTTPException(422,"Nivel geográfico no válido")
    _trace_coordinates(data["geojson"],data["tipo_geometria"])
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        if level=="DISTRITO":
            entity=_validate_district(cursor,target_id); district_id=target_id; circuit_id=None
        else:
            entity=_validate_circuit(cursor,target_id); district_id=int(entity["distrito_id"]); circuit_id=target_id
        cursor.execute("""
            SELECT TOP 1 id,nivel_geografico,distrito_id,circuito_id,ruta_id,nombre,geojson,color,grosor,opacidad
            FROM dbo.rutas_geograficas WITH (UPDLOCK,HOLDLOCK)
            WHERE nivel_geografico=? AND distrito_id=? AND (? IS NULL OR circuito_id=?) AND activo=1
            ORDER BY id DESC
        """,level,district_id,circuit_id,circuit_id)
        before=_row(cursor)
        serialized=json.dumps(data["geojson"],ensure_ascii=False,separators=(",",":"))
        if before:
            cursor.execute("""UPDATE dbo.rutas_geograficas SET nombre=?,tipo_geometria=?,geojson=?,color=?,grosor=?,opacidad=?,
                              estado=N'ACTIVA',actualizado_por=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
                           entity["nombre"],data["tipo_geometria"],serialized,data["color"],data["grosor"],data["opacidad"],user_id,before["id"])
            trace_id,created=int(before["id"]),False
        else:
            cursor.execute("""INSERT INTO dbo.rutas_geograficas
                              (nivel_geografico,distrito_id,circuito_id,ruta_id,nombre,tipo_geometria,geojson,color,grosor,opacidad,estado,creado_por,activo,fecha_creacion)
                              OUTPUT INSERTED.id VALUES(?,?,?,NULL,?,?,?,?,?,?,N'ACTIVA',?,1,SYSDATETIME())""",
                           level,district_id,circuit_id,entity["nombre"],data["tipo_geometria"],serialized,data["color"],data["grosor"],data["opacidad"],user_id)
            trace_id,created=int(cursor.fetchone()[0]),True
        after={"nivel_geografico":level,"distrito_id":district_id,"circuito_id":circuit_id,"geojson":data["geojson"]}
        _audit(cursor,user_id,"ASIGNAR_TRAZADO" if created else "MODIFICAR_TRAZADO","rutas_geograficas",trace_id,before,after)
        return {"id":trace_id,"creado":created,"nivel":level}


def upsert_route_trace(route_id: int, data: dict, user_id: int) -> dict:
    _trace_coordinates(data["geojson"], data["tipo_geometria"])
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        route = _validate_route(cursor, route_id, int(data["distrito_id"]))
        circuit_id=data.get("circuito_id")
        if circuit_id is not None:
            _route_ids_for_scope(cursor,int(data["distrito_id"]),int(circuit_id),route_id)
        cursor.execute("""
            SELECT TOP 1 id, distrito_id, ruta_id, nombre, geojson, color, grosor, opacidad
            FROM dbo.rutas_geograficas WITH (UPDLOCK, HOLDLOCK)
            WHERE nivel_geografico=N'RUTA' AND ruta_id=? AND activo=1 ORDER BY id DESC
        """, route_id)
        before = _row(cursor)
        serialized = json.dumps(data["geojson"], ensure_ascii=False, separators=(",", ":"))
        if before:
            cursor.execute("""
                UPDATE dbo.rutas_geograficas SET nivel_geografico=N'RUTA',distrito_id=?,circuito_id=?,nombre=?,tipo_geometria=?,
                    geojson=?, color=?, grosor=?, opacidad=?, estado=N'ACTIVA', actualizado_por=?,
                    fecha_actualizacion=SYSDATETIME()
                WHERE id=?
            """, data["distrito_id"],circuit_id,route["nombre"],data["tipo_geometria"],serialized,data["color"],data["grosor"],
                 data["opacidad"], user_id, before["id"])
            trace_id, action, created = int(before["id"]), "MODIFICAR_TRAZADO", False
        else:
            cursor.execute("""
                INSERT INTO dbo.rutas_geograficas
                    (nivel_geografico,distrito_id,circuito_id,ruta_id,nombre,tipo_geometria,geojson,color,grosor,opacidad,estado,creado_por,activo,fecha_creacion)
                OUTPUT INSERTED.id VALUES (N'RUTA',?,?,?,?,?,?,?,?,?,N'ACTIVA',?,1,SYSDATETIME())
            """,data["distrito_id"],circuit_id,route_id,route["nombre"],data["tipo_geometria"],serialized,data["color"],
                 data["grosor"], data["opacidad"], user_id)
            trace_id, action, created = int(cursor.fetchone()[0]), "ASIGNAR_TRAZADO", True
        after = {"ruta_id": route_id, "distrito_id": data["distrito_id"], "tipo_geometria": data["tipo_geometria"], "geojson": data["geojson"]}
        _audit(cursor, user_id, action, "rutas_geograficas", trace_id, before, after)
        return {"id": trace_id, "creado": created}


def remove_place_location(place_id: int, user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT id, nombre, ruta_id, distrito_id, latitud, longitud
            FROM dbo.lugares_servicio WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND activo=1
        """, place_id)
        before = _row(cursor)
        if not before:
            raise HTTPException(404, "El lugar de servicio no existe")
        if before["latitud"] is None and before["longitud"] is None:
            raise HTTPException(422, "Este lugar de servicio no tiene ubicación asignada")
        cursor.execute("""
            UPDATE dbo.lugares_servicio SET latitud=NULL, longitud=NULL, actualizado_por=?,
                fecha_actualizacion=SYSDATETIME() WHERE id=?
        """, user_id, place_id)
        after = {"latitud": None, "longitud": None}
        _audit(cursor, user_id, "ELIMINAR_UBICACION", "lugares_servicio", place_id, before, after)
        return {"id": place_id}


def update_place_location(place_id: int, data: dict, user_id: int) -> dict:
    latitude, longitude = Decimal(str(data["latitud"])), Decimal(str(data["longitud"]))
    if not (GYE_BOUNDS[0] <= latitude <= GYE_BOUNDS[1] and GYE_BOUNDS[2] <= longitude <= GYE_BOUNDS[3]):
        raise HTTPException(422, "Las coordenadas están fuera del área operativa permitida")
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        _validate_route(cursor, int(data["ruta_id"]), int(data["distrito_id"]))
        cursor.execute("""
            SELECT id, nombre, ruta_id, distrito_id, latitud, longitud
            FROM dbo.lugares_servicio WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND ruta_id=? AND distrito_id=? AND activo=1
        """, place_id, data["ruta_id"], data["distrito_id"])
        before = _row(cursor)
        if not before:
            raise HTTPException(422, "El lugar no pertenece a la ruta y distrito seleccionados")
        had_location = before["latitud"] is not None and before["longitud"] is not None
        if had_location and not data.get("reemplazar"):
            raise HTTPException(409, "Este lugar de servicio ya posee una ubicación asignada")
        cursor.execute("""
            SELECT TOP 1 nombre FROM dbo.lugares_servicio
            WHERE id<>? AND activo=1 AND latitud=? AND longitud=?
        """, place_id, latitude, longitude)
        duplicate = cursor.fetchone()
        if duplicate:
            raise HTTPException(409, f"Las coordenadas ya pertenecen al lugar {duplicate[0]}")
        cursor.execute("""
            UPDATE dbo.lugares_servicio SET latitud=?, longitud=?, actualizado_por=?,
                fecha_actualizacion=SYSDATETIME() WHERE id=?
        """, latitude, longitude, user_id, place_id)
        action = "MODIFICAR_UBICACION" if had_location else "ASIGNAR_UBICACION"
        after = {"ruta_id": data["ruta_id"], "distrito_id": data["distrito_id"], "latitud": str(latitude), "longitud": str(longitude)}
        _audit(cursor, user_id, action, "lugares_servicio", place_id, before, after)
        return {"id": place_id, "reemplazada": had_location, "latitud": latitude, "longitud": longitude}
