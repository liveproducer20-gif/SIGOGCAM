import pyodbc

from app.core.db import get_connection


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
    return _query(
        """
        SELECT r.id, r.nombre, r.distrito_id, d.nombre AS distrito, r.turno_id,
               t.nombre AS turno, CONVERT(VARCHAR(5),r.hora_inicio,108) AS hora_inicio,
               CONVERT(VARCHAR(5),r.hora_fin,108) AS hora_fin, r.asignar_encargado, r.activo
        FROM dbo.rutas r
        LEFT JOIN dbo.catalogo_detalles d ON d.id=r.distrito_id
        LEFT JOIN dbo.turnos t ON t.id=r.turno_id
        ORDER BY r.nombre
        """
    )


def list_service_places() -> list[dict]:
    return _query(
        """
        SELECT l.id, l.nombre, l.direccion, l.ubicacion_especifica, l.distrito_id,
               d.nombre AS distrito, l.ruta_id, r.nombre AS ruta,
               l.tipo_servicio_id, ts.nombre AS tipo_servicio,
               l.turno_id, t.nombre AS turno,
               l.cantidad_requerida, l.estado_operativo, l.consignas, l.observacion, l.lugar_formacion,
               l.latitud, l.longitud, ISNULL(r.asignar_encargado,0) AS ruta_asignar_encargado, l.activo
        FROM dbo.lugares_servicio l
        LEFT JOIN dbo.catalogo_detalles d ON d.id=l.distrito_id
        LEFT JOIN dbo.rutas r ON r.id=l.ruta_id
        LEFT JOIN dbo.catalogo_detalles ts ON ts.id=l.tipo_servicio_id
        LEFT JOIN dbo.turnos t ON t.id=l.turno_id
        ORDER BY COALESCE(l.nombre,l.direccion)
        """
    )


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
        "personal": _query(
            """SELECT p.id, p.cedula, LTRIM(RTRIM(CONCAT(p.apellidos, ' ', p.nombres))) AS nombre
               FROM dbo.personal p WHERE p.activo=1 ORDER BY p.apellidos,p.nombres"""
        ),
        "moviles": _query(
            """SELECT id, LTRIM(RTRIM(CONCAT(numero_movil,
                       CASE WHEN placa IS NULL OR LTRIM(RTRIM(placa))='' THEN '' ELSE ' · '+placa END))) AS nombre
               FROM dbo.moviles WHERE activo=1 ORDER BY numero_movil"""
        ),
        "rutas": _query(
            "SELECT id,nombre,distrito_id FROM dbo.rutas WHERE activo=1 AND distrito_id IS NOT NULL ORDER BY nombre"
        ),
    }


def list_circuits(district_id: int | None = None, search: str | None = None) -> list[dict]:
    term = (search or "").strip()
    rows = _query(
        """
        SELECT c.id,c.distrito_id,d.nombre AS distrito,c.nombre,c.encargado_id,
               LTRIM(RTRIM(CONCAT(pe.apellidos,' ',pe.nombres))) AS encargado,
               c.usar_encargado_distrito,c.auxiliar_1_id,
               LTRIM(RTRIM(CONCAT(p1.apellidos,' ',p1.nombres))) AS auxiliar_1,
               c.auxiliar_2_id,LTRIM(RTRIM(CONCAT(p2.apellidos,' ',p2.nombres))) AS auxiliar_2,
               c.movil_id,LTRIM(RTRIM(CONCAT(m.numero_movil,
                   CASE WHEN m.placa IS NULL OR LTRIM(RTRIM(m.placa))='' THEN '' ELSE ' · '+m.placa END))) AS movil,
               CONVERT(VARCHAR(5),c.hora_inicio,108) AS hora_inicio,
               CONVERT(VARCHAR(5),c.hora_fin,108) AS hora_fin,
               c.lugar_formacion,c.consignas,c.observaciones,c.perimetro,c.activo,
               ISNULL(ra.total_rutas,0) AS total_rutas,ra.ruta_ids,ra.rutas
        FROM dbo.circuitos c
        INNER JOIN dbo.catalogo_detalles d ON d.id=c.distrito_id
        INNER JOIN dbo.personal pe ON pe.id=c.encargado_id
        LEFT JOIN dbo.personal p1 ON p1.id=c.auxiliar_1_id
        LEFT JOIN dbo.personal p2 ON p2.id=c.auxiliar_2_id
        LEFT JOIN dbo.moviles m ON m.id=c.movil_id
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
          AND (?='' OR c.nombre LIKE '%'+?+'%' OR d.nombre LIKE '%'+?+'%'
               OR pe.nombres LIKE '%'+?+'%' OR pe.apellidos LIKE '%'+?+'%')
        ORDER BY d.nombre,c.nombre
        """,
        district_id,district_id,term,term,term,term,term,
    )
    for row in rows:
        row["ruta_ids"] = [int(value) for value in (row.get("ruta_ids") or "").split(",") if value]
    return rows


