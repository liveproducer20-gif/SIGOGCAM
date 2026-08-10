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
               l.cantidad_requerida, l.estado_operativo, l.consignas, l.observacion,
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
    }


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
                consignas,observacion,latitud,longitud,activo,fecha_creacion
            )
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),data.get("turnoId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("latitud"),data.get("longitud"),
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
                consignas=?,observacion=?,latitud=?,longitud=?,activo=?,fecha_actualizacion=SYSDATETIME()
            WHERE id = ?
            """,
            data.get("nombre"),data["direccion"],data.get("ubicacionEspecifica"),data["distritoId"],data["rutaId"],
            data.get("tipoServicioId"),data.get("turnoId"),
            int(data.get("cantidadRequerida",1)),data.get("estadoOperativo","ACTIVO"),
            data.get("consignas"),data.get("observacion"),data.get("latitud"),data.get("longitud"),
            1 if data.get("activo", True) else 0,
            item_id,
        )


def delete_service_place(item_id: int) -> None:
    _soft_delete("lugares_servicio", item_id)


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
