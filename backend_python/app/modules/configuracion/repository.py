import json
from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def my_structure(user_id: int) -> list[dict]:
    sql = """
        SELECT ms.id,
               COALESCE(NULLIF(rmc.nombre_visual, ''), ms.nombre) AS nombre,
               ms.codigo,
               COALESCE(rmc.icono_visual, ms.icono) AS icono,
               ms.ruta,
               rmc.modulo_padre_id,
               rmc.grupo,
               rmc.orden,
               rmc.nombre_visual AS etiqueta_personalizada,
               rmc.visible,
               rmc.habilitado,
               rmc.expandido,
               rmc.mostrar_badge,
               rmc.color_badge
        FROM dbo.personal per
        INNER JOIN dbo.roles r ON r.id = per.rol_id
        INNER JOIN dbo.rol_menu_configuracion rmc ON rmc.rol_id = r.id
        INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
        WHERE per.id = ?
          AND r.activo = 1
          AND rmc.visible = 1
          AND ms.estado = 1
        ORDER BY rmc.orden
    """
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(sql, user_id)
        return _rows(cursor)


def build_tree(items: list[dict]) -> list[dict]:
    mapped = {item["id"]: {**item, "hijos": []} for item in items}
    roots = []
    for item in items:
        menu_item = mapped[item["id"]]
        parent_id = item.get("modulo_padre_id")
        if parent_id and parent_id in mapped:
            mapped[parent_id]["hijos"].append(menu_item)
        else:
            roots.append(menu_item)
    return roots


def roles_configuration() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id, nombre, descripcion, activo FROM dbo.roles ORDER BY nombre")
        roles = _rows(cursor)
        for role in roles:
            cursor.execute(
                """
                SELECT p.id, p.codigo, p.descripcion, p.modulo
                FROM dbo.rol_permiso rp
                INNER JOIN dbo.permisos p ON p.id = rp.permiso_id
                WHERE rp.rol_id = ?
                ORDER BY p.modulo, p.codigo
                """,
                role["id"],
            )
            role["permisos"] = _rows(cursor)
        return roles


def current_version() -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT TOP 1
                id,
                rol_id,
                creado_por AS usuario_id,
                COALESCE(comentario, CONCAT('Versión ', CONVERT(NVARCHAR(30), version), ' - ', estado)) AS resumen,
                fecha_creacion
            FROM dbo.versiones_configuracion_roles
            ORDER BY fecha_creacion DESC, id DESC
            """
        )
        rows = _rows(cursor)
        return rows[0] if rows else {"resumen": "Configuración inicial", "fecha_creacion": None}


def all_permissions() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT id, codigo, descripcion, modulo, activo
            FROM dbo.permisos
            WHERE ISNULL(activo, 1) = 1
            ORDER BY modulo, codigo
            """
        )
        return _rows(cursor)


def update_role_permissions(role_id: int, permission_ids: list[int]) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("DELETE FROM dbo.rol_permiso WHERE rol_id = ?", role_id)
        for permission_id in sorted(set(int(item) for item in permission_ids)):
            cursor.execute(
                "INSERT INTO dbo.rol_permiso (rol_id, permiso_id) VALUES (?, ?)",
                role_id,
                permission_id,
            )


def all_modules() -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT id, codigo, nombre, ruta, icono, plataforma, orden_global, tiene_submenus, estado
            FROM dbo.modulos_sistema
            ORDER BY orden_global, nombre
            """
        )
        return _rows(cursor)


def menu_configuration(role_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT rmc.id, rmc.rol_id, rmc.modulo_id, ms.codigo, ms.nombre, ms.ruta, ms.icono,
                   rmc.modulo_padre_id, rmc.grupo, rmc.nombre_visual, rmc.icono_visual,
                   rmc.orden, rmc.visible, rmc.habilitado, rmc.expandido, rmc.pagina_inicial,
                   rmc.primera_opcion, rmc.mostrar_badge, rmc.color_badge, rmc.mostrar_vacio
            FROM dbo.rol_menu_configuracion rmc
            INNER JOIN dbo.modulos_sistema ms ON ms.id = rmc.modulo_id
            WHERE rmc.rol_id = ?
            ORDER BY rmc.orden, ms.nombre
            """,
            role_id,
        )
        return _rows(cursor)


