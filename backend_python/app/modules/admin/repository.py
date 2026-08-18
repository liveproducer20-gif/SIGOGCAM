import re
import unicodedata

import pyodbc

from app.core.db import get_connection
from app.core.sanitize import escape_like

# District ID for "Estacion de Accion Segura" — circuits in this district use EAS as circuit options
ESTACION_DISTRICT_ID = 1143


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _query(sql: str, *params) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


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


def list_eas() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        if _table_exists(connection, "eas"):
            cursor.execute(
                """
                SELECT id, codigo, nombre, direccion, activo
                FROM dbo.eas
                ORDER BY codigo, nombre
                """
            )
        else:
            cursor.execute(
                """
                SELECT e.id, e.codigo, e.nombre, e.ubicacion, e.direccion, e.distrito_id,
                       d.nombre AS distrito, e.activo, e.fecha_creacion, e.fecha_actualizacion
                FROM dbo.eas_estaciones e
                LEFT JOIN dbo.catalogo_detalles d ON d.id = e.distrito_id
                ORDER BY e.codigo, e.nombre
                """
            )
        return _rows(cursor)


def list_mobile_units() -> list[dict]:
    return _query(
        """
        SELECT m.id, m.numero_movil, m.placa, m.tipo_movil_id, tm.nombre AS tipo_movil,
               m.estado_movil_id, em.nombre AS estado_movil, m.kilometraje_actual,
               m.kilometraje_ultimo_mantenimiento, m.proximo_mantenimiento,
               m.observacion, m.observacion_estado, m.activo,
               a.id AS asignacion_id, a.eas_id, e.nombre AS eas_nombre
        FROM dbo.moviles m
        LEFT JOIN dbo.catalogo_detalles tm ON tm.id=m.tipo_movil_id
        LEFT JOIN dbo.catalogo_detalles em ON em.id=m.estado_movil_id
        LEFT JOIN dbo.movil_eas_asignaciones a ON a.movil_id=m.id AND a.activo=1
        LEFT JOIN dbo.eas_estaciones e ON e.id=a.eas_id
        ORDER BY m.numero_movil
        """
    )


def list_routes() -> list[dict]:
    rows = _query(
        """
        SELECT r.id, r.nombre, r.distrito_id, d.nombre AS distrito,
               CONVERT(VARCHAR(5),r.hora_inicio,108) AS hora_inicio,
               CONVERT(VARCHAR(5),r.hora_fin,108) AS hora_fin, r.asignar_encargado, r.activo,
               circuit.id AS circuito_id, circuit.nombre AS circuito
        FROM dbo.rutas r
        LEFT JOIN dbo.catalogo_detalles d ON d.id=r.distrito_id
        OUTER APPLY (
            SELECT TOP 1 c.id,c.nombre
            FROM dbo.circuito_rutas cr
            INNER JOIN dbo.circuitos c ON c.id=cr.circuito_id
            WHERE cr.ruta_id=r.id AND cr.deleted_at IS NULL AND c.deleted_at IS NULL
            ORDER BY c.nombre,c.id
        ) circuit
        ORDER BY r.nombre
        """
    )
    # Attach multi-turn data from junction table
    route_ids = [int(row["id"]) for row in rows]
    turn_map: dict[int, list[dict]] = {}
    if route_ids:
        placeholders = ",".join("?" for _ in route_ids)
        turn_rows = _query(
            f"""SELECT rt.ruta_id, t.id AS turno_id, t.nombre AS turno
               FROM dbo.ruta_turnos rt
               INNER JOIN dbo.turnos t ON t.id = rt.turno_id
               WHERE rt.ruta_id IN ({placeholders})
               ORDER BY rt.ruta_id, t.id""",
            *route_ids,
        )
        for tr in turn_rows:
            turn_map.setdefault(int(tr["ruta_id"]), []).append({
                "turno_id": int(tr["turno_id"]),
                "turno": str(tr["turno"]),
            })
    for row in rows:
        rid = int(row["id"])
        turns = turn_map.get(rid, [])
        row["turnos"] = turns
        row["turno_id"] = turns[0]["turno_id"] if turns else None
        row["turno"] = ", ".join(t["turno"] for t in turns) if turns else None
    return rows


def list_service_places() -> list[dict]:
    rows = _query(
        """
        SELECT l.id, l.nombre, l.direccion, l.ubicacion_especifica, l.distrito_id,
               d.nombre AS distrito, l.ruta_id, r.nombre AS ruta,
               l.tipo_servicio_id, ts.nombre AS tipo_servicio,
               l.cantidad_requerida, l.estado_operativo, l.consignas, l.observacion, l.lugar_formacion,
               l.latitud, l.longitud, ISNULL(r.asignar_encargado,0) AS ruta_asignar_encargado, l.activo
        FROM dbo.lugares_servicio l
        LEFT JOIN dbo.catalogo_detalles d ON d.id=l.distrito_id
        LEFT JOIN dbo.rutas r ON r.id=l.ruta_id
        LEFT JOIN dbo.catalogo_detalles ts ON ts.id=l.tipo_servicio_id
        ORDER BY COALESCE(l.nombre,l.direccion)
        """
    )
    # Attach multi-turn data from junction table
    place_ids = [int(row["id"]) for row in rows]
    turn_map: dict[int, list[dict]] = {}
    if place_ids:
        placeholders = ",".join("?" for _ in place_ids)
        turn_rows = _query(
            f"""SELECT lt.lugar_servicio_id, t.id AS turno_id, t.nombre AS turno
               FROM dbo.lugar_turnos lt
               INNER JOIN dbo.turnos t ON t.id = lt.turno_id
               WHERE lt.lugar_servicio_id IN ({placeholders})
               ORDER BY lt.lugar_servicio_id, t.id""",
            *place_ids,
        )
        for tr in turn_rows:
            turn_map.setdefault(int(tr["lugar_servicio_id"]), []).append({
                "turno_id": int(tr["turno_id"]),
                "turno": str(tr["turno"]),
            })
    for row in rows:
        pid = int(row["id"])
        turns = turn_map.get(pid, [])
        row["turnos"] = turns
        row["turno_id"] = turns[0]["turno_id"] if turns else None
        row["turno"] = ", ".join(t["turno"] for t in turns) if turns else None
    return rows


def list_grades() -> list[dict]:
    return _query(
        """
        SELECT id, nombre, CAST(NULL AS NVARCHAR(40)) AS abreviatura, activo
        FROM dbo.grados
        ORDER BY nombre
        """
    )


def admin_references() -> dict:
    def catalog(code: str) -> list[dict]:
        return _query(
            """SELECT d.id,d.codigo,d.nombre FROM dbo.catalogo_detalles d
               INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
               WHERE c.codigo=? AND d.estado=1 ORDER BY d.orden,d.nombre""", code
        )
    return {
        "distritos": catalog("DISTRITOS"),
        "tiposMovil": catalog("TIPOS_MOVIL"),
        "estadosMovil": catalog("ESTADOS_MOVIL"),
        "estadosAsignacion": catalog("ESTADOS_ASIGNACION_MOVIL"),
        "tiposMantenimiento": catalog("TIPOS_MANTENIMIENTO"),
        "tiposServicio": catalog("TIPOS_SERVICIO_LUGAR"),
        "turnos": _query("SELECT id,nombre FROM dbo.turnos WHERE activo=1 ORDER BY nombre"),
        "sectores": _query("SELECT id,nombre,ruta_id FROM dbo.sectores WHERE activo=1 ORDER BY nombre"),
        "rutas": _query(
            "SELECT id,nombre,distrito_id FROM dbo.rutas WHERE activo=1 AND distrito_id IS NOT NULL ORDER BY nombre"
        ),
    }


