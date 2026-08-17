import json
from datetime import date

from fastapi import HTTPException

from app.core.db import get_connection
from app.core.sanitize import escape_like
from app.core.security import hash_password


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _row(cursor) -> dict | None:
    rows = _rows(cursor)
    return rows[0] if rows else None


def list_people_paginated(
    search: str | None = None,
    estado: int | None = None,
    grado: int | None = None,
    rol: int | None = None,
    grupo: int | None = None,
    jornada: int | None = None,
    activo: int | None = None,
    page: int = 1,
    limit: int = 10,
) -> dict:
    params_count = []
    params_data = []
    where_count = []
    where_data = []

    where_base = "WHERE 1 = 1"

    if search:
        like = f"%{escape_like(search.lower())}%"
        cond = (
            "AND (LOWER(p.nombres) LIKE ? ESCAPE '\\' OR LOWER(p.apellidos) LIKE ? ESCAPE '\\' "
            "OR LOWER(p.cedula) LIKE ? ESCAPE '\\' OR LOWER(p.correo_institucional) LIKE ? ESCAPE '\\' "
            "OR LOWER(r.nombre) LIKE ? ESCAPE '\\' OR LOWER(g.nombre) LIKE ? ESCAPE '\\')"
        )
        params_count.extend([like] * 6)
        params_data.extend([like] * 6)
        where_count.append(cond)
        where_data.append(cond)

    if estado is not None:
        cond = "AND p.estado_personal_id = ?"
        params_count.append(estado)
        params_data.append(estado)
        where_count.append(cond)
        where_data.append(cond)

    if grado is not None:
        cond = "AND p.grado_id = ?"
        params_count.append(grado)
        params_data.append(grado)
        where_count.append(cond)
        where_data.append(cond)

    if rol is not None:
        cond = "AND p.rol_id = ?"
        params_count.append(rol)
        params_data.append(rol)
        where_count.append(cond)
        where_data.append(cond)

    if grupo is not None:
        cond = "AND p.grupo_id = ?"
        params_count.append(grupo)
        params_data.append(grupo)
        where_count.append(cond)
        where_data.append(cond)

    if jornada is not None:
        cond = "AND p.jornada_id = ?"
        params_count.append(jornada)
        params_data.append(jornada)
        where_count.append(cond)
        where_data.append(cond)

    if activo is not None:
        cond = "AND p.activo = ?"
        params_count.append(activo)
        params_data.append(activo)
        where_count.append(cond)
        where_data.append(cond)

    where_sql_count = where_base + " ".join(where_count)
    where_sql_data = where_base + " ".join(where_data)

    sql_count = f"SELECT COUNT(*) FROM dbo.personal p LEFT JOIN dbo.roles r ON r.id = p.rol_id LEFT JOIN dbo.grados g ON g.id = p.grado_id {where_sql_count}"

    offset = max(0, (page - 1) * limit)

    sql_data = f"""
        SELECT
            p.id,
            p.cedula,
            p.nombres,
            p.apellidos,
            LTRIM(RTRIM(ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
            p.correo_institucional,
            p.telefono,
            p.cargo_id,
            p.area_id,
            p.grupo_id,
            p.jornada_id,
            p.rol_id,
            p.grado_id,
            p.estado_personal_id,
            p.activo,
            r.nombre AS rol,
            ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal,
            ISNULL(g.nombre, '') AS grado,
            ISNULL(cg.nombre, '') AS grupo,
            ISNULL(jj.nombre, '') AS jornada
        FROM dbo.personal p
        LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
        LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
        LEFT JOIN dbo.grados g ON g.id = p.grado_id
        LEFT JOIN dbo.catalogo_detalles cg ON cg.id = p.grupo_id
        LEFT JOIN dbo.catalogo_detalles jj ON jj.id = p.jornada_id
        {where_sql_data}
        ORDER BY p.apellidos, p.nombres
        OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
    """
    params_data.extend([offset, limit])

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql_count, *params_count)
        total = cursor.fetchone()[0]
        cursor.execute(sql_data, *params_data)
        data = _rows(cursor)

    total_pages = max(1, (total + limit - 1) // limit)
    return {
        "data": data,
        "pagination": {
            "page": page,
            "limit": limit,
            "total": total,
            "totalPages": total_pages,
        },
    }


def list_people(search: str | None = None, limit: int = 200) -> list[dict]:
    params = []
    where = "WHERE 1 = 1"
    if search:
        where += """
          AND (
            LOWER(p.nombres) LIKE ? ESCAPE '\\'
            OR LOWER(p.apellidos) LIKE ? ESCAPE '\\'
            OR LOWER(p.cedula) LIKE ? ESCAPE '\\'
            OR LOWER(p.correo_institucional) LIKE ? ESCAPE '\\'
          )
        """
        term = f"%{escape_like(search.lower())}%"
        params.extend([term, term, term, term])

    sql = f"""
        SELECT TOP ({int(limit)})
            p.id,
            p.cedula,
            p.nombres,
            p.apellidos,
            LTRIM(RTRIM(ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
            p.correo_institucional,
            p.telefono,
            p.cargo_id,
            p.area_id,
            p.grupo_id,
            p.jornada_id,
            p.rol_id,
            p.grado_id,
            p.estado_personal_id,
            p.activo,
            r.nombre AS rol,
            ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal,
            ISNULL(g.nombre, '') AS grado,
            ISNULL(cg.nombre, '') AS grupo,
            ISNULL(jj.nombre, '') AS jornada
        FROM dbo.personal p
        LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
        LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
        LEFT JOIN dbo.grados g ON g.id = p.grado_id
        LEFT JOIN dbo.catalogo_detalles cg ON cg.id = p.grupo_id
        LEFT JOIN dbo.catalogo_detalles jj ON jj.id = p.jornada_id
        {where}
        ORDER BY p.apellidos, p.nombres
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, *params)
        return _rows(cursor)


def get_person(person_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT p.id, p.cedula, p.nombres, p.apellidos,
                   LTRIM(RTRIM(ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                   p.correo_institucional, p.telefono, p.cargo_id, p.area_id,
                   p.grupo_id, p.jornada_id, p.rol_id, p.grado_id,
                   p.estado_personal_id, p.activo,
                   r.nombre AS rol, ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal
            FROM dbo.personal p
            LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            WHERE p.id = ?
        """, person_id)
        person = _row(cursor)
        if not person:
            raise HTTPException(404, "La persona no existe")
        return person


