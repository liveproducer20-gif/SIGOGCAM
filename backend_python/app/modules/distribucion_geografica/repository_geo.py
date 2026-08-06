import json
from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


# ===================================================================
# RUTAS GEOGRÁFICAS
# ===================================================================

def list_rutas_geograficas(distrito_id: int | None = None) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        sql = """SELECT rg.id, rg.distrito_id, cd.nombre AS distrito, rg.ruta_id, r.nombre AS ruta,
                        rg.nombre, rg.descripcion, rg.tipo_geometria, rg.geojson,
                        rg.color, rg.grosor, rg.opacidad, rg.estado, rg.activo,
                        p.nombre_completo AS creado_por_nombre,
                        rg.fecha_creacion, rg.fecha_actualizacion
                 FROM dbo.rutas_geograficas rg
                 INNER JOIN dbo.catalogo_detalles cd ON cd.id = rg.distrito_id
                 INNER JOIN dbo.rutas r ON r.id = rg.ruta_id
                 LEFT JOIN dbo.vw_personal_detalle p ON p.id = rg.creado_por
                 WHERE rg.activo = 1"""
        params = []
        if distrito_id:
            sql += " AND rg.distrito_id = ?"
            params.append(distrito_id)
        sql += " ORDER BY cd.nombre, r.nombre, rg.nombre"
        cursor.execute(sql, params)
        return _rows(cursor)


def get_ruta_geografica(ruta_geo_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT rg.id, rg.distrito_id, cd.nombre AS distrito, rg.ruta_id, r.nombre AS ruta,
                                 rg.nombre, rg.descripcion, rg.tipo_geometria, rg.geojson,
                                 rg.color, rg.grosor, rg.opacidad, rg.estado, rg.activo,
                                 rg.creado_por, p.nombre_completo AS creado_por_nombre,
                                 rg.fecha_creacion, rg.fecha_actualizacion
                          FROM dbo.rutas_geograficas rg
                          INNER JOIN dbo.catalogo_detalles cd ON cd.id = rg.distrito_id
                          INNER JOIN dbo.rutas r ON r.id = rg.ruta_id
                          LEFT JOIN dbo.vw_personal_detalle p ON p.id = rg.creado_por
                          WHERE rg.id = ? AND rg.activo = 1""", ruta_geo_id)
        rows = _rows(cursor)
        return rows[0] if rows else None


def get_ruta_geografica_by_ruta(ruta_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT rg.id, rg.distrito_id, cd.nombre AS distrito, rg.ruta_id, r.nombre AS ruta,
                                 rg.nombre, rg.descripcion, rg.tipo_geometria, rg.geojson,
                                 rg.color, rg.grosor, rg.opacidad, rg.estado, rg.activo,
                                 rg.creado_por, p.nombre_completo AS creado_por_nombre,
                                 rg.fecha_creacion, rg.fecha_actualizacion
                          FROM dbo.rutas_geograficas rg
                          INNER JOIN dbo.catalogo_detalles cd ON cd.id = rg.distrito_id
                          INNER JOIN dbo.rutas r ON r.id = rg.ruta_id
                          LEFT JOIN dbo.vw_personal_detalle p ON p.id = rg.creado_por
                          WHERE rg.ruta_id = ? AND rg.activo = 1""", ruta_id)
        rows = _rows(cursor)
        return rows[0] if rows else None


def create_ruta_geografica(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """INSERT INTO dbo.rutas_geograficas
               (distrito_id, ruta_id, nombre, descripcion, tipo_geometria, geojson,
                color, grosor, opacidad, estado, activo, creado_por, fecha_creacion)
               OUTPUT INSERTED.id
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, SYSDATETIME())""",
            data["distrito_id"], data["ruta_id"], data["nombre"],
            data.get("descripcion"), data.get("tipo_geometria", "lineal"),
            data.get("geojson"), data.get("color", "#2563EB"),
            data.get("grosor", 6), data.get("opacidad", 0.55),
            data.get("estado", "ACTIVA"), user_id
        )
        return int(cursor.fetchone()[0])


def update_ruta_geografica(ruta_geo_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE dbo.rutas_geograficas
               SET nombre = ?, descripcion = ?, tipo_geometria = ?, geojson = ?,
                   color = ?, grosor = ?, opacidad = ?, estado = ?,
                   actualizado_por = ?, fecha_actualizacion = SYSDATETIME()
               WHERE id = ? AND activo = 1""",
            data.get("nombre"), data.get("descripcion"),
            data.get("tipo_geometria"), data.get("geojson"),
            data.get("color"), data.get("grosor"), data.get("opacidad"),
            data.get("estado"), user_id, ruta_geo_id
        )


def delete_ruta_geografica(ruta_geo_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE dbo.rutas_geograficas
               SET activo = 0, actualizado_por = ?, fecha_actualizacion = SYSDATETIME()
               WHERE id = ?""",
            user_id, ruta_geo_id
        )


# ===================================================================
# LUGARES DE SERVICIO
# ===================================================================

def list_lugares_servicio(ruta_id: int | None = None, distrito_id: int | None = None) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        sql = """SELECT ls.id, ls.ruta_id, r.nombre AS ruta, ls.nombre, ls.descripcion,
                        ls.direccion_referencial, ls.latitud, ls.longitud,
                        ls.estado, ls.activo, ls.creado_por,
                        p.nombre_completo AS creado_por_nombre,
                        ls.fecha_creacion, ls.fecha_actualizacion,
                        (SELECT COUNT(*) FROM dbo.asignaciones_punto ap
                         WHERE ap.punto_id = ls.id AND ap.activo = 1) AS agentes_asignados
                 FROM dbo.lugares_servicio ls
                 INNER JOIN dbo.rutas r ON r.id = ls.ruta_id
                 LEFT JOIN dbo.vw_personal_detalle p ON p.id = ls.creado_por
                 WHERE ls.activo = 1"""
        params = []
        if ruta_id:
            sql += " AND ls.ruta_id = ?"
            params.append(ruta_id)
        if distrito_id:
            sql += " AND r.id IN (SELECT id FROM dbo.rutas WHERE distrito_id = ?)"
            params.append(distrito_id)
        sql += " ORDER BY r.nombre, ls.nombre"
        cursor.execute(sql, params)
        return _rows(cursor)