def get_circuit(item_id: int) -> dict:
    rows = list_circuits()
    for row in rows:
        if int(row["id"]) == item_id:
            return row
    raise ValueError("Circuito no encontrado")


def _nullable_person_id(value) -> int | None:
    if value in (None, "", 0, "0"):
        return None
    return int(value)


def _validate_circuit(cursor, data: dict, item_id: int | None = None) -> tuple:
    district_id = int(data.get("distritoId") or 0)
    manager_id = int(data.get("encargadoId") or 0)
    assistant_1 = _nullable_person_id(data.get("auxiliar1Id"))
    assistant_2 = _nullable_person_id(data.get("auxiliar2Id"))
    mobile_id = _nullable_person_id(data.get("movilId"))
    name = str(data.get("nombre") or "").strip()
    if not district_id or not manager_id or not name:
        raise ValueError("Distrito, nombre y encargado son obligatorios")
    people = [manager_id] + [value for value in (assistant_1,assistant_2) if value is not None]
    if len(people) != len(set(people)):
        raise ValueError("El encargado y los auxiliares deben ser personas diferentes")
    cursor.execute(
        """SELECT COUNT(*) FROM dbo.catalogo_detalles d INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
           WHERE d.id=? AND d.estado=1 AND c.codigo='DISTRITOS'""", district_id,
    )
    if int(cursor.fetchone()[0]) != 1:
        raise ValueError("El distrito seleccionado no es válido")
    placeholders = ",".join("?" for _ in people)
    cursor.execute(f"SELECT COUNT(*) FROM dbo.personal WHERE activo=1 AND id IN ({placeholders})", *people)
    if int(cursor.fetchone()[0]) != len(people):
        raise ValueError("El encargado o uno de los auxiliares no está activo")
    if mobile_id is not None:
        cursor.execute("SELECT COUNT(*) FROM dbo.moviles WHERE id=? AND activo=1", mobile_id)
        if int(cursor.fetchone()[0]) != 1:
            raise ValueError("El móvil seleccionado no está activo")
    cursor.execute(
        "SELECT COUNT(*) FROM dbo.circuitos WHERE distrito_id=? AND nombre=? AND deleted_at IS NULL AND (? IS NULL OR id<>?)",
        district_id,name,item_id,item_id,
    )
    if int(cursor.fetchone()[0]):
        raise ValueError("Ya existe un circuito con ese nombre en el distrito")
    return district_id,name,manager_id,assistant_1,assistant_2,mobile_id


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