def save_menu_configuration(role_id: int, items: list[dict]) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        for index, item in enumerate(items, start=1):
            menu_id = int(item.get("id") or 0)
            modulo_id = int(item.get("moduloId") or item.get("modulo_id") or 0)
            values = (
                item.get("moduloPadreId") or item.get("modulo_padre_id"),
                item.get("grupo"),
                item.get("nombreVisual") or item.get("nombre_visual"),
                item.get("iconoVisual") or item.get("icono_visual"),
                int(item.get("orden") or index),
                1 if item.get("visible", True) else 0,
                1 if item.get("habilitado", True) else 0,
                1 if item.get("expandido", False) else 0,
                1 if item.get("paginaInicial", False) else 0,
                1 if item.get("primeraOpcion", False) else 0,
                1 if item.get("mostrarBadge", False) else 0,
                item.get("colorBadge") or item.get("color_badge"),
                1 if item.get("mostrarVacio", False) else 0,
            )
            if menu_id > 0:
                cursor.execute(
                    """
                    UPDATE dbo.rol_menu_configuracion
                    SET modulo_padre_id = ?, grupo = ?, nombre_visual = ?, icono_visual = ?,
                        orden = ?, visible = ?, habilitado = ?, expandido = ?,
                        pagina_inicial = ?, primera_opcion = ?, mostrar_badge = ?,
                        color_badge = ?, mostrar_vacio = ?, fecha_actualizacion = SYSDATETIME()
                    WHERE id = ? AND rol_id = ?
                    """,
                    *values,
                    menu_id,
                    role_id,
                )
            elif modulo_id > 0:
                cursor.execute(
                    """
                    INSERT INTO dbo.rol_menu_configuracion (
                        rol_id, modulo_id, modulo_padre_id, grupo, nombre_visual, icono_visual,
                        orden, visible, habilitado, expandido, pagina_inicial, primera_opcion,
                        mostrar_badge, color_badge, mostrar_vacio, fecha_actualizacion
                    )
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
                    """,
                    role_id,
                    modulo_id,
                    *values,
                )


def data_scopes(role_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT rad.id, rad.rol_id, rad.modulo_id, ms.nombre AS modulo,
                   rad.tipo_alcance, rad.configuracion_json
            FROM dbo.rol_alcance_datos rad
            INNER JOIN dbo.modulos_sistema ms ON ms.id = rad.modulo_id
            WHERE rad.rol_id = ?
            ORDER BY ms.nombre
            """,
            role_id,
        )
        return _rows(cursor)


def save_data_scope(role_id: int, data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        item_id = int(data.get("id") or 0)
        if item_id > 0:
            cursor.execute(
                """
                UPDATE dbo.rol_alcance_datos
                SET modulo_id = ?, tipo_alcance = ?, configuracion_json = ?
                WHERE id = ? AND rol_id = ?
                """,
                data["moduloId"],
                data["tipoAlcance"],
                data.get("configuracionJson"),
                item_id,
                role_id,
            )
            return item_id
        cursor.execute(
            """
            INSERT INTO dbo.rol_alcance_datos (rol_id, modulo_id, tipo_alcance, configuracion_json)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?)
            """,
            role_id,
            data["moduloId"],
            data["tipoAlcance"],
            data.get("configuracionJson"),
        )
        return int(cursor.fetchone()[0])


def role_conditions(role_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            """
            SELECT rc.id, rc.rol_id, rc.modulo_id, ms.nombre AS modulo, rc.campo,
                   rc.operador, rc.valor, rc.agrupador, rc.estado
            FROM dbo.rol_condiciones rc
            LEFT JOIN dbo.modulos_sistema ms ON ms.id = rc.modulo_id
            WHERE rc.rol_id = ?
            ORDER BY rc.id DESC
            """,
            role_id,
        )
        return _rows(cursor)


def save_role_condition(role_id: int, data: dict) -> int:
    with get_connection() as connection:
        cursor = connection.cursor()
        item_id = int(data.get("id") or 0)
        values = (
            data.get("moduloId"),
            data["campo"],
            data["operador"],
            data.get("valor"),
            data.get("agrupador"),
            1 if data.get("estado", True) else 0,
        )
        if item_id > 0:
            cursor.execute(
                """
                UPDATE dbo.rol_condiciones
                SET modulo_id = ?, campo = ?, operador = ?, valor = ?, agrupador = ?, estado = ?
                WHERE id = ? AND rol_id = ?
                """,
                *values,
                item_id,
                role_id,
            )
            return item_id
        cursor.execute(
            """
            INSERT INTO dbo.rol_condiciones (rol_id, modulo_id, campo, operador, valor, agrupador, estado)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            role_id,
            *values,
        )
        return int(cursor.fetchone()[0])