def list_circuits(district_id: int | None = None, search: str | None = None) -> list[dict]:
    term = escape_like((search or "").strip())
    rows = _query(
        """
        SELECT c.id,c.distrito_id,d.nombre AS distrito,c.nombre,
               CONVERT(VARCHAR(5),c.hora_inicio,108) AS hora_inicio,
               CONVERT(VARCHAR(5),c.hora_fin,108) AS hora_fin,
               c.lugar_formacion,c.consignas,c.observaciones,c.perimetro,c.activo,
               ISNULL(ra.total_rutas,0) AS total_rutas,ra.ruta_ids,ra.rutas
        FROM dbo.circuitos c
        INNER JOIN dbo.catalogo_detalles d ON d.id=c.distrito_id
        OUTER APPLY (
            SELECT COUNT(*) AS total_rutas,
                   STRING_AGG(CONVERT(NVARCHAR(MAX),x.ruta_id),',') WITHIN GROUP (ORDER BY x.nombre) AS ruta_ids,
                   STRING_AGG(CONVERT(NVARCHAR(MAX),x.nombre),' · ') WITHIN GROUP (ORDER BY x.nombre) AS rutas
            FROM (
                SELECT cr.ruta_id,r.nombre
                FROM dbo.circuito_rutas cr
                INNER JOIN dbo.rutas r ON r.id=cr.ruta_id
                WHERE cr.circuito_id=c.id AND cr.deleted_at IS NULL
            ) x
        ) ra
        WHERE c.deleted_at IS NULL
          AND (? IS NULL OR c.distrito_id=?)
          AND (?='' OR c.nombre LIKE '%'+?+'%' ESCAPE '\\' OR d.nombre LIKE '%'+?+'%' ESCAPE '\\')
        ORDER BY d.nombre,c.nombre
        """,
        district_id,district_id,term,term,term,
    )
    for row in rows:
        row["ruta_ids"] = [int(value) for value in (row.get("ruta_ids") or "").split(",") if value]
    # Load EAS from junction table
    circuit_ids = [int(r["id"]) for r in rows]
    if circuit_ids:
        placeholders = ','.join('?' for _ in circuit_ids)
        eas_rows = _query(
            f"""SELECT ce.circuito_id, ce.eas_id, e.nombre AS eas_nombre, e.codigo AS eas_codigo
                FROM dbo.circuito_eas ce
                INNER JOIN dbo.eas_estaciones e ON e.id=ce.eas_id
                WHERE ce.circuito_id IN ({placeholders})""",
            *circuit_ids,
        )
        eas_map: dict[int, list] = {}
        for er in eas_rows:
            cid = int(er["circuito_id"])
            eas_map.setdefault(cid, []).append({
                "eas_id": int(er["eas_id"]),
                "eas_nombre": er["eas_nombre"],
                "eas_codigo": er["eas_codigo"],
            })
        for row in rows:
            cid = int(row["id"])
            row["eas_list"] = eas_map.get(cid, [])
    return rows


def list_eas_for_estacion() -> list[dict]:
    """Return active EAS records for the Estacion de Accion Segura district."""
    return _query(
        """SELECT id, codigo, nombre, activo
           FROM dbo.eas_estaciones
           WHERE activo = 1
           ORDER BY codigo, nombre"""
    )


def get_circuit(item_id: int) -> dict:
    rows = list_circuits()
    for row in rows:
        if int(row["id"]) == item_id:
            return row
    raise ValueError("Circuito no encontrado")


def _validate_circuit(cursor, data: dict, item_id: int | None = None) -> tuple:
    district_id = int(data.get("distritoId") or 0)
    name = str(data.get("nombre") or "").strip()
    if not district_id or not name:
        raise ValueError("Distrito y nombre son obligatorios")
    cursor.execute(
        """SELECT COUNT(*) FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
           WHERE d.id=? AND d.estado=1 AND c.codigo='DISTRITOS'""", district_id,
    )
    if int(cursor.fetchone()[0]) != 1:
        raise ValueError("El distrito seleccionado no es válido")
    cursor.execute(
        "SELECT COUNT(*) FROM dbo.circuitos WHERE distrito_id=? AND nombre=? AND deleted_at IS NULL AND (? IS NULL OR id<>?)",
        district_id,name,item_id,item_id,
    )
    if int(cursor.fetchone()[0]):
        raise ValueError("Ya existe un circuito con ese nombre en el distrito")
    return district_id,name


def _replace_circuit_routes(cursor, circuit_id: int, district_id: int, route_ids: list) -> None:
    normalized = list(dict.fromkeys(int(value) for value in (route_ids or []) if int(value) > 0))
    if normalized:
        placeholders = ",".join("?" for _ in normalized)
        cursor.execute(
            f"SELECT id FROM dbo.rutas WHERE activo=1 AND distrito_id=? AND id IN ({placeholders})",
            district_id,*normalized,
        )
        valid = {int(row[0]) for row in cursor.fetchall()}
        if valid != set(normalized):
            raise ValueError("Todas las rutas deben pertenecer al distrito seleccionado")
        cursor.execute(
            f"""SELECT r.nombre FROM dbo.circuito_rutas cr INNER JOIN dbo.rutas r ON r.id=cr.ruta_id
                INNER JOIN dbo.circuitos c ON c.id=cr.circuito_id
                WHERE cr.deleted_at IS NULL AND c.deleted_at IS NULL AND cr.circuito_id<>?
                  AND cr.ruta_id IN ({placeholders})""",
            circuit_id,*normalized,
        )
        occupied = [str(row[0]) for row in cursor.fetchall()]
        if occupied:
            raise ValueError("Estas rutas ya pertenecen a otro circuito: " + ", ".join(occupied))
    cursor.execute("UPDATE dbo.circuito_rutas SET deleted_at=SYSDATETIME() WHERE circuito_id=? AND deleted_at IS NULL", circuit_id)
    for route_id in normalized:
        cursor.execute(
            """UPDATE dbo.circuito_rutas SET deleted_at=NULL,fecha_creacion=SYSDATETIME()
               WHERE id=(SELECT TOP 1 id FROM dbo.circuito_rutas WHERE circuito_id=? AND ruta_id=? ORDER BY id DESC)""",
            circuit_id,route_id,
        )
        if cursor.rowcount == 0:
            cursor.execute("INSERT INTO dbo.circuito_rutas(circuito_id,ruta_id) VALUES(?,?)", circuit_id,route_id)