def create_circuit(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        district_id,name,manager_id,assistant_1,assistant_2,mobile_id = _validate_circuit(cursor,data)
        cursor.execute(
            """INSERT INTO dbo.circuitos(
                   distrito_id,nombre,encargado_id,usar_encargado_distrito,auxiliar_1_id,auxiliar_2_id,
                   movil_id,hora_inicio,hora_fin,lugar_formacion,consignas,observaciones,perimetro,activo)
               OUTPUT INSERTED.id VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,1)""",
            district_id,name,manager_id,1 if data.get("usarEncargadoDistrito") else 0,assistant_1,assistant_2,
            mobile_id,data.get("horaInicio") or None,data.get("horaFin") or None,data.get("lugarFormacion") or None,
            data.get("consignas") or None,data.get("observaciones") or None,data.get("perimetro") or None,
        )
        circuit_id = int(cursor.fetchone()[0])
        _replace_circuit_routes(cursor,circuit_id,district_id,data.get("rutaIds") or [])
        return circuit_id


def update_circuit(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT COUNT(*) FROM dbo.circuitos WHERE id=? AND deleted_at IS NULL",item_id)
        if int(cursor.fetchone()[0]) != 1:
            raise ValueError("Circuito no encontrado")
        district_id,name,manager_id,assistant_1,assistant_2,mobile_id = _validate_circuit(cursor,data,item_id)
        cursor.execute(
            """UPDATE dbo.circuitos SET distrito_id=?,nombre=?,encargado_id=?,usar_encargado_distrito=?,
                   auxiliar_1_id=?,auxiliar_2_id=?,movil_id=?,hora_inicio=?,hora_fin=?,lugar_formacion=?,
                   consignas=?,observaciones=?,perimetro=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
            district_id,name,manager_id,1 if data.get("usarEncargadoDistrito") else 0,assistant_1,assistant_2,
            mobile_id,data.get("horaInicio") or None,data.get("horaFin") or None,data.get("lugarFormacion") or None,
            data.get("consignas") or None,data.get("observaciones") or None,data.get("perimetro") or None,item_id,
        )
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
        cursor.execute(
            """
            INSERT INTO dbo.rutas (nombre, distrito_id, turno_id, hora_inicio, hora_fin, asignar_encargado, activo, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data["nombre"],
            data.get("distritoId"), data.get("turnoId"), data.get("horaInicio"), data.get("horaFin"),
            1 if data.get("asignarEncargado",False) else 0,
            1 if data.get("activo", True) else 0,
        )
        return int(cursor.fetchone()[0])


def update_route(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.rutas
            SET nombre = ?, distrito_id=?, turno_id=?, hora_inicio=?, hora_fin=?, asignar_encargado=?, activo = ?, fecha_actualizacion = SYSDATETIME()
            WHERE id = ?
            """,
            data["nombre"],
            data.get("distritoId"), data.get("turnoId"), data.get("horaInicio"), data.get("horaFin"),
            1 if data.get("asignarEncargado",False) else 0,
            1 if data.get("activo", True) else 0,
            item_id,
        )


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


def create_service_place(data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            INSERT INTO dbo.lugares_servicio (
                nombre,direccion,ubicacion_especifica,distrito_id,ruta_id,tipo_servicio_id,turno_id,
                cantidad_requerida,estado_operativo,
                consignas,observacion,lugar_formacion,latitud,longitud,activo,fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),data.get("turnoId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("lugarFormacion"),data.get("latitud"),data.get("longitud"),
            1 if data.get("activo", True) else 0,
        )
        return int(cursor.fetchone()[0])


def update_service_place(item_id: int, data: dict) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            UPDATE dbo.lugares_servicio
            SET nombre=?,direccion=?,ubicacion_especifica=?,distrito_id=?,ruta_id=?,tipo_servicio_id=?,turno_id=?,
                cantidad_requerida=?,estado_operativo=?,
                consignas=?,observacion=?,lugar_formacion=?,latitud=?,longitud=?,activo=?,fecha_actualizacion=SYSDATETIME()
            WHERE id = ?
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),data.get("turnoId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("lugarFormacion"),data.get("latitud"),data.get("longitud"),
            1 if data.get("activo", True) else 0,
            item_id,
        )


def delete_service_place(item_id: int) -> None:
    _soft_delete("lugares_servicio", item_id)


def _import_key(value) -> str:
    return " ".join(str(value or "").strip().split()).casefold()


def import_service_places(rows: list[dict], confirm: bool = False) -> dict:
    if not isinstance(rows, list) or not rows:
        raise ValueError("El archivo CSV no contiene registros")
    if len(rows) > 2000:
        raise ValueError("El archivo CSV no puede contener más de 2000 registros")

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """SELECT d.id,d.nombre FROM dbo.catalogo_detalles d
               INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
               WHERE c.codigo='DISTRITOS' AND d.estado=1"""
        )
        districts: dict[str, list[tuple[int, str]]] = {}
        for item_id, name in cursor.fetchall():
            districts.setdefault(_import_key(name), []).append((int(item_id), str(name)))

        cursor.execute(
            """SELECT d.id,d.nombre FROM dbo.catalogo_detalles d
               INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id
               WHERE c.codigo='TIPOS_SERVICIO_LUGAR' AND d.estado=1"""
        )
        service_types: dict[str, list[tuple[int, str]]] = {}
        for item_id, name in cursor.fetchall():
            service_types.setdefault(_import_key(name), []).append((int(item_id), str(name)))

        cursor.execute("SELECT id,nombre,distrito_id,turno_id FROM dbo.rutas")
        routes: dict[str, list[tuple[int, str, int | None, int | None]]] = {}
        for item_id, name, district_id, shift_id in cursor.fetchall():
            routes.setdefault(_import_key(name), []).append(
                (int(item_id), str(name), int(district_id) if district_id is not None else None,
                 int(shift_id) if shift_id is not None else None)
            )

        lock_hint = " WITH (UPDLOCK, HOLDLOCK)" if confirm else ""
        cursor.execute(
            f"SELECT distrito_id,ruta_id,nombre FROM dbo.lugares_servicio{lock_hint}"
        )
        existing = {
            (int(district_id or 0), int(route_id or 0), _import_key(name))
            for district_id, route_id, name in cursor.fetchall()
        }

        reviewed: list[dict] = []
        file_keys: set[tuple[int, int, str]] = set()
        valid_payloads: list[dict] = []
        for index, raw in enumerate(rows):
            row = raw if isinstance(raw, dict) else {}
            row_number = int(row.get("fila") or index + 2)
            district_name = str(row.get("distrito") or "").strip()
            route_name = str(row.get("ruta") or "").strip()
            service_name = str(row.get("tipo_servicio") or "").strip()
            place_name = str(row.get("nombre_lugar_servicio") or "").strip()
            amount_raw = str(row.get("cantidad_requerida") or "").strip()
            errors: list[str] = []
            if row.get("_parse_error"):
                errors.append(str(row["_parse_error"]))

            district_matches = districts.get(_import_key(district_name), [])
            district = district_matches[0] if len(district_matches) == 1 else None
            if not district_name:
                errors.append("Distrito es obligatorio")
            elif not district_matches:
                errors.append(f"El distrito '{district_name}' no existe o no está activo")
            elif len(district_matches) > 1:
                errors.append(f"El distrito '{district_name}' es ambiguo")

            type_matches = service_types.get(_import_key(service_name), [])
            service_type = type_matches[0] if len(type_matches) == 1 else None
            if not service_name:
                errors.append("Tipo de servicio es obligatorio")
            elif not type_matches:
                errors.append(f"El tipo de servicio '{service_name}' no existe o no está activo")
            elif len(type_matches) > 1:
                errors.append(f"El tipo de servicio '{service_name}' es ambiguo")

            route_matches = routes.get(_import_key(route_name), [])
            route = None
            if not route_name:
                errors.append("Ruta es obligatoria")
            elif not route_matches:
                errors.append(f"La ruta '{route_name}' no existe")
            elif district:
                matching_district = [item for item in route_matches if item[2] == district[0]]
                if len(matching_district) == 1:
                    route = matching_district[0]
                elif not matching_district:
                    errors.append(f"La ruta '{route_name}' no pertenece al distrito '{district_name}'")
                else:
                    errors.append(f"La ruta '{route_name}' es ambigua dentro del distrito")

            amount = None
            if not amount_raw.isdigit():
                errors.append("Cantidad requerida debe ser numérica y mayor a 0")
            else:
                amount = int(amount_raw)
                if amount <= 0:
                    errors.append("Cantidad requerida debe ser mayor a 0")
            if not place_name:
                errors.append("Nombre del lugar de servicio es obligatorio")

            duplicate_key = None
            if district and route and place_name:
                duplicate_key = (district[0], route[0], _import_key(place_name))
                if duplicate_key in existing:
                    errors.append("Ya existe un lugar de servicio con ese nombre en la ruta indicada")
                elif duplicate_key in file_keys:
                    errors.append("Lugar de servicio duplicado dentro del archivo CSV")
                elif not errors:
                    file_keys.add(duplicate_key)

            normalized = None
            if not errors and district and route and service_type and amount is not None:
                normalized = {
                    "nombre": place_name,
                    "direccion": place_name,
                    "ubicacionEspecifica": None,
                    "distritoId": district[0],
                    "rutaId": route[0],
                    "tipoServicioId": service_type[0],
                    "turnoId": route[3],
                    "cantidadRequerida": amount,
                    "estadoOperativo": "ACTIVO",
                    "consignas": str(row.get("consignas") or "").strip() or None,
                    "observacion": str(row.get("observacion") or "").strip() or None,
                    "lugarFormacion": str(row.get("lugar_formacion") or "").strip() or None,
                    "activo": True,
                }
                valid_payloads.append(normalized)

            reviewed.append({
                "fila": row_number,
                "distrito": district_name,
                "ruta": route_name,
                "tipo_servicio": service_name,
                "cantidad_requerida": amount_raw,
                "nombre_lugar_servicio": place_name,
                "consignas": str(row.get("consignas") or "").strip(),
                "observacion": str(row.get("observacion") or "").strip(),
                "lugar_formacion": str(row.get("lugar_formacion") or "").strip(),
                "valida": not errors,
                "errores": errors,
            })

        imported = 0
        if confirm:
            for data in valid_payloads:
                cursor.execute(
                    """INSERT INTO dbo.lugares_servicio (
                           nombre,direccion,ubicacion_especifica,distrito_id,ruta_id,tipo_servicio_id,turno_id,
                           cantidad_requerida,estado_operativo,consignas,observacion,lugar_formacion,
                           latitud,longitud,activo,fecha_creacion
                       ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, NULL, 1, SYSDATETIME())""",
                    data["nombre"], data["direccion"], data["ubicacionEspecifica"], data["distritoId"],
                    data["rutaId"], data["tipoServicioId"], data["turnoId"], data["cantidadRequerida"],
                    data["estadoOperativo"], data["consignas"], data["observacion"], data["lugarFormacion"],
                )
                imported += 1

        valid_count = sum(1 for row in reviewed if row["valida"])
        return {
            "filas": reviewed,
            "total": len(reviewed),
            "validos": valid_count,
            "rechazados": len(reviewed) - valid_count,
            "importados": imported,
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