def get_lugar_servicio(lugar_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT ls.id, ls.ruta_id, r.nombre AS ruta, ls.nombre, ls.descripcion,
                                 ls.direccion_referencial, ls.latitud, ls.longitud,
                                 ls.estado, ls.activo, ls.creado_por,
                                 p.nombre_completo AS creado_por_nombre,
                                 ls.fecha_creacion, ls.fecha_actualizacion
                          FROM dbo.lugares_servicio ls
                          INNER JOIN dbo.rutas r ON r.id = ls.ruta_id
                          LEFT JOIN dbo.vw_personal_detalle p ON p.id = ls.creado_por
                          WHERE ls.id = ? AND ls.activo = 1""", lugar_id)
        rows = _rows(cursor)
        return rows[0] if rows else None


def create_lugar_servicio(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """INSERT INTO dbo.lugares_servicio
               (ruta_id, nombre, descripcion, direccion_referencial, latitud, longitud,
                estado, activo, creado_por, fecha_creacion)
               OUTPUT INSERTED.id
               VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?, SYSDATETIME())""",
            data["ruta_id"], data["nombre"], data.get("descripcion"),
            data.get("direccion_referencial"), data.get("latitud"),
            data.get("longitud"), data.get("estado", "ACTIVO"), user_id
        )
        return int(cursor.fetchone()[0])


def update_lugar_servicio(lugar_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE dbo.lugares_servicio
               SET nombre = ?, descripcion = ?, direccion_referencial = ?,
                   latitud = ?, longitud = ?, estado = ?,
                   fecha_actualizacion = SYSDATETIME()
               WHERE id = ? AND activo = 1""",
            data.get("nombre"), data.get("descripcion"),
            data.get("direccion_referencial"), data.get("latitud"),
            data.get("longitud"), data.get("estado"), lugar_id
        )


def delete_lugar_servicio(lugar_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE dbo.lugares_servicio
               SET activo = 0, fecha_actualizacion = SYSDATETIME()
               WHERE id = ?""",
            lugar_id
        )


# ===================================================================
# CATÁLOGOS (distritos, rutas por distrito)
# ===================================================================

def get_distritos() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT cd.id, cd.codigo, cd.nombre
                          FROM dbo.catalogo_detalles cd
                          INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
                          WHERE c.codigo = 'DISTRITOS' AND cd.estado = 1
                          ORDER BY cd.nombre""")
        return _rows(cursor)


def get_rutas_por_distrito(distrito_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT r.id, r.nombre, r.distrito_id, r.turno_id,
                                 r.hora_inicio, r.hora_fin, r.activo
                          FROM dbo.rutas r
                          WHERE r.distrito_id = ? AND r.activo = 1
                          ORDER BY r.nombre""", distrito_id)
        return _rows(cursor)


def get_lugares_por_ruta(ruta_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT ls.id, ls.nombre, ls.descripcion,
                                 ls.direccion_referencial, ls.latitud, ls.longitud,
                                 ls.estado
                          FROM dbo.lugares_servicio ls
                          WHERE ls.ruta_id = ? AND ls.activo = 1
                          ORDER BY ls.nombre""", ruta_id)
        return _rows(cursor)


# ===================================================================
# ASIGNACIONES DE PUNTOS (lugares de servicio)
# ===================================================================

def get_asignaciones_punto(punto_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""SELECT ap.id, ap.personal_id,
                                 p.nombre_completo AS agente, p.cedula AS codigo,
                                 ap.tipo_asignacion, ap.fecha_inicio, ap.fecha_fin,
                                 ap.turno_id, t.nombre AS turno,
                                 ap.hora_inicio, ap.hora_fin,
                                 ap.funcion, ap.observaciones, ap.estado
                          FROM dbo.asignaciones_punto ap
                          INNER JOIN dbo.vw_personal_detalle p ON p.id = ap.personal_id
                          LEFT JOIN dbo.turnos t ON t.id = ap.turno_id
                          WHERE ap.punto_id = ? AND ap.activo = 1
                          ORDER BY ap.fecha_inicio DESC""", punto_id)
        return _rows(cursor)


def create_asignacion_punto(punto_id: int, data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """INSERT INTO dbo.asignaciones_punto
               (punto_id, personal_id, tipo_asignacion, fecha_inicio, fecha_fin,
                turno_id, hora_inicio, hora_fin, funcion, observaciones,
                estado, activo, creado_por, fecha_creacion)
               OUTPUT INSERTED.id
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'ACTIVA', 1, ?, SYSDATETIME())""",
            punto_id, data["personal_id"], data.get("tipo_asignacion", "FIJA"),
            data["fecha_inicio"], data.get("fecha_fin"),
            data["turno_id"], data["hora_inicio"], data["hora_fin"],
            data.get("funcion"), data.get("observaciones"), user_id
        )
        return int(cursor.fetchone()[0])


def delete_asignacion_punto(asignacion_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """UPDATE dbo.asignaciones_punto
               SET activo = 0, estado = 'INACTIVA', actualizado_por = ?, fecha_actualizacion = SYSDATETIME()
               WHERE id = ?""",
            user_id, asignacion_id
        )