def get_available_routes_for_circuit(district_id: int, circuito_id: int | None = None) -> list[dict]:
    """Return routes available for a circuit: unassigned routes + routes of the current circuit."""
    with get_connection() as connection:
        cursor = connection.cursor()
        # Get routes that are either unassigned OR belong to this circuit
        cursor.execute(
            """
            SELECT r.id, r.nombre, r.distrito_id, d.nombre AS distrito,
                   CASE WHEN cr.ruta_id IS NOT NULL THEN 1 ELSE 0 END AS asignada_a_este_circuito
            FROM dbo.rutas r
            LEFT JOIN dbo.catalogo_detalles d ON d.id = r.distrito_id
            LEFT JOIN dbo.circuito_rutas cr ON cr.ruta_id = r.id AND cr.deleted_at IS NULL
                AND cr.circuito_id = ?
            WHERE r.activo = 1 AND r.distrito_id = ?
              AND (
                  NOT EXISTS (
                      SELECT 1 FROM dbo.circuito_rutas cr2
                      WHERE cr2.ruta_id = r.id AND cr2.deleted_at IS NULL
                  )
                  OR cr.ruta_id IS NOT NULL
              )
            ORDER BY r.nombre
            """,
            circuito_id or 0, district_id,
        )
        return _rows(cursor)


def _sync_circuito_eas(cursor, circuit_id: int, eas_ids: list) -> None:
    """Sync junction table for circuit EAS. Replaces all existing rows."""
    cursor.execute("DELETE FROM dbo.circuito_eas WHERE circuito_id = ?", circuit_id)
    for eas_id in eas_ids:
        cursor.execute(
            "INSERT INTO dbo.circuito_eas (circuito_id, eas_id) VALUES (?, ?)",
            circuit_id, int(eas_id),
        )