def create_person(data: dict, user_id: int) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.personal WHERE cedula = ?", data["cedula"])
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe una persona con esa cédula")
        password_hash = hash_password(data["password"]) if data.get("password") else None
        cursor.execute("""
            INSERT INTO dbo.personal
              (cedula, nombres, apellidos, correo_institucional, telefono,
               cargo_id, area_id, grupo_id, jornada_id, rol_id, grado_id,
               estado_personal_id, password_hash, activo, fecha_creacion)
            OUTPUT INSERTED.id VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
        """,
            data["cedula"], data["nombres"], data["apellidos"],
            data["correo_institucional"], data.get("telefono"),
            data.get("cargo_id"), data.get("area_id"), data.get("grupo_id"),
            data.get("jornada_id"), data.get("rol_id"), data.get("grado_id"),
            data.get("estado_personal_id"), password_hash,
            1 if data.get("activo", True) else 0,
        )
        return int(cursor.fetchone()[0])


def update_person(person_id: int, data: dict, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.personal WHERE id = ?", person_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La persona no existe")
        cursor.execute("SELECT id FROM dbo.personal WHERE cedula = ? AND id <> ?", data["cedula"], person_id)
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe otra persona con esa cédula")
        sets = [
            "cedula = ?", "nombres = ?", "apellidos = ?",
            "correo_institucional = ?", "telefono = ?",
            "cargo_id = ?", "area_id = ?", "grupo_id = ?",
            "jornada_id = ?", "rol_id = ?", "grado_id = ?",
            "estado_personal_id = ?", "activo = ?",
            "fecha_actualizacion = SYSDATETIME()",
        ]
        params = [
            data["cedula"], data["nombres"], data["apellidos"],
            data["correo_institucional"], data.get("telefono"),
            data.get("cargo_id"), data.get("area_id"), data.get("grupo_id"),
            data.get("jornada_id"), data.get("rol_id"), data.get("grado_id"),
            data.get("estado_personal_id"),
            1 if data.get("activo", True) else 0,
        ]
        if data.get("password"):
            sets.append("password_hash = ?")
            params.append(hash_password(data["password"]))
        params.append(person_id)
        cursor.execute(f"UPDATE dbo.personal SET {', '.join(sets)} WHERE id = ?", *params)


def delete_person(person_id: int, user_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.personal WHERE id = ?", person_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La persona no existe")
        cursor.execute("UPDATE dbo.personal SET activo = 0, fecha_actualizacion = SYSDATETIME() WHERE id = ?", person_id)


def my_profile(user_id: int) -> dict | None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT TOP 1
                p.id, p.cedula, p.nombres, p.apellidos,
                LTRIM(RTRIM(ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                p.correo_institucional, p.telefono, p.cargo_id, p.area_id,
                p.grupo_id, p.jornada_id, p.rol_id, p.grado_id,
                p.estado_personal_id, p.activo,
                r.nombre AS rol, ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal
            FROM dbo.personal p
            LEFT JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            WHERE p.id = ?
        """, user_id)
        result = _rows(cursor)
        return result[0] if result else None


def reset_password(person_id: int, new_password: str) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.personal WHERE id = ?", person_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La persona no existe")
        cursor.execute(
            "UPDATE dbo.personal SET password_hash = ?, fecha_actualizacion = SYSDATETIME() WHERE id = ?",
            hash_password(new_password), person_id,
        )


def catalogs_for_personal() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id, nombre FROM dbo.roles WHERE activo = 1 ORDER BY nombre")
        roles = _rows(cursor)
        cursor.execute("SELECT id, nombre FROM dbo.grados WHERE activo = 1 ORDER BY nombre")
        grados = _rows(cursor)
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'ESTADOS_PERSONAL' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.nombre
        """)
        estados = _rows(cursor)
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'GRUPOS' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.orden, cd.nombre
        """)
        grupos = _rows(cursor)
        cursor.execute("""
            SELECT cd.id, cd.nombre FROM dbo.catalogo_detalles cd
            INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'JORNADAS' AND c.estado = 1 AND cd.estado = 1 ORDER BY cd.orden, cd.nombre
        """)
        jornadas = _rows(cursor)
        return {"roles": roles, "grados": grados, "estados": estados, "grupos": grupos, "jornadas": jornadas}