def delete_role_condition(role_id: int, condition_id: int) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute(
            "UPDATE dbo.rol_condiciones SET estado = 0 WHERE id = ? AND rol_id = ?",
            condition_id,
            role_id,
        )


def system_fields() -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("""SELECT cs.id,cs.modulo_id,ms.nombre AS modulo,cs.codigo,cs.nombre,cs.tipo_dato,cs.clasificacion,cs.estado
                          FROM dbo.campos_sistema cs LEFT JOIN dbo.modulos_sistema ms ON ms.id=cs.modulo_id ORDER BY ms.nombre,cs.nombre""")
        return _rows(cursor)


def role_fields(role_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("""SELECT cs.id AS campo_id,cs.codigo,cs.nombre,cs.tipo_dato,cs.clasificacion,ms.nombre AS modulo,
                          ISNULL(rcp.nivel_acceso,'ninguno') AS nivel_acceso,ISNULL(rcp.enmascarado,0) AS enmascarado
                          FROM dbo.campos_sistema cs LEFT JOIN dbo.modulos_sistema ms ON ms.id=cs.modulo_id
                          LEFT JOIN dbo.rol_campos_permisos rcp ON rcp.campo_id=cs.id AND rcp.rol_id=? WHERE cs.estado=1 ORDER BY ms.nombre,cs.nombre""",role_id)
        return _rows(cursor)


def save_role_fields(role_id: int, items: list[dict]) -> None:
    with get_connection() as connection:
        cursor=connection.cursor()
        for item in items:
            cursor.execute("DELETE FROM dbo.rol_campos_permisos WHERE rol_id=? AND campo_id=?",role_id,int(item["campoId"]))
            cursor.execute("INSERT INTO dbo.rol_campos_permisos(rol_id,campo_id,nivel_acceso,enmascarado) VALUES(?,?,?,?)",role_id,int(item["campoId"]),item.get("nivelAcceso") or "ninguno",1 if item.get("enmascarado") else 0)


def role_versions(role_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("""SELECT v.id,v.rol_id,v.version,v.estado,v.comentario,v.creado_por,p.nombre_completo AS creado_por_nombre,v.fecha_creacion
                          FROM dbo.versiones_configuracion_roles v LEFT JOIN dbo.vw_personal_detalle p ON p.id=v.creado_por WHERE v.rol_id=? ORDER BY v.version DESC""",role_id)
        return _rows(cursor)


def create_role_version(role_id: int, user_id: int, comment: str | None) -> int:
    snapshot={"menu":menu_configuration(role_id),"alcance":data_scopes(role_id),"campos":role_fields(role_id),"condiciones":role_conditions(role_id)}
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute("SELECT ISNULL(MAX(version),0)+1 FROM dbo.versiones_configuracion_roles WHERE rol_id=?",role_id); version=int(cursor.fetchone()[0])
        cursor.execute("""INSERT INTO dbo.versiones_configuracion_roles(rol_id,version,estado,configuracion_json,comentario,creado_por,fecha_creacion)
                          OUTPUT INSERTED.id VALUES(?,?,'ACTIVA',?,?,?,SYSDATETIME())""",role_id,version,json.dumps(snapshot,ensure_ascii=False,default=str),comment,user_id)
        return int(cursor.fetchone()[0])


def configuration_audit(role_id: int | None = None, limit: int = 100) -> list[dict]:
    with get_connection() as connection:
        cursor=connection.cursor(); cursor.execute(f"""SELECT TOP ({int(limit)}) a.id,a.usuario_id,p.nombre_completo AS usuario,a.accion,a.rol_afectado_id,r.nombre AS rol,
                          a.valor_anterior,a.valor_nuevo,a.ip,a.dispositivo,a.fecha FROM dbo.auditoria_roles_permisos a
                          LEFT JOIN dbo.vw_personal_detalle p ON p.id=a.usuario_id LEFT JOIN dbo.roles r ON r.id=a.rol_afectado_id
                          WHERE (? IS NULL OR a.rol_afectado_id=?) ORDER BY a.fecha DESC""",role_id,role_id)
        return _rows(cursor)