def create_circuit(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        district_id,name = _validate_circuit(cursor,data)
        eas_ids = [int(x) for x in (data.get("easIds") or []) if int(x) > 0] if district_id == ESTACION_DISTRICT_ID else []
        cursor.execute(
            """INSERT INTO dbo.circuitos(
                   distrito_id,nombre,hora_inicio,hora_fin,lugar_formacion,consignas,observaciones,perimetro,activo)
               OUTPUT INSERTED.id VALUES(?,?,?,?,?,?,?,?,1)""",
            district_id,name,data.get("horaInicio") or None,data.get("horaFin") or None,data.get("lugarFormacion") or None,
            data.get("consignas") or None,data.get("observaciones") or None,data.get("perimetro") or None,
        )
        circuit_id = int(cursor.fetchone()[0])
        _sync_circuito_eas(cursor, circuit_id, eas_ids)
        _replace_circuit_routes(cursor,circuit_id,district_id,data.get("rutaIds") or [])
        return circuit_id


def update_circuit(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM dbo.circuitos WHERE id=? AND deleted_at IS NULL",item_id)
        if int(cursor.fetchone()[0]) != 1:
            raise ValueError("Circuito no encontrado")
        district_id,name = _validate_circuit(cursor,data,item_id)
        eas_ids = [int(x) for x in (data.get("easIds") or []) if int(x) > 0] if district_id == ESTACION_DISTRICT_ID else []
        cursor.execute(
            """UPDATE dbo.circuitos SET distrito_id=?,nombre=?,hora_inicio=?,hora_fin=?,lugar_formacion=?,
                   consignas=?,observaciones=?,perimetro=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
            district_id,name,data.get("horaInicio") or None,data.get("horaFin") or None,data.get("lugarFormacion") or None,
            data.get("consignas") or None,data.get("observaciones") or None,data.get("perimetro") or None,item_id,
        )
        _sync_circuito_eas(cursor, item_id, eas_ids)
        _replace_circuit_routes(cursor,item_id,district_id,data.get("rutaIds") or [])


def replace_circuit_routes(item_id: int, route_ids: list) -> None:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("SELECT distrito_id FROM dbo.circuitos WHERE id=? AND deleted_at IS NULL",item_id)
        row=cursor.fetchone()
        if row is None:
            raise ValueError("Circuito no encontrado")
        _replace_circuit_routes(cursor,item_id,int(row[0]),route_ids)


def delete_circuit(item_id: int) -> None:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("DELETE FROM dbo.circuito_eas WHERE circuito_id=?",item_id)
        cursor.execute("UPDATE dbo.circuito_rutas SET deleted_at=SYSDATETIME() WHERE circuito_id=? AND deleted_at IS NULL",item_id)
        cursor.execute("UPDATE dbo.circuitos SET activo=0,deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME() WHERE id=? AND deleted_at IS NULL",item_id)
        if cursor.rowcount != 1:
            raise ValueError("Circuito no encontrado")


def list_catalogs_admin() -> list[dict]:
    return _query(
        """
        SELECT c.id, c.codigo, c.nombre, c.descripcion, c.estado,
               COUNT(d.id) AS total_detalles,
               SUM(CASE WHEN d.estado=1 THEN 1 ELSE 0 END) AS detalles_activos
        FROM dbo.catalogos c
        LEFT JOIN dbo.catalogo_detalles d ON d.catalogo_id=c.id
        GROUP BY c.id,c.codigo,c.nombre,c.descripcion,c.estado
        ORDER BY c.nombre
        """
    )


def list_catalog_details(codigo: str) -> list[dict]:
    return _query(
        """
        SELECT d.id,d.catalogo_id,c.codigo AS catalogo_codigo,c.nombre AS catalogo,
               d.codigo,d.nombre,d.descripcion,d.orden,d.asignar_encargado,d.estado
        FROM dbo.catalogo_detalles d
        INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
        WHERE c.codigo=?
        ORDER BY d.orden,d.nombre
        """, codigo
    )


def create_catalog_detail(codigo: str, data: dict) -> int:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("SELECT id FROM dbo.catalogos WHERE codigo=?", codigo)
        row=cursor.fetchone()
        if row is None:
            raise ValueError("Catálogo no encontrado")
        cursor.execute(
            """INSERT INTO dbo.catalogo_detalles(catalogo_id,codigo,nombre,descripcion,orden,estado,asignar_encargado,fecha_creacion)
               OUTPUT INSERTED.id VALUES(?,?,?,?,?,?,?,SYSDATETIME())""",
            row[0], data["codigo"], data["nombre"], data.get("descripcion"),
            int(data.get("orden",0)), 1 if data.get("estado",True) else 0,
            1 if codigo.upper() == "DISTRITOS" and data.get("asignarEncargado",False) else 0,
        )
        return int(cursor.fetchone()[0])


def update_catalog_detail(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute(
            """UPDATE dbo.catalogo_detalles SET codigo=?,nombre=?,descripcion=?,orden=?,estado=?,asignar_encargado=?,
               fecha_actualizacion=SYSDATETIME() WHERE id=?""",
            data["codigo"],data["nombre"],data.get("descripcion"),int(data.get("orden",0)),
            1 if data.get("estado",True) else 0,1 if data.get("asignarEncargado",False) else 0,item_id,
        )


def delete_catalog_detail(item_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        _cascade_delete(cursor, "catalogo_detalles", item_id)


def list_mobile_assignments() -> list[dict]:
    return _query(
        """
        SELECT a.id,a.eas_id,e.codigo AS eas_codigo,e.nombre AS eas_nombre,
               a.movil_id,m.numero_movil,m.placa,a.estado_asignacion_id,
               ed.nombre AS estado_asignacion,a.fecha_asignacion,a.observacion,a.activo
        FROM dbo.movil_eas_asignaciones a
        INNER JOIN dbo.eas_estaciones e ON e.id=a.eas_id
        INNER JOIN dbo.moviles m ON m.id=a.movil_id
        INNER JOIN dbo.catalogo_detalles ed ON ed.id=a.estado_asignacion_id
        ORDER BY a.activo DESC,a.fecha_asignacion DESC
        """
    )


def create_mobile_assignment(data: dict) -> int:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute("UPDATE dbo.movil_eas_asignaciones SET activo=0,fecha_actualizacion=SYSDATETIME() WHERE movil_id=? AND activo=1",data["movilId"])
        cursor.execute(
            """INSERT INTO dbo.movil_eas_asignaciones(eas_id,movil_id,fecha_asignacion,estado_asignacion_id,observacion,activo,fecha_creacion)
               OUTPUT INSERTED.id VALUES(?,?,SYSDATETIME(),?,?,1,SYSDATETIME())""",
            data["easId"],data["movilId"],data["estadoAsignacionId"],data.get("observacion"),
        )
        return int(cursor.fetchone()[0])


def update_mobile_assignment(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute(
            """UPDATE dbo.movil_eas_asignaciones SET eas_id=?,movil_id=?,estado_asignacion_id=?,
               observacion=?,activo=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
            data["easId"],data["movilId"],data["estadoAsignacionId"],data.get("observacion"),
            1 if data.get("activo",True) else 0,item_id,
        )


def delete_mobile_assignment(item_id: int) -> None:
    _soft_delete("movil_eas_asignaciones",item_id)


def list_mobile_maintenance(mobile_id: int | None = None) -> list[dict]:
    sql="""
        SELECT mm.id,mm.movil_id,m.numero_movil,mm.fecha_mantenimiento,mm.kilometraje,
               mm.descripcion,mm.tipo_mantenimiento_id,tm.nombre AS tipo_mantenimiento,mm.activo
        FROM dbo.movil_mantenimiento mm
        INNER JOIN dbo.moviles m ON m.id=mm.movil_id
        LEFT JOIN dbo.catalogo_detalles tm ON tm.id=mm.tipo_mantenimiento_id
        WHERE (? IS NULL OR mm.movil_id=?)
        ORDER BY mm.fecha_mantenimiento DESC
    """
    return _query(sql,mobile_id,mobile_id)


def create_mobile_maintenance(mobile_id: int, data: dict) -> int:
    with get_connection() as connection:
        cursor=connection.cursor()
        cursor.execute(
            """INSERT INTO dbo.movil_mantenimiento(movil_id,fecha_mantenimiento,kilometraje,descripcion,tipo_mantenimiento_id,activo,fecha_creacion)
               OUTPUT INSERTED.id VALUES(?,?,?,?,?,1,SYSDATETIME())""",
            mobile_id,data["fechaMantenimiento"],data["kilometraje"],data.get("descripcion"),data.get("tipoMantenimientoId"),
        )
        maintenance_id = int(cursor.fetchone()[0])
        cursor.execute("UPDATE dbo.moviles SET kilometraje_ultimo_mantenimiento=?,fecha_actualizacion=SYSDATETIME() WHERE id=?",data["kilometraje"],mobile_id)
        return maintenance_id


def create_grade(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.grados (nombre, activo, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (?, ?, SYSDATETIME())
            """,
            data["nombre"],
            1 if data.get("activo", True) else 0,
        )
        return int(cursor.fetchone()[0])


def update_grade(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.grados
            SET nombre = ?, activo = ?, fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
            """,
            data["nombre"],
            1 if data.get("activo", True) else 0,
            item_id,
        )


def delete_grade(item_id: int) -> None:
    _soft_delete("grados", item_id)


def create_route(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        turnos_ids = [int(t) for t in (data.get("turnosIds") or []) if t]
        if not turnos_ids and data.get("turnoId"):
            turnos_ids = [int(data["turnoId"])]
        if not turnos_ids:
            turnos_ids = [1]  # Default to Primer Turno
        cursor.execute(
            """
            INSERT INTO dbo.rutas (nombre, distrito_id, hora_inicio, hora_fin, asignar_encargado, activo, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data["nombre"],
            data.get("distritoId"), data.get("horaInicio"), data.get("horaFin"),
            1 if data.get("asignarEncargado",False) else 0,
            1 if data.get("activo", True) else 0,
        )
        route_id = int(cursor.fetchone()[0])
        _sync_route_turnos(cursor, route_id, turnos_ids)
        return route_id


def update_route(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        turnos_ids = [int(t) for t in (data.get("turnosIds") or []) if t]
        if not turnos_ids and data.get("turnoId"):
            turnos_ids = [int(data["turnoId"])]
        cursor.execute(
            """
            UPDATE dbo.rutas
            SET nombre = ?, distrito_id=?, hora_inicio=?, hora_fin=?, asignar_encargado=?, activo = ?, fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
            """,
            data["nombre"],
            data.get("distritoId"), data.get("horaInicio"), data.get("horaFin"),
            1 if data.get("asignarEncargado",False) else 0,
            1 if data.get("activo", True) else 0,
            item_id,
        )
        if turnos_ids:
            _sync_route_turnos(cursor, item_id, turnos_ids)


def _route_import_key(value) -> str:
    normalized = unicodedata.normalize("NFKD", str(value or "").strip())
    return " ".join("".join(char for char in normalized if not unicodedata.combining(char)).split()).casefold()


def _route_import_empty(value) -> str:
    text = str(value or "").strip()
    return "" if text == "..." else text


def _route_import_bool(value, default: bool) -> tuple[bool, bool]:
    text = _route_import_key(_route_import_empty(value))
    if not text:
        return default, True
    if text in {"si", "true", "1"}:
        return True, True
    if text in {"no", "false", "0"}:
        return False, True
    return default, False


def _attach_route_to_circuit(cursor, circuit_id: int, route_id: int) -> bool:
    cursor.execute(
        """SELECT cr.circuito_id,c.nombre FROM dbo.circuito_rutas cr
           INNER JOIN dbo.circuitos c ON c.id=cr.circuito_id
           WHERE cr.ruta_id=? AND cr.deleted_at IS NULL AND c.deleted_at IS NULL""",
        route_id,
    )
    current = cursor.fetchone()
    if current and int(current[0]) != circuit_id:
        raise ValueError(f"La ruta ya pertenece al circuito {current[1]}")
    if current:
        return False
    cursor.execute(
        """UPDATE dbo.circuito_rutas SET deleted_at=NULL,fecha_creacion=SYSDATETIME()
           WHERE id=(SELECT TOP 1 id FROM dbo.circuito_rutas WHERE circuito_id=? AND ruta_id=? ORDER BY id DESC)""",
        circuit_id, route_id,
    )
    if cursor.rowcount == 0:
        cursor.execute("INSERT INTO dbo.circuito_rutas(circuito_id,ruta_id) VALUES(?,?)", circuit_id, route_id)
    return True


def import_routes(rows: list[dict], confirm: bool = False, existing_actions: dict | None = None, circuit_id: int | None = None) -> dict:
    if not isinstance(rows, list) or not rows:
        raise ValueError("El archivo CSV no contiene registros")
    if len(rows) > 2000:
        raise ValueError("El archivo CSV no puede contener más de 2000 registros")
    existing_actions = {str(key): str(value).upper() for key, value in (existing_actions or {}).items()}

    with get_connection() as connection:
        cursor = connection.cursor()
        circuit = None
        circuit_id = int(circuit_id or 0)
        if circuit_id:
            cursor.execute("SELECT id,nombre,distrito_id FROM dbo.circuitos WHERE id=? AND activo=1 AND deleted_at IS NULL", circuit_id)
            circuit_row = cursor.fetchone()
            if circuit_row is None:
                raise ValueError("Circuito no encontrado")
            circuit = {"id":int(circuit_row[0]),"nombre":str(circuit_row[1]),"distrito_id":int(circuit_row[2])}
        cursor.execute("""SELECT d.id,d.nombre FROM dbo.catalogo_detalles d
                          INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
                          WHERE c.codigo='DISTRITOS' AND c.estado=1 AND d.estado=1""")
        districts: dict[str, list[tuple[int, str]]] = {}
        for item_id, name in cursor.fetchall():
            districts.setdefault(_route_import_key(name), []).append((int(item_id), str(name)))
        cursor.execute("SELECT id,nombre FROM dbo.turnos WHERE activo=1")
        shifts: dict[str, list[tuple[int, str]]] = {}
        for item_id, name in cursor.fetchall():
            shifts.setdefault(_route_import_key(name), []).append((int(item_id), str(name)))
        lock_hint = " WITH (UPDLOCK, HOLDLOCK)" if confirm else ""
        cursor.execute(f"SELECT id,nombre,distrito_id FROM dbo.rutas{lock_hint}")
        existing: dict[tuple[str, int], tuple[int, str]] = {}
        for item_id, name, district_id in cursor.fetchall():
            existing[(_route_import_key(name), int(district_id or 0))] = (int(item_id), str(name))
        cursor.execute(
            """SELECT cr.ruta_id,cr.circuito_id,c.nombre FROM dbo.circuito_rutas cr
               INNER JOIN dbo.circuitos c ON c.id=cr.circuito_id
               WHERE cr.deleted_at IS NULL AND c.deleted_at IS NULL"""
        )
        route_circuits = {int(route_id):(int(owner_id),str(owner_name)) for route_id,owner_id,owner_name in cursor.fetchall()}

        reviewed: list[dict] = []
        payloads: list[dict] = []
        file_keys: set[tuple[str, int, int]] = set()
        for index, raw in enumerate(rows):
            row = raw if isinstance(raw, dict) else {}
            row_number = int(row.get("fila") or index + 2)
            name = _route_import_empty(row.get("nombre"))
            district_name = _route_import_empty(row.get("distrito"))
            # Support both single 'turno' and multi 'turnos_habilitados' columns
            turnos_raw = _route_import_empty(row.get("turnos_habilitados")) or _route_import_empty(row.get("turno"))
            start_time = _route_import_empty(row.get("hora_inicio"))
            end_time = _route_import_empty(row.get("hora_fin"))
            manager, manager_valid = _route_import_bool(row.get("asignar_encargado"), False)
            active, active_valid = _route_import_bool(row.get("activa"), True)
            errors: list[str] = []
            if row.get("_parse_error"):
                errors.append(str(row["_parse_error"]))
            district_matches = districts.get(_route_import_key(district_name), [])
            district = district_matches[0] if len(district_matches) == 1 else None
            # Parse multiple turns from pipe-separated string
            turnos_resolved: list[tuple[int, str]] = []
            if turnos_raw:
                for part in turnos_raw.split("|"):
                    part = part.strip()
                    if not part:
                        continue
                    matches = shifts.get(_route_import_key(part), [])
                    if len(matches) == 1:
                        turnos_resolved.append(matches[0])
                    elif len(matches) > 1:
                        errors.append(f"Turno ambiguo: {part}")
                    else:
                        errors.append(f"Turno no válido: {part}")
            if not name:
                errors.append("Nombre obligatorio")
            if not district_name:
                errors.append("Distrito obligatorio")
            elif not district_matches:
                errors.append("Distrito no encontrado")
            elif len(district_matches) > 1:
                errors.append("Distrito ambiguo")
            if not turnos_raw:
                errors.append("Turno(s) obligatorio(s)")
            elif not turnos_resolved and not errors:
                errors.append("Ningún turno válido encontrado")
            time_pattern = re.compile(r"^(?:[01]\d|2[0-3]):[0-5]\d$")
            if start_time and not time_pattern.fullmatch(start_time):
                errors.append("Hora de inicio inválida")
            if end_time and not time_pattern.fullmatch(end_time):
                errors.append("Hora de fin inválida")
            if not manager_valid:
                errors.append("Asignar encargado debe ser SI o NO")
            if not active_valid:
                errors.append("Activa debe ser SI o NO")
            if circuit and district and int(district[0]) != circuit["distrito_id"]:
                errors.append("El distrito de la ruta no coincide con el distrito del circuito")

            duplicate_key = None
            existing_route = None
            if name and district and turnos_resolved:
                duplicate_key = (_route_import_key(name), district[0])
                existing_route = existing.get(duplicate_key)
                owner = route_circuits.get(int(existing_route[0])) if existing_route else None
                if circuit and owner and owner[0] != circuit_id:
                    errors.append(f"La ruta ya pertenece al circuito {owner[1]}")
                if duplicate_key in file_keys:
                    errors.append("Ruta duplicada dentro del archivo CSV")
                else:
                    file_keys.add(duplicate_key)
            status = "ERROR" if errors else ("EXISTENTE" if existing_route else "VALIDA")
            normalized = None
            if not errors and district and turnos_resolved:
                normalized = {
                    "fila": row_number, "nombre": name, "distritoId": district[0],
                    "turnosIds": [t[0] for t in turnos_resolved],
                    "horaInicio": start_time or None, "horaFin": end_time or None,
                    "asignarEncargado": manager, "activo": active,
                    "existenteId": existing_route[0] if existing_route else None,
                }
                payloads.append(normalized)
            turnos_str = " | ".join(t[1] for t in turnos_resolved) if turnos_resolved else "..."
            reviewed.append({
                "fila": row_number, "nombre": name or "...", "distrito": district_name or "...",
                "turno": turnos_str, "hora_inicio": start_time or "...", "hora_fin": end_time or "...",
                "asignar_encargado": manager, "activa": active, "estado": status,
                "valida": not errors, "existente_id": existing_route[0] if existing_route else None,
                "errores": errors or (["Ruta existente"] if existing_route else []),
            })

        created = updated = omitted = linked = 0
        if confirm:
            for data in payloads:
                existing_id = data.pop("existenteId")
                if existing_id:
                    action = existing_actions.get(str(data["fila"]), "VINCULAR" if circuit else "OMITIR")
                    if action == "OMITIR":
                        omitted += 1
                        continue
                    if action == "ACTUALIZAR":
                        cursor.execute("""UPDATE dbo.rutas SET nombre=?,distrito_id=?,hora_inicio=?,hora_fin=?,
                                          asignar_encargado=?,activo=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
                                       data["nombre"],data["distritoId"],data["horaInicio"],data["horaFin"],
                                       1 if data["asignarEncargado"] else 0,1 if data["activo"] else 0,existing_id)
                        _sync_route_turnos(cursor, existing_id, data["turnosIds"])
                        updated += 1
                    if circuit and _attach_route_to_circuit(cursor,circuit_id,int(existing_id)):
                        linked += 1
                else:
                    cursor.execute("""INSERT INTO dbo.rutas
                                      (nombre,distrito_id,hora_inicio,hora_fin,asignar_encargado,activo,fecha_creacion)
                                      OUTPUT INSERTED.id VALUES (?,?,?,?,?,?,SYSDATETIME())""",
                                   data["nombre"],data["distritoId"],data["horaInicio"],data["horaFin"],
                                   1 if data["asignarEncargado"] else 0,1 if data["activo"] else 0)
                    new_route_id = int(cursor.fetchone()[0])
                    _sync_route_turnos(cursor, new_route_id, data["turnosIds"])
                    created += 1
                    if circuit and _attach_route_to_circuit(cursor,circuit_id,new_route_id):
                        linked += 1
        valid_count = sum(1 for item in reviewed if item["estado"] == "VALIDA")
        existing_count = sum(1 for item in reviewed if item["estado"] == "EXISTENTE")
        error_count = sum(1 for item in reviewed if item["estado"] == "ERROR")
        return {"filas": reviewed, "total": len(reviewed), "validos": valid_count,
                "existentes": existing_count, "rechazados": error_count,
                "creados": created, "actualizados": updated, "omitidos": omitted + error_count,
                "vinculados": linked, "circuito": circuit}


def delete_route(item_id: int) -> None:
    _soft_delete("rutas", item_id)


def create_eas(data: dict) -> int:
    table = _eas_table()
    with get_connection() as connection:
        cursor = connection.cursor()
        if table == "eas":
            cursor.execute(
                """
                INSERT INTO dbo.eas (codigo, nombre, direccion, activo)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, ?)
                """,
                data["codigo"],
                data["nombre"],
                data["direccion"],
                1 if data.get("activo", True) else 0,
            )
        else:
            cursor.execute(
                """
                INSERT INTO dbo.eas_estaciones (codigo, nombre, direccion, ubicacion, activo, distrito_id, fecha_creacion)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, ?, ?, ?, SYSDATETIME())
                """,
                data["codigo"],
                data["nombre"],
                data["direccion"],
                data.get("ubicacion"),
                1 if data.get("activo", True) else 0,
                data.get("distritoId"),
            )
        return int(cursor.fetchone()[0])


def update_eas(item_id: int, data: dict) -> None:
    table = _eas_table()
    with get_connection() as connection:
        cursor = connection.cursor()
        if table == "eas":
            cursor.execute(
                """
                UPDATE dbo.eas
                SET codigo = ?, nombre = ?, direccion = ?, activo = ?
                WHERE id = ?
                """,
                data["codigo"],
                data["nombre"],
                data["direccion"],
                1 if data.get("activo", True) else 0,
                item_id,
            )
        else:
            cursor.execute(
                """
                UPDATE dbo.eas_estaciones
                SET codigo = ?, nombre = ?, direccion = ?, ubicacion = ?, activo = ?,
                    distrito_id = ?, fecha_actualizacion = SYSDATETIME()
                WHERE id = ?
                """,
                data["codigo"],
                data["nombre"],
                data["direccion"],
                data.get("ubicacion"),
                1 if data.get("activo", True) else 0,
                data.get("distritoId"),
                item_id,
            )


def delete_eas(item_id: int) -> None:
    _soft_delete(_eas_table(), item_id)


def create_mobile_unit(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.moviles (
                numero_movil, placa, tipo_movil_id, kilometraje_actual,
                kilometraje_ultimo_mantenimiento, proximo_mantenimiento,
                estado_movil_id, observacion, activo, fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data["numeroMovil"],
            data.get("placa"),
            data["tipoMovilId"],
            data.get("kilometrajeActual", 0),
            data.get("kilometrajeUltimoMantenimiento", 0),
            data.get("proximoMantenimiento"),
            data["estadoMovilId"],
            data.get("observacion"),
            1 if data.get("activo", True) else 0,
        )
        return int(cursor.fetchone()[0])


def update_mobile_unit(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.moviles
            SET numero_movil = ?, placa = ?, tipo_movil_id = ?, kilometraje_actual = ?,
                kilometraje_ultimo_mantenimiento = ?, proximo_mantenimiento = ?,
                estado_movil_id = ?, observacion = ?, activo = ?, fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
            """,
            data["numeroMovil"],
            data.get("placa"),
            data["tipoMovilId"],
            data.get("kilometrajeActual", 0),
            data.get("kilometrajeUltimoMantenimiento", 0),
            data.get("proximoMantenimiento"),
            data["estadoMovilId"],
            data.get("observacion"),
            1 if data.get("activo", True) else 0,
            item_id,
        )


def delete_mobile_unit(item_id: int) -> None:
    _soft_delete("moviles", item_id)


def _sync_route_turnos(cursor, route_id: int, turnos_ids: list[int]) -> None:
    """Sync junction table for route turns. turnos_ids must have at least 1 entry."""
    cursor.execute("DELETE FROM dbo.ruta_turnos WHERE ruta_id = ?", route_id)
    for turno_id in turnos_ids:
        cursor.execute(
            "INSERT INTO dbo.ruta_turnos (ruta_id, turno_id) VALUES (?, ?)",
            route_id, turno_id,
        )


def _sync_lugar_turnos(cursor, lugar_id: int, turnos_ids: list[int]) -> None:
    """Sync junction table for place turns. turnos_ids must have at least 1 entry."""
    cursor.execute("DELETE FROM dbo.lugar_turnos WHERE lugar_servicio_id = ?", lugar_id)
    for turno_id in turnos_ids:
        cursor.execute(
            "INSERT INTO dbo.lugar_turnos (lugar_servicio_id, turno_id) VALUES (?, ?)",
            lugar_id, turno_id,
        )


def get_route_turnos(cursor, ruta_id: int) -> list[int]:
    """Get enabled turn IDs for a route."""
    cursor.execute(
        "SELECT turno_id FROM dbo.ruta_turnos WHERE ruta_id = ? ORDER BY turno_id",
        ruta_id,
    )
    return [int(row[0]) for row in cursor.fetchall()]


def create_service_place(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        turnos_ids = [int(t) for t in (data.get("turnosIds") or []) if t]
        if not turnos_ids:
            # Fallback: inherit from route
            rt = get_route_turnos(cursor, int(data["rutaId"]))
            turnos_ids = rt if rt else [1]
        cursor.execute(
            """
            INSERT INTO dbo.lugares_servicio (
                nombre,direccion,ubicacion_especifica,distrito_id,ruta_id,tipo_servicio_id,
                cantidad_requerida,estado_operativo,
                consignas,observacion,lugar_formacion,latitud,longitud,activo,fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("lugarFormacion"),data.get("latitud"),data.get("longitud"),
            1 if data.get("activo", True) else 0,
        )
        lugar_id = int(cursor.fetchone()[0])
        _sync_lugar_turnos(cursor, lugar_id, turnos_ids)
        return lugar_id


def update_service_place(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        turnos_ids = [int(t) for t in (data.get("turnosIds") or []) if t]
        if not turnos_ids:
            rt = get_route_turnos(cursor, int(data["rutaId"]))
            turnos_ids = rt if rt else [1]
        cursor.execute(
            """
            UPDATE dbo.lugares_servicio
            SET nombre=?,direccion=?,ubicacion_especifica=?,distrito_id=?,ruta_id=?,tipo_servicio_id=?,
                cantidad_requerida=?,estado_operativo=?,
                consignas=?,observacion=?,lugar_formacion=?,latitud=?,longitud=?,activo=?,fecha_actualizacion=SYSDATETIME()
            WHERE id = ?
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("lugarFormacion"),data.get("latitud"),data.get("longitud"),
            1 if data.get("activo", True) else 0,
            item_id,
        )
        _sync_lugar_turnos(cursor, item_id, turnos_ids)


def delete_service_place(item_id: int) -> None:
    _soft_delete("lugares_servicio", item_id)


def delete_service_places_by_scope(route_id: int | None = None, circuit_id: int | None = None) -> int:
    route_id = int(route_id or 0)
    circuit_id = int(circuit_id or 0)
    if bool(route_id) == bool(circuit_id):
        raise ValueError("Seleccione una ruta o un circuito, pero no ambos")

    with get_connection() as connection:
        cursor = connection.cursor()
        if route_id:
            cursor.execute("SELECT id FROM dbo.rutas WHERE id=?", route_id)
            if cursor.fetchone() is None:
                raise ValueError("La ruta seleccionada no existe")
            cursor.execute("SELECT id FROM dbo.lugares_servicio WHERE ruta_id=? ORDER BY id", route_id)
        else:
            cursor.execute("SELECT id FROM dbo.circuitos WHERE id=? AND deleted_at IS NULL", circuit_id)
            if cursor.fetchone() is None:
                raise ValueError("El circuito seleccionado no existe")
            cursor.execute(
                """SELECT DISTINCT l.id FROM dbo.lugares_servicio l
                   INNER JOIN dbo.circuito_rutas cr ON cr.ruta_id=l.ruta_id
                   WHERE cr.circuito_id=? AND cr.deleted_at IS NULL ORDER BY l.id""",
                circuit_id,
            )

        place_ids = [int(row[0]) for row in cursor.fetchall()]
        for place_id in place_ids:
            _cascade_delete(cursor, "lugares_servicio", place_id, set())
        return len(place_ids)


def _import_key(value) -> str:
    return " ".join(str(value or "").strip().split()).casefold()


def _csv_empty(value) -> bool:
    """Return True if value is empty, None, or '...'."""
    v = str(value or "").strip()
    return v == "" or v == "..."


def _csv_clean(value) -> str | None:
    """Return trimmed value, or None if empty / '...'."""
    v = str(value or "").strip()
    if v == "" or v == "...":
        return None
    return v


def import_service_places(rows: list[dict], confirm: bool = False, existing_actions: dict | None = None) -> dict:
    if not isinstance(rows, list) or not rows:
        raise ValueError("El archivo CSV no contiene registros")
    if len(rows) > 2000:
        raise ValueError("El archivo CSV no puede contener más de 2000 registros")
    existing_actions = {str(key): str(value).upper() for key, value in (existing_actions or {}).items()}

    with get_connection() as connection:
        cursor = connection.cursor()

        cursor.execute("SELECT id,nombre,distrito_id FROM dbo.rutas")
        routes: dict[str, list[tuple[int, str, int, list[int]]]] = {}
        for item_id, name, district_id in cursor.fetchall():
            route_turns = get_route_turnos(cursor, int(item_id))
            routes.setdefault(_import_key(name), []).append(
                (int(item_id), str(name), int(district_id or 0), route_turns)
            )

        cursor.execute(
            """SELECT d.id,d.nombre FROM dbo.catalogo_detalles d
               INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
               WHERE c.codigo='TIPOS_SERVICIO_LUGAR' AND d.estado=1"""
        )
        service_types: dict[str, tuple[int, str]] = {
            _import_key(name): (int(item_id), str(name))
            for item_id, name in cursor.fetchall()
        }

        lock_hint = " WITH (UPDLOCK, HOLDLOCK)" if confirm else ""
        cursor.execute(f"SELECT id,ruta_id,nombre FROM dbo.lugares_servicio{lock_hint}")
        existing = {
            (int(route_id or 0), _import_key(name)): int(item_id)
            for item_id, route_id, name in cursor.fetchall()
        }

        reviewed: list[dict] = []
        file_keys: set[tuple[int, str]] = set()
        payloads: list[dict] = []
        ruta_no_encontradas: set[str] = set()

        for index, raw in enumerate(rows):
            row = raw if isinstance(raw, dict) else {}
            row_number = int(row.get("fila") or index + 2)
            route_name = str(row.get("ruta") or "").strip()
            place_name = str(row.get("lugar_servicio") or "")
            horario = str(row.get("horario") or "").strip()
            lugar_formacion = str(row.get("lugar_formacion") or "").strip()
            consignas = str(row.get("consignas") or "").strip()
            observacion = str(row.get("observacion") or "").strip()
            service_type_name = str(row.get("tipo_servicio") or "").strip()
            errors: list[str] = []
            warnings: list[str] = []
            duplicate_type = None
            existing_id = None
            if row.get("_parse_error"):
                errors.append(str(row["_parse_error"]))

            if _csv_empty(route_name):
                errors.append("Ruta es obligatoria")
            elif _import_key(route_name) not in routes:
                errors.append("Ruta no encontrada")
                ruta_no_encontradas.add(_import_key(route_name))

            if _csv_empty(place_name):
                errors.append("Lugar de servicio es obligatorio")

            service_type_match = None
            if not _csv_empty(service_type_name):
                service_type_match = service_types.get(_import_key(service_type_name))
                if service_type_match is None:
                    errors.append("Tipo de servicio no encontrado")

            route_match = None
            if not _csv_empty(route_name) and _import_key(route_name) in routes:
                candidates = routes[_import_key(route_name)]
                if len(candidates) == 1:
                    route_match = candidates[0]
                    if route_match[2] <= 0:
                        errors.append(f"La ruta '{route_name}' no tiene un distrito asignado")
                else:
                    errors.append(f"La ruta '{route_name}' es ambigua en el sistema")

            dup_key = None
            if route_match and not _csv_empty(place_name):
                dup_key = (route_match[0], _import_key(place_name))
                if dup_key in existing:
                    duplicate_type = "BASE_DATOS"
                    existing_id = existing[dup_key]
                    warnings.append("Lugar de servicio ya registrado en esta ruta.")
                elif dup_key in file_keys:
                    duplicate_type = "ARCHIVO"
                    warnings.append("Lugar repetido dentro del archivo CSV")
                else:
                    file_keys.add(dup_key)

            # Parse turnos_habilitados column (pipe-separated), fallback to route's turns
            turnos_raw = str(row.get("turnos_habilitados") or "").strip()
            turnos_ids_for_place: list[int] = []
            if turnos_raw and route_match:
                # Resolve turns against available shifts
                cursor.execute("SELECT id,nombre FROM dbo.turnos WHERE activo=1")
                all_shifts = {_import_key(name): int(sid) for sid, name in cursor.fetchall()}
                for part in turnos_raw.split("|"):
                    part = part.strip()
                    if not part:
                        continue
                    tid = all_shifts.get(_import_key(part))
                    if tid and tid in route_match[3]:
                        turnos_ids_for_place.append(tid)
                    elif not tid:
                        errors.append(f"Turno no válido: {part}")
            # If no explicit turns, inherit all from route
            if not turnos_ids_for_place and route_match:
                turnos_ids_for_place = list(route_match[3])

            normalized = None
            if not errors and route_match and duplicate_type != "ARCHIVO":
                normalized = {
                    "fila": row_number,
                    "nombre": place_name,
                    "direccion": place_name,
                    "ubicacion_especifica": _csv_clean(horario),
                    "ruta_id": route_match[0],
                    "distrito_id": route_match[2],
                    "turnosIds": turnos_ids_for_place,
                    "consignas": _csv_clean(consignas),
                    "observacion": _csv_clean(observacion),
                    "lugar_formacion": _csv_clean(lugar_formacion),
                    "tipo_servicio_id": service_type_match[0] if service_type_match else None,
                    "activo": True,
                    "existente_id": existing_id,
                }
                payloads.append(normalized)

            reviewed.append({
                "fila": row_number,
                "ruta": route_name,
                "lugar_servicio": place_name,
                "horario": horario,
                "lugar_formacion": lugar_formacion,
                "consignas": consignas,
                "observacion": observacion,
                "tipo_servicio": service_type_name,
                "valida": not errors,
                "duplicado": duplicate_type is not None,
                "tipo_duplicado": duplicate_type,
                "existente_id": existing_id,
                "errores": errors + warnings,
            })

        imported = updated = omitted_existing = 0
        if confirm:
            for data in payloads:
                if data["existente_id"]:
                    action = existing_actions.get(str(data["fila"]), "OMITIR")
                    if action != "ACTUALIZAR":
                        omitted_existing += 1
                        continue
                    cursor.execute(
                        """UPDATE dbo.lugares_servicio
                           SET ubicacion_especifica=?,consignas=?,observacion=?,lugar_formacion=?,
                               tipo_servicio_id=?,activo=1,fecha_actualizacion=SYSDATETIME()
                           WHERE id=?""",
                        data["ubicacion_especifica"], data["consignas"], data["observacion"],
                        data["lugar_formacion"], data["tipo_servicio_id"], data["existente_id"],
                    )
                    updated += 1
                else:
                    cursor.execute(
                        """INSERT INTO dbo.lugares_servicio (
                               ruta_id,nombre,direccion,ubicacion_especifica,distrito_id,
                               consignas,observacion,lugar_formacion,estado_operativo,cantidad_requerida,
                               activo,fecha_creacion,tipo_servicio_id,latitud,longitud
                           )
                        OUTPUT INSERTED.id
                        VALUES (?,?,?,?,?,?,?,?,'ACTIVO',1,1,SYSDATETIME(),?,NULL,NULL)""",
                        data["ruta_id"], data["nombre"], data["direccion"], data["ubicacion_especifica"],
                        data["distrito_id"], data["consignas"], data["observacion"],
                        data["lugar_formacion"], data["tipo_servicio_id"],
                    )
                    new_place_id = int(cursor.fetchone()[0])
                    _sync_lugar_turnos(cursor, new_place_id, data["turnosIds"])
                    imported += 1

        valid_count = sum(1 for row in reviewed if row["valida"] and not row["duplicado"])
        existing_count = sum(1 for row in reviewed if row["tipo_duplicado"] == "BASE_DATOS")
        file_duplicate_count = sum(1 for row in reviewed if row["tipo_duplicado"] == "ARCHIVO")
        error_count = sum(1 for row in reviewed if not row["valida"])
        return {
            "filas": reviewed,
            "total": len(reviewed),
            "validos": valid_count,
            "duplicados": existing_count + file_duplicate_count,
            "existentes": existing_count,
            "duplicados_archivo": file_duplicate_count,
            "rechazados": error_count,
            "rutas_encontradas": len(reviewed) - len(ruta_no_encontradas),
            "rutas_no_encontradas": len(ruta_no_encontradas),
            "importados": imported,
            "actualizados": updated,
            "omitidos": omitted_existing + file_duplicate_count + error_count,
        }


_fk_cache: dict[str, list[tuple[str, str]]] | None = None


def _child_map(cursor) -> dict[str, list[tuple[str, str]]]:
    """child_table -> [(parent_col, child_col)] construido desde las FK reales del esquema."""
    global _fk_cache
    if _fk_cache is not None:
        return _fk_cache
    cursor.execute(
        """
        SELECT t2.name AS parent, c1.name AS child_col, t1.name AS child_table
        FROM sys.foreign_keys fk
        JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
        JOIN sys.tables t1 ON t1.object_id = fk.parent_object_id
        JOIN sys.columns c1 ON c1.object_id = t1.object_id AND c1.column_id = fkc.parent_column_id
        JOIN sys.columns c2 ON c2.object_id = fk.referenced_object_id AND c2.column_id = fkc.referenced_column_id
        JOIN sys.tables t2 ON t2.object_id = fk.referenced_object_id
        """
    )
    result: dict[str, list[tuple[str, str]]] = {}
    for table, col, child in cursor.fetchall():
        key = (child, col)
        result.setdefault(table, []).append(key)
    _fk_cache = result
    return result


def _soft_delete(table_name: str, item_id: int) -> None:
    if table_name not in {"eas", "eas_estaciones", "moviles", "rutas", "lugares_servicio", "grados", "movil_eas_asignaciones"}:
        raise ValueError("Tabla no permitida")
    with get_connection() as connection:
        cursor = connection.cursor()
        _cascade_delete(cursor, table_name, item_id, set())


def _cascade_delete(cursor, table_name: str, item_id: int, stack: set) -> None:
    if (table_name, item_id) in stack:
        return
    stack.add((table_name, item_id))
    for child, column in _child_map(cursor).get(table_name, []):
        cursor.execute(f"SELECT id FROM dbo.{child} WHERE {column} = ?", item_id)
        child_ids = [row[0] for row in cursor.fetchall()]
        for child_id in child_ids:
            _cascade_delete(cursor, child, child_id, stack)
    cursor.execute(f"DELETE FROM dbo.{table_name} WHERE id = ?", item_id)


def _eas_table() -> str:
    with get_connection() as connection:
        return "eas" if _table_exists(connection, "eas") else "eas_estaciones"
