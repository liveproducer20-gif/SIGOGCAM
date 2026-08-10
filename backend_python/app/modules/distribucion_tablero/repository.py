import json
import random
import uuid
from datetime import date, datetime, time
from decimal import Decimal

from fastapi import HTTPException

from app.core.db import get_connection


def _rows(cursor) -> list[dict]:
    columns = [column[0] for column in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _row(cursor) -> dict | None:
    rows = _rows(cursor)
    return rows[0] if rows else None


def _audit(cursor, user_id: int, action: str, sorteo_id: str, data: dict) -> None:
    cursor.execute("""
        INSERT INTO dbo.auditoria (usuario_id, accion, modulo, tabla_afectada, registro_id, metodo, endpoint, datos_nuevos)
        VALUES (?, ?, N'distribucion', N'sorteos_historial', ?, 'POST', '/api/distribucion-tablero/sorteo', ?)
    """, user_id, action, sorteo_id, json.dumps(data, default=str, ensure_ascii=False))


def get_route_sectors(route_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT ls.id, ls.nombre, ls.cantidad_requerida AS cantidad_agentes_requeridos,
                   ls.distrito_id, ls.ruta_id,
                   (SELECT COUNT(*) FROM dbo.asignaciones_ruta ar
                    WHERE ar.sector_id = ls.id AND ar.estado IN ('PENDIENTE', 'ACTIVA')
                    AND ar.deleted_at IS NULL) AS agentes_asignados
            FROM dbo.lugares_servicio ls
            WHERE ls.activo = 1 AND ls.ruta_id = ?
            ORDER BY ls.orden_distribucion, ls.nombre
        """, route_id)
        return _rows(cursor)


def get_route_info(route_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id, r.turno_id, r.hora_inicio, r.hora_fin,
                   d.nombre AS distrito, t.nombre AS turno
            FROM dbo.rutas r
            INNER JOIN dbo.catalogo_detalles d ON d.id = r.distrito_id
            LEFT JOIN dbo.turnos t ON t.id = r.turno_id
            WHERE r.id = ? AND r.activo = 1
        """, route_id)
        route = _row(cursor)
        if not route:
            raise HTTPException(404, "La ruta no existe o no esta activa")
        return route


def get_route_stats(route_id: int, fecha: date, turno: str) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT
                (SELECT COUNT(*) FROM dbo.lugares_servicio WHERE ruta_id = ? AND activo = 1) AS total_sectores,
                (SELECT ISNULL(SUM(cantidad_requerida), 0) FROM dbo.lugares_servicio WHERE ruta_id = ? AND activo = 1) AS agentes_requeridos,
                (SELECT COUNT(*) FROM dbo.asignaciones_ruta
                 WHERE ruta_id = ? AND fecha_asignacion = ? AND turno = ?
                 AND estado IN ('PENDIENTE', 'ACTIVA') AND deleted_at IS NULL) AS agentes_asignados
        """, route_id, route_id, route_id, fecha, turno)
        stats = _row(cursor) or {}
        stats["agentes_pendientes"] = max(0, (stats.get("agentes_requeridos") or 0) - (stats.get("agentes_asignados") or 0))
        stats["cobertura"] = round(((stats.get("agentes_asignados") or 0) / max(1, (stats.get("agentes_requeridos") or 1))) * 100)
        return {k: int(v or 0) for k, v in stats.items()}


def get_available_agents(route_id: int, fecha: date, turno: str, hora_inicio: time, hora_fin: time) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT p.id,
                   LTRIM(RTRIM(ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                   p.cedula,
                   ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal,
                   p.grado_id,
                   p.cargo_id AS cargo,
                   p.area_id AS area,
                   p.funcion_operativa_id
            FROM dbo.personal p
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            WHERE p.activo = 1
              AND ISNULL(ep.nombre, 'SIN ESTADO') = 'ACTIVO'
              AND p.id NOT IN (
                  SELECT ar.agente_id FROM dbo.asignaciones_ruta ar
                  WHERE ar.fecha_asignacion = ? AND ar.estado IN ('PENDIENTE', 'ACTIVA')
                    AND ar.deleted_at IS NULL
                    AND ar.hora_inicio < ? AND ar.hora_fin > ?
              )
              AND p.id NOT IN (
                  SELECT ap.personal_id FROM dbo.asignaciones_punto ap
                  WHERE ap.fecha_inicio <= ? AND (ap.fecha_fin IS NULL OR ap.fecha_fin >= ?)
                    AND ap.activo = 1 AND ap.estado IN ('ACTIVA', 'PENDIENTE')
                    AND ap.hora_inicio < ? AND ap.hora_fin > ?
              )
              AND p.id NOT IN (
                  SELECT ae.personal_id FROM dbo.evento_personal ae
                  INNER JOIN dbo.eventos e ON e.id = ae.evento_id
                  WHERE ae.fecha_asignacion = ?
                    AND e.fecha >= ?
                    AND e.fecha <= ?
              )
            ORDER BY nombre_completo
        """, fecha, hora_fin, hora_inicio, fecha, fecha, hora_fin, hora_inicio, fecha, fecha, fecha)
        return _rows(cursor)


def _get_agent_assignment_history(cursor, agent_id: int) -> dict:
    cursor.execute("""
        SELECT
            COUNT(*) AS total_asignaciones,
            ISNULL(SUM(CASE WHEN ar.ruta_id IS NOT NULL THEN 1 ELSE 0 END), 0) AS asignaciones_ruta
        FROM dbo.asignaciones_ruta ar
        WHERE ar.agente_id = ? AND ar.deleted_at IS NULL
    """, agent_id)
    return _row(cursor) or {"total_asignaciones": 0, "asignaciones_ruta": 0}


def _get_agent_route_history(cursor, agent_id: int, ruta_id: int) -> int:
    cursor.execute("""
        SELECT COUNT(*) FROM dbo.asignaciones_ruta
        WHERE agente_id = ? AND ruta_id = ? AND deleted_at IS NULL
    """, agent_id, ruta_id)
    result = cursor.fetchone()
    return int(result[0]) if result else 0


def _get_agent_sector_history(cursor, agent_id: int, sector_id: int) -> int:
    cursor.execute("""
        SELECT COUNT(*) FROM dbo.asignaciones_ruta
        WHERE agente_id = ? AND sector_id = ? AND deleted_at IS NULL
    """, agent_id, sector_id)
    result = cursor.fetchone()
    return int(result[0]) if result else 0


def generate_random_preview(route_id: int, fecha: date, turno: str, hora_inicio: time, hora_fin: time, user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        route = get_route_info(route_id)
        sectors = get_route_sectors(route_id)
        if not sectors:
            raise HTTPException(422, "La ruta no tiene sectores activos")

        total_required = sum(s["cantidad_agentes_requeridos"] for s in sectors)
        if total_required == 0:
            raise HTTPException(422, "Ningun sector tiene una cantidad de agentes requeridos configurada")

        available = get_available_agents(route_id, fecha, turno, hora_inicio, hora_fin)
        if not available:
            raise HTTPException(422, "No existe personal disponible para completar la ruta")

        sorteo_id = str(uuid.uuid4())[:16]

        agent_scores = []
        for agent in available:
            agent_id = agent["id"]
            history = _get_agent_assignment_history(cursor, agent_id)
            route_history = _get_agent_route_history(cursor, agent_id, route_id)
            score = 100
            score -= history.get("asignaciones_ruta", 0) * 3
            score -= route_history * 5
            score = max(0, score)
            agent_scores.append({
                **agent,
                "score": score,
                "total_asignaciones": history.get("total_asignaciones", 0),
                "asignaciones_en_ruta": route_history,
            })

        agent_scores.sort(key=lambda a: a["score"], reverse=True)

        preview = []
        used_agents = set()

        for sector in sectors:
            sector_preview = {
                "sector_id": sector["id"],
                "sector_nombre": sector["nombre"],
                "cantidad_requerida": sector["cantidad_agentes_requeridos"],
                "agentes": [],
            }
            candidates = [a for a in agent_scores if a["id"] not in used_agents]
            candidates.sort(key=lambda a: (
                -a["score"],
                a.get("asignaciones_en_ruta", 0),
                a.get("total_asignaciones", 0),
            ))
            selected = candidates[:sector["cantidad_agentes_requeridos"]]
            for agent in selected:
                used_agents.add(agent["id"])
                sector_preview["agentes"].append({
                    "agente_id": agent["id"],
                    "agente_nombre": agent["nombre_completo"],
                    "cedula": agent["cedula"],
                    "score": agent["score"],
                    "asignaciones_previas": agent.get("total_asignaciones", 0),
                    "en_esta_ruta": agent.get("asignaciones_en_ruta", 0),
                })
            preview.append(sector_preview)

        total_selected = len(used_agents)
        insufficient = total_selected < total_required

        return {
            "sorteo_id": sorteo_id,
            "ruta": route,
            "sectores": preview,
            "agentes_requeridos": total_required,
            "agentes_disponibles": len(available),
            "agentes_seleccionados": total_selected,
            "insuficiente": insufficient,
            "mensaje_personal_insuficiente": (
                f"No existe suficiente personal disponible para completar la ruta. "
                f"Se requieren {total_required} agentes y unicamente existen {len(available)} agentes disponibles."
            ) if insufficient else None,
        }


def confirm_random_assignment(sorteo_id: str, asignaciones: list[dict], user_id: int, ip: str | None = None) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()

        if not asignaciones:
            raise HTTPException(422, "No hay asignaciones para confirmar")

        first = asignaciones[0]
        ruta_id = first.get("ruta_id")
        fecha = first.get("fecha_asignacion")
        turno = first.get("turno")
        hora_inicio = first.get("hora_inicio")
        hora_fin = first.get("hora_fin")
        distrito_id = first.get("distrito_id")

        if not all([ruta_id, fecha, turno, hora_inicio, hora_fin, distrito_id]):
            raise HTTPException(422, "Datos de asignacion incompletos")

        cursor.execute("SELECT id FROM dbo.rutas WHERE id=? AND activo=1", ruta_id)
        if not cursor.fetchone():
            raise HTTPException(422, "La ruta ya no esta activa")

        assigned_agent_ids = set()
        for asig in asignaciones:
            agent_id = asig.get("agente_id")
            if not agent_id:
                raise HTTPException(422, "Asignacion sin agente especificado")
            if agent_id in assigned_agent_ids:
                raise HTTPException(409, f"El agente {agent_id} esta duplicado en la solicitud")
            assigned_agent_ids.add(agent_id)

            cursor.execute("SELECT id, estado_personal FROM dbo.vw_personal_detalle WHERE id=?", agent_id)
            agent = cursor.fetchone()
            if not agent or str(agent[1]).upper() != "ACTIVO":
                raise HTTPException(422, f"El agente {agent_id} ya no esta activo")

            cursor.execute("""
                SELECT TOP 1 ar.id FROM dbo.asignaciones_ruta ar
                WHERE ar.agente_id = ? AND ar.fecha_asignacion = ? AND ar.estado IN ('PENDIENTE', 'ACTIVA')
                  AND ar.deleted_at IS NULL AND ar.hora_inicio < ? AND ar.hora_fin > ?
            """, agent_id, fecha, hora_fin, hora_inicio)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya tiene una asignacion en ese horario")

            cursor.execute("""
                SELECT TOP 1 ap.id FROM dbo.asignaciones_punto ap
                WHERE ap.personal_id = ? AND ap.fecha_inicio <= ? AND (ap.fecha_fin IS NULL OR ap.fecha_fin >= ?)
                  AND ap.activo = 1 AND ap.estado IN ('ACTIVA', 'PENDIENTE')
                  AND ap.hora_inicio < ? AND ap.hora_fin > ?
            """, agent_id, fecha, fecha, hora_fin, hora_inicio)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} tiene un servicio asignado en ese horario")

        created_ids = []
        for asig in asignaciones:
            cursor.execute("""
                INSERT INTO dbo.asignaciones_ruta
                    (agente_id, distrito_id, ruta_id, sector_id, fecha_asignacion, turno,
                     hora_inicio, hora_fin, estado, tipo_asignacion, sorteo_id, asignado_por, observacion, fecha_creacion)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'PENDIENTE', 'ALEATORIA', ?, ?, ?, SYSDATETIME())
            """, asig["agente_id"], distrito_id, ruta_id, asig["sector_id"], fecha,
                 turno, hora_inicio, hora_fin, sorteo_id, user_id, asig.get("observacion"))
            created_ids.append(int(cursor.fetchone()[0]))

        sectors_summary = {}
        for asig in asignaciones:
            sid = asig["sector_id"]
            if sid not in sectors_summary:
                sectors_summary[sid] = {"sector_id": sid, "agentes": 0}
            sectors_summary[sid]["agentes"] += 1

        audit_data = {
            "sorteo_id": sorteo_id,
            "ruta_id": ruta_id,
            "fecha_servicio": str(fecha),
            "turno": turno,
            "agentes_confirmados": len(created_ids),
            "sectores": list(sectors_summary.values()),
        }
        _audit(cursor, user_id, "CONFIRMAR_SORTEO", sorteo_id, audit_data)

        cursor.execute("""
            INSERT INTO dbo.sorteos_historial
                (sorteo_id, usuario_id, distrito_id, ruta_id, fecha_servicio, turno,
                 hora_inicio, hora_fin, sectores_incluidos, agentes_requeridos,
                 agentes_disponibles, agentes_seleccionados, agentes_confirmados,
                 veces_sorteo, resultado, ip, fecha_ejecucion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'CONFIRMADO', ?, SYSDATETIME())
        """, sorteo_id, user_id, distrito_id, ruta_id, fecha, turno, hora_inicio, hora_fin,
             json.dumps(list(sectors_summary.values()), default=str),
             len(created_ids), len(created_ids), len(created_ids), len(created_ids), ip)

        return {
            "ok": True,
            "sorteo_id": sorteo_id,
            "asignaciones_creadas": len(created_ids),
            "ids": created_ids,
        }


def clean_route_assignments(ruta_id: int, fecha: date, turno: str, user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            UPDATE dbo.asignaciones_ruta
            SET estado = 'CANCELADA', deleted_at = SYSDATETIME(), fecha_actualizacion = SYSDATETIME()
            WHERE ruta_id = ? AND fecha_asignacion = ? AND turno = ?
              AND estado IN ('PENDIENTE', 'ACTIVA') AND deleted_at IS NULL
        """, ruta_id, fecha, turno)
        affected = cursor.rowcount
        _audit(cursor, user_id, "LIMPIAR_ASIGNACIONES", f"clean-{ruta_id}", {
            "ruta_id": ruta_id, "fecha": str(fecha), "turno": turno, "eliminadas": affected
        })
        return {"eliminadas": affected}


def get_assignments_by_route(route_id: int, fecha: date, turno: str) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT ar.id, ar.agente_id, vp.nombre_completo AS agente_nombre, vp.cedula,
                   ar.sector_id, ls.nombre AS sector_nombre,
                   ar.fecha_asignacion, ar.turno, ar.hora_inicio, ar.hora_fin,
                   ar.estado, ar.tipo_asignacion, ar.sorteo_id, ar.observacion,
                   ar.fecha_creacion
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ar.agente_id
            INNER JOIN dbo.lugares_servicio ls ON ls.id = ar.sector_id
            WHERE ar.ruta_id = ? AND ar.fecha_asignacion = ? AND ar.turno = ?
              AND ar.deleted_at IS NULL
            ORDER BY ls.orden_distribucion, ls.nombre, vp.nombre_completo
        """, route_id, fecha, turno)
        return _rows(cursor)


def get_assignment_history(route_id: int | None = None, fecha_desde: date | None = None, fecha_hasta: date | None = None) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        where = ["sh.deleted_at IS NULL"]
        params: list = []
        if route_id:
            where.append("sh.ruta_id = ?")
            params.append(route_id)
        if fecha_desde:
            where.append("sh.fecha_servicio >= ?")
            params.append(fecha_desde)
        if fecha_hasta:
            where.append("sh.fecha_servicio <= ?")
            params.append(fecha_hasta)
        sql = f"""
            SELECT sh.sorteo_id, sh.usuario_id, vp.nombre_completo AS usuario_nombre,
                   sh.distrito_id, d.nombre AS distrito, sh.ruta_id, r.nombre AS ruta,
                   sh.fecha_servicio, sh.turno, sh.hora_inicio, sh.hora_fin,
                   sh.agentes_requeridos, sh.agentes_disponibles, sh.agentes_seleccionados,
                   sh.agentes_confirmados, sh.veces_sorteo, sh.resultado, sh.fecha_ejecucion
            FROM dbo.sorteos_historial sh
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = sh.usuario_id
            INNER JOIN dbo.catalogo_detalles d ON d.id = sh.distrito_id
            INNER JOIN dbo.rutas r ON r.id = sh.ruta_id
            WHERE {' AND '.join(where)}
            ORDER BY sh.fecha_ejecucion DESC
        """
        cursor.execute(sql, *params)
        return _rows(cursor)


def update_sector_requirements(route_id: int, sectores: list[dict], user_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        updated = 0
        for item in sectores:
            cursor.execute("""
                UPDATE dbo.lugares_servicio
                SET cantidad_requerida = ?, actualizado_por = ?, fecha_actualizacion = SYSDATETIME()
                WHERE id = ? AND ruta_id = ? AND activo = 1
            """, item["cantidad_agentes_requeridos"], user_id, item["sector_id"], route_id)
            updated += cursor.rowcount
        _audit(cursor, user_id, "CONFIGURAR_REQUERIMIENTO", f"config-{route_id}", {
            "ruta_id": route_id, "sectores_actualizados": updated
        })
        return {"sectores_actualizados": updated}


# ---------------------------------------------------------------------------
# Tablero de distribución v2: el borrador vive en el navegador y solamente
# se persiste cuando el usuario confirma la fecha de la distribución general.
# ---------------------------------------------------------------------------


def get_board_data(district_id: int, shift_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT t.id, t.nombre, t.hora_inicio, t.hora_fin
            FROM dbo.turnos t WHERE t.id = ? AND t.activo = 1
        """, shift_id)
        shift = _row(cursor)
        if not shift:
            raise HTTPException(404, "El turno seleccionado no existe o no esta activo")

        cursor.execute("""
            SELECT d.id, d.nombre
            FROM dbo.catalogo_detalles d
            WHERE d.id = ? AND d.estado = 1
        """, district_id)
        district = _row(cursor)
        if not district:
            raise HTTPException(404, "El distrito seleccionado no existe o no esta activo")

        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id, r.turno_id,
                   COALESCE(r.hora_inicio, t.hora_inicio) AS hora_inicio,
                   COALESCE(r.hora_fin, t.hora_fin) AS hora_fin,
                   COUNT(ls.id) AS lugares
            FROM dbo.rutas r
            LEFT JOIN dbo.turnos t ON t.id = ?
            LEFT JOIN dbo.lugares_servicio ls ON ls.ruta_id = r.id AND ls.activo = 1
                AND (ls.turno_id IS NULL OR ls.turno_id = ?)
            WHERE r.activo = 1 AND r.distrito_id = ?
              AND (r.turno_id IS NULL OR r.turno_id = ?)
            GROUP BY r.id, r.nombre, r.distrito_id, r.turno_id,
                     COALESCE(r.hora_inicio, t.hora_inicio), COALESCE(r.hora_fin, t.hora_fin)
            ORDER BY r.nombre
        """, shift_id, shift_id, district_id, shift_id)
        return {"distrito": district, "turno": shift, "rutas": _rows(cursor)}


def get_route_places(route_id: int, shift_id: int) -> list[dict]:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT ls.id, ls.ruta_id, ls.distrito_id, ls.nombre,
                   COALESCE(NULLIF(ls.direccion_referencial, ''), NULLIF(ls.ubicacion_especifica, ''),
                            NULLIF(ls.direccion, ''), NULLIF(ls.descripcion, ''), N'Sin referencia') AS referencia,
                   CASE WHEN ls.cantidad_requerida < 0 THEN 0 ELSE ls.cantidad_requerida END AS cantidad_requerida
            FROM dbo.lugares_servicio ls
            INNER JOIN dbo.rutas r ON r.id = ls.ruta_id AND r.activo = 1
            WHERE ls.ruta_id = ? AND ls.activo = 1
              AND (ls.turno_id IS NULL OR ls.turno_id = ?)
              AND (r.turno_id IS NULL OR r.turno_id = ?)
            ORDER BY ls.nombre
        """, route_id, shift_id, shift_id)
        return _rows(cursor)


def _active_agents(cursor, excluded: set[int] | None = None) -> list[dict]:
    excluded = excluded or set()
    cursor.execute("""
        SELECT p.id,
               LTRIM(RTRIM(ISNULL(g.nombre + ' ', '') + ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
               p.cedula, ISNULL(g.nombre, '') AS grado,
               ISNULL(ep.nombre, 'SIN ESTADO') AS estado_personal
        FROM dbo.personal p
        LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
        LEFT JOIN dbo.grados g ON g.id = p.grado_id
        INNER JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
        WHERE p.activo = 1 AND UPPER(ISNULL(ep.nombre, '')) = 'ACTIVO'
          AND UPPER(ISNULL(r.codigo, '')) IN ('AGENTE', 'ENCARGADO', 'INSPECTOR', 'OPERACIONES', 'SUPERVISOR')
        ORDER BY p.apellidos, p.nombres
    """)
    return [item for item in _rows(cursor) if int(item["id"]) not in excluded]


def get_board_availability(district_id: int, shift_id: int, excluded: set[int] | None = None) -> dict:
    excluded = excluded or set()
    with get_connection() as connection:
        cursor = connection.cursor()
        all_active_agents = _active_agents(cursor)
        agents = [agent for agent in all_active_agents if int(agent["id"]) not in excluded]
        cursor.execute("""
            SELECT DISTINCT ap.personal_id
            FROM dbo.asignaciones_punto ap
            WHERE ap.activo = 1 AND ap.turno_id = ?
              AND ap.estado IN ('ACTIVA', 'PENDIENTE')
              AND CAST(GETDATE() AS date) BETWEEN ap.fecha_inicio AND ISNULL(ap.fecha_fin, '9999-12-31')
            UNION
            SELECT DISTINCT ar.agente_id
            FROM dbo.asignaciones_ruta ar
            WHERE ar.distrito_id = ? AND ar.turno = (SELECT nombre FROM dbo.turnos WHERE id = ?)
              AND ar.fecha_asignacion = CAST(GETDATE() AS date)
              AND ar.estado IN ('ACTIVA', 'PENDIENTE') AND ar.deleted_at IS NULL
        """, shift_id, district_id, shift_id)
        database_service_ids = {int(row[0]) for row in cursor.fetchall()}
        in_service_ids = (database_service_ids | excluded) & {int(agent["id"]) for agent in all_active_agents}
        available = [a for a in agents if int(a["id"]) not in in_service_ids]

        cursor.execute("""
            SELECT COUNT(*)
            FROM dbo.personal p
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            LEFT JOIN dbo.roles r ON r.id = p.rol_id
            WHERE p.activo = 0 OR UPPER(ISNULL(ep.nombre, '')) <> 'ACTIVO'
               OR UPPER(ISNULL(r.codigo, '')) NOT IN ('AGENTE', 'ENCARGADO', 'INSPECTOR', 'OPERACIONES', 'SUPERVISOR')
        """)
        unavailable = int(cursor.fetchone()[0])
        return {
            "agentes": available,
            "disponibles": len(available),
            "en_servicio": len(in_service_ids),
            "no_disponibles": unavailable,
            "total_agentes": len(all_active_agents) + unavailable,
        }


def generate_draft_assignments(data: dict) -> dict:
    route_id = int(data["ruta_id"])
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    current = data.get("asignaciones") or []
    used = {int(item["agente_id"]) for item in current}
    if len(used) != len(current):
        raise HTTPException(409, "El borrador contiene agentes duplicados")

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT id FROM dbo.rutas WHERE id=? AND distrito_id=? AND activo=1", route_id, district_id)
        if not cursor.fetchone():
            raise HTTPException(422, "La ruta no pertenece al distrito seleccionado")
        places = get_route_places(route_id, shift_id)
        if not places:
            raise HTTPException(422, "La ruta no tiene lugares de servicio para este turno")
        agents = get_board_availability(district_id, shift_id, used)["agentes"]
        random.SystemRandom().shuffle(agents)

        by_place: dict[int, list[dict]] = {}
        for item in current:
            by_place.setdefault(int(item["lugar_id"]), []).append(item)
        generated: list[dict] = []
        position = 0
        for place in places:
            missing = max(0, int(place["cantidad_requerida"] or 0) - len(by_place.get(int(place["id"]), [])))
            for _ in range(missing):
                if position >= len(agents):
                    break
                agent = agents[position]
                position += 1
                generated.append({
                    "lugar_id": int(place["id"]),
                    "agente_id": int(agent["id"]),
                    "tipo_asignacion": "ALEATORIA",
                    "agente": agent,
                })
        required = sum(int(place["cantidad_requerida"] or 0) for place in places)
        assigned_on_route = sum(len(by_place.get(int(place["id"]), [])) for place in places) + len(generated)
        return {
            "asignaciones": generated,
            "requeridos": required,
            "asignados": assigned_on_route,
            "insuficiente": assigned_on_route < required,
            "mensaje": "No existe suficiente personal disponible para cubrir toda la ruta." if assigned_on_route < required else None,
        }


def _validate_distribution_relations(cursor, district_id: int, shift_id: int, assignments: list[dict]) -> tuple[list[dict], dict[int, dict]]:
    cursor.execute("""
        SELECT ls.id, ls.ruta_id, ls.distrito_id,
               CASE WHEN ls.cantidad_requerida < 0 THEN 0 ELSE ls.cantidad_requerida END AS cantidad_requerida,
               ls.nombre AS lugar, r.nombre AS ruta
        FROM dbo.lugares_servicio ls
        INNER JOIN dbo.rutas r ON r.id = ls.ruta_id AND r.activo = 1
        WHERE ls.activo = 1 AND r.distrito_id = ?
          AND (r.turno_id IS NULL OR r.turno_id = ?)
          AND (ls.turno_id IS NULL OR ls.turno_id = ?)
            ORDER BY r.nombre, ls.nombre
    """, district_id, shift_id, shift_id)
    places = _rows(cursor)
    if not places:
        raise HTTPException(422, "No existen lugares de servicio para el distrito y turno seleccionados")
    place_map = {int(place["id"]): place for place in places}
    counts: dict[int, int] = {}
    for item in assignments:
        place_id = int(item["lugar_id"])
        if place_id not in place_map:
            raise HTTPException(422, f"El lugar {place_id} no pertenece al distrito y turno seleccionados")
        counts[place_id] = counts.get(place_id, 0) + 1
        if counts[place_id] > int(place_map[place_id]["cantidad_requerida"] or 0):
            raise HTTPException(422, f"El lugar {place_map[place_id]['lugar']} supera su cantidad requerida")
    return places, place_map


def save_distribution(data: dict, user_id: int, ip: str | None = None) -> dict:
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    assignments = data.get("asignaciones") or []
    agent_ids = [int(item["agente_id"]) for item in assignments]
    if len(agent_ids) != len(set(agent_ids)):
        raise HTTPException(409, "Un agente no puede estar asignado a dos lugares en la misma distribucion")

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        cursor.execute("""
            SELECT id, nombre, hora_inicio, hora_fin
            FROM dbo.turnos WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND activo=1
        """, shift_id)
        shift = _row(cursor)
        if not shift:
            raise HTTPException(422, "El turno seleccionado no es valido")
        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE id=? AND estado=1", district_id)
        if not cursor.fetchone():
            raise HTTPException(422, "El distrito seleccionado no es valido")

        places, place_map = _validate_distribution_relations(cursor, district_id, shift_id, assignments)
        required = sum(int(place["cantidad_requerida"] or 0) for place in places)
        assigned = len(assignments)
        pending = max(0, required - assigned)
        if pending and not data.get("guardar_con_pendientes"):
            raise HTTPException(409, "La distribucion posee lugares de servicio pendientes de asignacion")

        cursor.execute("""
            SELECT TOP 1 id FROM dbo.distribuciones_personal WITH (UPDLOCK, HOLDLOCK)
            WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=? AND deleted_at IS NULL
        """, district_id, shift_id, distribution_date)
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe una distribucion guardada para ese distrito, turno y fecha")

        for agent_id in agent_ids:
            cursor.execute("""
                SELECT p.id
                FROM dbo.personal p WITH (UPDLOCK, HOLDLOCK)
                LEFT JOIN dbo.catalogo_detalles ep ON ep.id=p.estado_personal_id
                INNER JOIN dbo.roles r ON r.id=p.rol_id AND r.activo=1
                WHERE p.id=? AND p.activo=1 AND UPPER(ISNULL(ep.nombre,''))='ACTIVO'
                  AND UPPER(ISNULL(r.codigo,'')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')
            """, agent_id)
            if not cursor.fetchone():
                raise HTTPException(422, f"El agente {agent_id} no esta habilitado para trabajar")
            cursor.execute("""
                SELECT TOP 1 id FROM dbo.asignaciones_ruta WITH (UPDLOCK, HOLDLOCK)
                WHERE agente_id=? AND fecha_asignacion=? AND turno=?
                  AND estado IN ('PENDIENTE','ACTIVA') AND deleted_at IS NULL
            """, agent_id, distribution_date, shift["nombre"])
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya esta asignado en la misma fecha y turno")
            cursor.execute("""
                SELECT TOP 1 id FROM dbo.asignaciones_punto WITH (UPDLOCK, HOLDLOCK)
                WHERE personal_id=? AND turno_id=? AND activo=1 AND estado IN ('ACTIVA','PENDIENTE')
                  AND fecha_inicio <= ? AND (fecha_fin IS NULL OR fecha_fin >= ?)
            """, agent_id, shift_id, distribution_date, distribution_date)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya tiene un servicio para esa fecha y turno")

        name = f"DISTRIBUCIÓN DE PERSONAL FECHA {distribution_date.strftime('%d/%m/%Y')}"
        coverage = round((assigned / required * 100), 2) if required else 0
        status = "COMPLETA" if pending == 0 else "PARCIAL"
        cursor.execute("""
            INSERT INTO dbo.distribuciones_personal
                (nombre, fecha_distribucion, creado_por, distrito_id, turno_id, estado,
                 porcentaje_cobertura, total_requerido, total_asignado, fecha_creacion)
            OUTPUT INSERTED.id
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
        """, name, distribution_date, user_id, district_id, shift_id, status, coverage, required, assigned)
        distribution_id = int(cursor.fetchone()[0])

        by_place: dict[int, list[dict]] = {}
        for item in assignments:
            by_place.setdefault(int(item["lugar_id"]), []).append(item)
        assignment_ids: list[int] = []
        for place in places:
            place_assignments = by_place.get(int(place["id"]), [])
            slots = max(int(place["cantidad_requerida"] or 0), len(place_assignments))
            for slot in range(slots):
                item = place_assignments[slot] if slot < len(place_assignments) else None
                assignment_id = None
                if item:
                    cursor.execute("""
                        INSERT INTO dbo.asignaciones_ruta
                            (agente_id, distrito_id, ruta_id, sector_id, lugar_id, fecha_asignacion, turno,
                             hora_inicio, hora_fin, estado, tipo_asignacion, sorteo_id,
                             asignado_por, observacion, fecha_creacion)
                        OUTPUT INSERTED.id
                        VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?, 'PENDIENTE', ?, ?, ?, ?, SYSDATETIME())
                    """, int(item["agente_id"]), district_id, int(place["ruta_id"]), int(place["id"]),
                         distribution_date, shift["nombre"], shift["hora_inicio"], shift["hora_fin"],
                         str(item.get("tipo_asignacion") or "MANUAL").upper(), f"DIST-{distribution_id}",
                         user_id, name)
                    assignment_id = int(cursor.fetchone()[0])
                    assignment_ids.append(assignment_id)
                cursor.execute("""
                    INSERT INTO dbo.distribucion_personal_detalle
                        (distribucion_id, ruta_id, lugar_id, cantidad_requerida, agente_id,
                         asignacion_ruta_id, tipo_asignacion, estado, fecha_creacion)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
                """, distribution_id, int(place["ruta_id"]), int(place["id"]), int(place["cantidad_requerida"] or 0),
                     int(item["agente_id"]) if item else None, assignment_id,
                     str(item.get("tipo_asignacion") or "MANUAL").upper() if item else None,
                     "ASIGNADO" if item else "PENDIENTE")

        _audit(cursor, user_id, "GUARDAR_DISTRIBUCION", str(distribution_id), {
            "nombre": name, "fecha": str(distribution_date), "distrito_id": district_id,
            "turno_id": shift_id, "requeridos": required, "asignados": assigned,
            "cobertura": coverage, "ip": ip,
        })
        return {
            "id": distribution_id, "nombre": name, "fecha_distribucion": distribution_date,
            "estado": status, "porcentaje_cobertura": coverage,
            "total_requerido": required, "total_asignado": assigned,
            "pendientes": pending, "asignaciones_creadas": len(assignment_ids),
        }


def get_distribution(distribution_id: int) -> dict:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT dp.id, dp.nombre, dp.fecha_distribucion, dp.estado, dp.porcentaje_cobertura,
                   dp.total_requerido, dp.total_asignado, dp.fecha_creacion,
                   d.nombre AS distrito, t.nombre AS turno,
                   vp.nombre_completo AS creado_por_nombre
            FROM dbo.distribuciones_personal dp
            INNER JOIN dbo.catalogo_detalles d ON d.id=dp.distrito_id
            INNER JOIN dbo.turnos t ON t.id=dp.turno_id
            LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=dp.creado_por
            WHERE dp.id=? AND dp.deleted_at IS NULL
        """, distribution_id)
        header = _row(cursor)
        if not header:
            raise HTTPException(404, "La distribucion no existe")
        cursor.execute("""
            SELECT dd.id, dd.ruta_id, r.nombre AS ruta, dd.lugar_id, ls.nombre AS lugar,
                   dd.cantidad_requerida, dd.agente_id, vp.nombre_completo AS agente,
                   vp.cedula, dd.tipo_asignacion, dd.estado
            FROM dbo.distribucion_personal_detalle dd
            INNER JOIN dbo.rutas r ON r.id=dd.ruta_id
            INNER JOIN dbo.lugares_servicio ls ON ls.id=dd.lugar_id
            LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=dd.agente_id
            WHERE dd.distribucion_id=? AND dd.deleted_at IS NULL
            ORDER BY r.nombre, ls.nombre, dd.id
        """, distribution_id)
        header["detalles"] = _rows(cursor)
        return header


def update_distribution(distribution_id: int, data: dict, user_id: int, ip: str | None = None) -> dict:
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    assignments = data.get("asignaciones") or []
    agent_ids = [int(item["agente_id"]) for item in assignments]
    if len(agent_ids) != len(set(agent_ids)):
        raise HTTPException(409, "Un agente no puede estar asignado a dos lugares en la misma distribucion")

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        cursor.execute("""
            SELECT id FROM dbo.distribuciones_personal WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND deleted_at IS NULL
        """, distribution_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La distribucion no existe")

        cursor.execute("""
            UPDATE ar SET estado='CANCELADA', deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.distribucion_personal_detalle dd ON dd.asignacion_ruta_id=ar.id
            WHERE dd.distribucion_id=? AND ar.deleted_at IS NULL
        """, distribution_id)
        cursor.execute("""
            UPDATE dbo.distribucion_personal_detalle SET deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            WHERE distribucion_id=? AND deleted_at IS NULL
        """, distribution_id)

        cursor.execute("""
            SELECT id, nombre, hora_inicio, hora_fin FROM dbo.turnos WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND activo=1
        """, shift_id)
        shift = _row(cursor)
        if not shift:
            raise HTTPException(422, "El turno seleccionado no es valido")
        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE id=? AND estado=1", district_id)
        if not cursor.fetchone():
            raise HTTPException(422, "El distrito seleccionado no es valido")
        places, place_map = _validate_distribution_relations(cursor, district_id, shift_id, assignments)
        required = sum(int(place["cantidad_requerida"] or 0) for place in places)
        assigned = len(assignments)
        pending = max(0, required - assigned)
        if pending and not data.get("guardar_con_pendientes"):
            raise HTTPException(409, "La distribucion posee lugares de servicio pendientes de asignacion")

        cursor.execute("""
            SELECT TOP 1 id FROM dbo.distribuciones_personal WITH (UPDLOCK, HOLDLOCK)
            WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=?
              AND id<>? AND deleted_at IS NULL
        """, district_id, shift_id, distribution_date, distribution_id)
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe otra distribucion para ese distrito, turno y fecha")

        for agent_id in agent_ids:
            cursor.execute("""
                SELECT p.id FROM dbo.personal p WITH (UPDLOCK, HOLDLOCK)
                LEFT JOIN dbo.catalogo_detalles ep ON ep.id=p.estado_personal_id
                INNER JOIN dbo.roles r ON r.id=p.rol_id AND r.activo=1
                WHERE p.id=? AND p.activo=1 AND UPPER(ISNULL(ep.nombre,''))='ACTIVO'
                  AND UPPER(ISNULL(r.codigo,'')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')
            """, agent_id)
            if not cursor.fetchone():
                raise HTTPException(422, f"El agente {agent_id} no esta habilitado para trabajar")
            cursor.execute("""
                SELECT TOP 1 id FROM dbo.asignaciones_ruta WITH (UPDLOCK, HOLDLOCK)
                WHERE agente_id=? AND fecha_asignacion=? AND turno=?
                  AND estado IN ('PENDIENTE','ACTIVA') AND deleted_at IS NULL
            """, agent_id, distribution_date, shift["nombre"])
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya esta asignado en la misma fecha y turno")
            cursor.execute("""
                SELECT TOP 1 id FROM dbo.asignaciones_punto WITH (UPDLOCK, HOLDLOCK)
                WHERE personal_id=? AND turno_id=? AND activo=1 AND estado IN ('ACTIVA','PENDIENTE')
                  AND fecha_inicio<=? AND (fecha_fin IS NULL OR fecha_fin>=?)
            """, agent_id, shift_id, distribution_date, distribution_date)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya tiene un servicio para esa fecha y turno")

        name = f"DISTRIBUCIÓN DE PERSONAL FECHA {distribution_date.strftime('%d/%m/%Y')}"
        coverage = round((assigned / required * 100), 2) if required else 0
        status = "COMPLETA" if pending == 0 else "PARCIAL"
        cursor.execute("""
            UPDATE dbo.distribuciones_personal
            SET nombre=?, fecha_distribucion=?, distrito_id=?, turno_id=?, estado=?,
                porcentaje_cobertura=?, total_requerido=?, total_asignado=?, fecha_actualizacion=SYSDATETIME()
            WHERE id=?
        """, name, distribution_date, district_id, shift_id, status, coverage, required, assigned, distribution_id)

        by_place: dict[int, list[dict]] = {}
        for item in assignments:
            by_place.setdefault(int(item["lugar_id"]), []).append(item)
        created = 0
        for place in places:
            place_assignments = by_place.get(int(place["id"]), [])
            slots = max(int(place["cantidad_requerida"] or 0), len(place_assignments))
            for slot in range(slots):
                item = place_assignments[slot] if slot < len(place_assignments) else None
                assignment_id = None
                if item:
                    cursor.execute("""
                        INSERT INTO dbo.asignaciones_ruta
                            (agente_id, distrito_id, ruta_id, sector_id, lugar_id, fecha_asignacion, turno,
                             hora_inicio, hora_fin, estado, tipo_asignacion, sorteo_id,
                             asignado_por, observacion, fecha_creacion)
                        OUTPUT INSERTED.id
                        VALUES (?, ?, ?, NULL, ?, ?, ?, ?, ?, 'PENDIENTE', ?, ?, ?, ?, SYSDATETIME())
                    """, int(item["agente_id"]), district_id, int(place["ruta_id"]), int(place["id"]),
                         distribution_date, shift["nombre"], shift["hora_inicio"], shift["hora_fin"],
                         str(item.get("tipo_asignacion") or "MANUAL").upper(), f"DIST-{distribution_id}", user_id, name)
                    assignment_id = int(cursor.fetchone()[0])
                    created += 1
                cursor.execute("""
                    INSERT INTO dbo.distribucion_personal_detalle
                        (distribucion_id, ruta_id, lugar_id, cantidad_requerida, agente_id,
                         asignacion_ruta_id, tipo_asignacion, estado, fecha_creacion)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, SYSDATETIME())
                """, distribution_id, int(place["ruta_id"]), int(place["id"]), int(place["cantidad_requerida"] or 0),
                     int(item["agente_id"]) if item else None, assignment_id,
                     str(item.get("tipo_asignacion") or "MANUAL").upper() if item else None,
                     "ASIGNADO" if item else "PENDIENTE")

        _audit(cursor, user_id, "EDITAR_DISTRIBUCION", str(distribution_id), {
            "nombre": name, "fecha": str(distribution_date), "asignados": assigned, "cobertura": coverage, "ip": ip,
        })
        return {"id": distribution_id, "nombre": name, "fecha_distribucion": distribution_date,
                "estado": status, "porcentaje_cobertura": coverage, "total_requerido": required,
                "total_asignado": assigned, "pendientes": pending, "asignaciones_creadas": created}


def get_agents_for_modal(data: dict) -> dict:
    """Paginated, filtered agent list for the Cambiar modal."""
    with get_connection() as connection:
        cursor = connection.cursor()
        distrito_id = int(data["distrito_id"])
        turno_id = int(data["turno_id"])
        ruta_id = int(data["ruta_id"])
        lugar_id = int(data["lugar_id"])
        excluded_ids = [int(x) for x in data.get("excluidos", []) if x]
        page = int(data.get("page", 1))
        limit = int(data.get("limit", 20))
        offset = (page - 1) * limit

        cursor.execute("SELECT nombre FROM dbo.turnos WHERE id = ? AND activo = 1", turno_id)
        turno_row = cursor.fetchone()
        turno_nombre = turno_row[0] if turno_row else ""

        cursor.execute("""
            SELECT ls.nombre AS lugar_nombre, r.nombre AS ruta_nombre
            FROM dbo.lugares_servicio ls
            INNER JOIN dbo.rutas r ON r.id = ls.ruta_id
            WHERE ls.id = ? AND ls.ruta_id = ?
        """, lugar_id, ruta_id)
        place_row = cursor.fetchone()
        lugar_nombre = place_row[0] if place_row else ""
        ruta_nombre = place_row[1] if place_row else ""

        cursor.execute("""
            SELECT cd.id, cd.nombre FROM catalogo_detalles cd
            INNER JOIN catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'GRUPOS' AND cd.estado = 1 ORDER BY cd.nombre
        """)
        grupos = [{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()]

        cursor.execute("SELECT id, nombre FROM grados WHERE activo = 1 ORDER BY nombre")
        grados = [{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()]

        cursor.execute("""
            SELECT cd.id, cd.nombre FROM catalogo_detalles cd
            INNER JOIN catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'TIPOS_SERVICIO_LUGAR' AND cd.estado = 1 ORDER BY cd.nombre
        """)
        tipos_servicio = [{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()]

        cursor.execute("""
            SELECT cd.id, cd.nombre FROM catalogo_detalles cd
            INNER JOIN catalogos c ON c.id = cd.catalogo_id
            WHERE c.codigo = 'ESTADOS_PERSONAL' AND cd.estado = 1 ORDER BY cd.nombre
        """)
        estados = [{"id": int(r[0]), "nombre": r[1]} for r in cursor.fetchall()]

        where = ["p.activo = 1", "UPPER(ISNULL(r.codigo, '')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')"]
        params: list = []

        if excluded_ids:
            placeholders = ",".join("?" * len(excluded_ids))
            where.append(f"p.id NOT IN ({placeholders})")
            params.extend(excluded_ids)

        if data.get("grupo_id"):
            where.append("p.grupo_id = ?")
            params.append(int(data["grupo_id"]))
        if data.get("grado_id"):
            where.append("p.grado_id = ?")
            params.append(int(data["grado_id"]))
        if data.get("tipo_servicio_id"):
            where.append("fo.id = ?")
            params.append(int(data["tipo_servicio_id"]))
        if data.get("estado"):
            where.append("UPPER(ISNULL(ep.nombre, '')) = UPPER(?)")
            params.append(str(data["estado"]))
        if data.get("search"):
            where.append("(p.nombres LIKE ? OR p.apellidos LIKE ? OR p.cedula LIKE ?)")
            search = f"%{data['search']}%"
            params.extend([search, search, search])

        where_sql = " AND ".join(where)

        cursor.execute(f"""
            SELECT COUNT(*)
            FROM dbo.personal p
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            LEFT JOIN dbo.grados g ON g.id = p.grado_id
            LEFT JOIN dbo.catalogo_detalles gf ON gf.id = p.grupo_id
            LEFT JOIN dbo.catalogo_detalles fo ON fo.id = p.funcion_operativa_id
            INNER JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
            WHERE {where_sql}
        """, *params)
        total = int(cursor.fetchone()[0])

        cursor.execute(f"""
            SELECT p.id,
                   LTRIM(RTRIM(ISNULL(g.nombre + ' ', '') + ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                   p.nombres, p.apellidos, p.cedula,
                   ISNULL(ep.nombre, 'SIN ESTADO') AS estado_laboral,
                   ISNULL(g.nombre, '') AS grado,
                   ISNULL(gf.nombre, 'Sin grupo') AS grupo,
                   ISNULL(fo.nombre, '') AS tipo_servicio
            FROM dbo.personal p
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            LEFT JOIN dbo.grados g ON g.id = p.grado_id
            LEFT JOIN dbo.catalogo_detalles gf ON gf.id = p.grupo_id
            LEFT JOIN dbo.catalogo_detalles fo ON fo.id = p.funcion_operativa_id
            INNER JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
            WHERE {where_sql}
            ORDER BY p.apellidos, p.nombres
            OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
        """, *params, offset, limit)
        agents_rows = _rows(cursor)

        today = datetime.now().date()
        turno_name = turno_nombre

        agents = []
        for agent in agents_rows:
            agent_id = int(agent["id"])
            estado_laboral = str(agent["estado_laboral"]).upper()

            disponible = True
            motivo_no_disponible = ""

            if estado_laboral in ("VACACIONES", "FRANCO", "PERMISO", "INCAPACIDAD", "AUSENTE", "SUSPENDIDO", "REPOSO MEDICO", "COMISION_SERVICIO"):
                disponible = False
                motivo_no_disponible = f"Estado: {agent['estado_laboral']}"

            cursor.execute("""
                SELECT TOP 1 ar.id, ar.ruta_id, r.nombre AS ruta_nombre, ls.nombre AS lugar_nombre
                FROM dbo.asignaciones_ruta ar
                LEFT JOIN dbo.rutas r ON r.id = ar.ruta_id
                LEFT JOIN dbo.lugares_servicio ls ON ls.id = ar.lugar_id
                WHERE ar.agente_id = ? AND ar.deleted_at IS NULL
                  AND ar.estado IN ('PENDIENTE', 'ACTIVA')
            """, agent_id)
            existing = cursor.fetchone()
            asignacion_actual = None
            if existing:
                disponible = False
                motivo_no_disponible = "Ya asignado"
                asignacion_actual = {
                    "ruta_id": int(existing[1]),
                    "ruta_nombre": existing[2] or "",
                    "lugar_nombre": existing[3] or "",
                }

            if disponible and estado_laboral == "ACTIVO":
                cursor.execute("""
                    SELECT TOP 1 ap.id FROM dbo.asignaciones_punto ap
                    WHERE ap.personal_id = ? AND ap.fecha_inicio <= ? AND (ap.fecha_fin IS NULL OR ap.fecha_fin >= ?)
                      AND ap.activo = 1 AND ap.estado IN ('ACTIVA', 'PENDIENTE')
                """, agent_id, today, today)
                if cursor.fetchone():
                    disponible = False
                    motivo_no_disponible = "Asignado en punto"

            puede_asignar_normal = disponible
            requiere_forzado = not disponible

            agents.append({
                "id": agent_id,
                "nombre_completo": agent["nombre_completo"],
                "nombres": agent["nombres"],
                "apellidos": agent["apellidos"],
                "cedula": agent["cedula"],
                "estado_laboral": agent["estado_laboral"],
                "grado": agent["grado"],
                "grupo": agent["grupo"],
                "tipo_servicio": agent["tipo_servicio"],
                "disponible": disponible,
                "motivo_no_disponible": motivo_no_disponible,
                "asignacion_actual": asignacion_actual,
                "puede_asignar_normal": puede_asignar_normal,
                "requiere_forzado": requiere_forzado,
            })

        total_pages = max(1, (total + limit - 1) // limit)
        return {
            "agentes": agents,
            "total": total,
            "page": page,
            "limit": limit,
            "total_pages": total_pages,
            "lugar_nombre": lugar_nombre,
            "ruta_nombre": ruta_nombre,
            "turno_nombre": turno_nombre,
            "catalogos": {
                "grupos": grupos,
                "grados": grados,
                "tipos_servicio": tipos_servicio,
                "estados": estados,
            },
        }


def validate_and_change_agent(data: dict, user_id: int, ip: str | None = None) -> dict:
    """Validate and apply an agent change. Returns validation result."""
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")

        distrito_id = int(data["distrito_id"])
        turno_id = int(data["turno_id"])
        ruta_id = int(data["ruta_id"])
        lugar_id = int(data["lugar_id"])
        nuevo_id = int(data["agente_nuevo_id"])
        anterior_id = int(data.get("agente_anterior_id"))
        forzado = bool(data.get("forzado", False))
        motivo = data.get("motivo_forzado")

        cursor.execute("SELECT nombre, hora_inicio, hora_fin FROM dbo.turnos WHERE id = ? AND activo = 1", turno_id)
        turno = _row(cursor)
        if not turno:
            raise HTTPException(422, "El turno seleccionado no es valido")
        turno_nombre = turno["nombre"]

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE id = ? AND estado = 1", distrito_id)
        if not cursor.fetchone():
            raise HTTPException(422, "El distrito seleccionado no es valido")

        cursor.execute("""
            SELECT ls.id, ls.nombre, r.id AS ruta_id, r.nombre AS ruta_nombre
            FROM dbo.lugares_servicio ls
            INNER JOIN dbo.rutas r ON r.id = ls.ruta_id AND r.activo = 1
            WHERE ls.id = ? AND ls.ruta_id = ? AND ls.activo = 1
        """, lugar_id, ruta_id)
        lugar = _row(cursor)
        if not lugar:
            raise HTTPException(422, "El lugar de servicio no es valido")

        cursor.execute("""
            SELECT p.id, LTRIM(RTRIM(ISNULL(g.nombre + ' ', '') + ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                   p.cedula, ISNULL(ep.nombre, 'SIN ESTADO') AS estado_laboral
            FROM dbo.personal p
            LEFT JOIN dbo.catalogo_detalles ep ON ep.id = p.estado_personal_id
            LEFT JOIN dbo.grados g ON g.id = p.grado_id
            INNER JOIN dbo.roles r ON r.id = p.rol_id AND r.activo = 1
            WHERE p.id = ? AND p.activo = 1
              AND UPPER(ISNULL(r.codigo, '')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')
        """, nuevo_id)
        nuevo = _row(cursor)
        if not nuevo:
            raise HTTPException(422, "El agente seleccionado no existe o no esta habilitado")

        estado_nuevo = str(nuevo["estado_laboral"]).upper()
        es_estado_no_disponible = estado_nuevo in ("VACACIONES", "FRANCO", "PERMISO", "INCAPACIDAD", "AUSENTE", "SUSPENDIDO", "REPOSO MEDICO", "COMISION_SERVICIO")

        if es_estado_no_disponible and not forzado:
            raise HTTPException(409, f"El agente se encuentra en estado '{nuevo['estado_laboral']}'. Debe forzar la asignacion.")

        if forzado and not motivo:
            raise HTTPException(422, "Debe especificar el motivo de la asignacion forzada")

        cursor.execute("""
            SELECT TOP 1 ar.id, r.nombre AS ruta_nombre, ls.nombre AS lugar_nombre
            FROM dbo.asignaciones_ruta ar
            LEFT JOIN dbo.rutas r ON r.id = ar.ruta_id
            LEFT JOIN dbo.lugares_servicio ls ON ls.id = ar.lugar_id
            WHERE ar.agente_id = ? AND ar.deleted_at IS NULL
              AND ar.estado IN ('PENDIENTE', 'ACTIVA')
        """, nuevo_id)
        duplicado = cursor.fetchone()
        if duplicado:
            if not forzado:
                raise HTTPException(409, f"El agente ya esta asignado en: {duplicado[1]} - {duplicado[2]}")
            else:
                raise HTTPException(409, f"El agente ya esta asignado en: {duplicado[1]} - {duplicado[2]}. No se puede duplicar un agente en dos lugares simultaneamente.")

        if forzado:
            cursor.execute("SELECT id FROM dbo.permisos WHERE codigo = 'distribucion.forzar_asignacion' AND activo = 1")
            perm_row = cursor.fetchone()
            if perm_row:
                perm_id = int(perm_row[0])
                cursor.execute("SELECT id FROM dbo.roles WHERE id = (SELECT rol_id FROM dbo.personal WHERE id = ?)", user_id)
                user_role = cursor.fetchone()
                if user_role:
                    cursor.execute("SELECT permitido FROM dbo.rol_permiso WHERE rol_id = ? AND permiso_id = ?", int(user_role[0]), perm_id)
                    rp = cursor.fetchone()
                    if not rp or not rp[0]:
                        raise HTTPException(403, "No tiene permiso para realizar asignaciones forzadas")

            _audit(cursor, user_id, "ASIGNACION_FORZADA", str(nuevo_id), {
                "agente_id": nuevo_id,
                "agente_nombre": nuevo["nombre_completo"],
                "estado_original": nuevo["estado_laboral"],
                "lugar_id": lugar_id,
                "lugar_nombre": lugar["nombre"],
                "ruta_id": ruta_id,
                "ruta_nombre": lugar["ruta_nombre"],
                "turno": turno_nombre,
                "motivo": motivo,
                "distrito_id": distrito_id,
            })

        return {
            "ok": True,
            "agente_nuevo": {
                "id": int(nuevo["id"]),
                "nombre_completo": nuevo["nombre_completo"],
                "cedula": nuevo["cedula"],
                "estado_laboral": nuevo["estado_laboral"],
            },
            "lugar": {"id": int(lugar["id"]), "nombre": lugar["nombre"], "ruta_nombre": lugar["ruta_nombre"]},
            "turno": turno_nombre,
            "forzado": forzado,
            "estado_original": nuevo["estado_laboral"] if forzado else None,
            "motivo_forzado": motivo if forzado else None,
        }


def delete_distribution(distribution_id: int, user_id: int, ip: str | None = None) -> None:
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        cursor.execute("""
            SELECT id FROM dbo.distribuciones_personal WITH (UPDLOCK, HOLDLOCK)
            WHERE id=? AND deleted_at IS NULL
        """, distribution_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La distribucion no existe")
        cursor.execute("""
            UPDATE ar SET estado='CANCELADA', deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.distribucion_personal_detalle dd ON dd.asignacion_ruta_id=ar.id
            WHERE dd.distribucion_id=? AND ar.deleted_at IS NULL
        """, distribution_id)
        cursor.execute("UPDATE dbo.distribucion_personal_detalle SET deleted_at=SYSDATETIME() WHERE distribucion_id=? AND deleted_at IS NULL", distribution_id)
        cursor.execute("""
            UPDATE dbo.distribuciones_personal
            SET estado='ELIMINADA', eliminado_por=?, deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            WHERE id=?
        """, user_id, distribution_id)
        _audit(cursor, user_id, "ELIMINAR_DISTRIBUCION", str(distribution_id), {"ip": ip})


def get_distributions_dashboard() -> dict:
    """List all active distributions with completeness analysis per district."""
    with get_connection() as connection:
        cursor = connection.cursor()

        cursor.execute("""
            SELECT dp.id, dp.nombre, dp.fecha_distribucion, dp.estado,
                   dp.porcentaje_cobertura, dp.total_requerido, dp.total_asignado,
                   dp.fecha_creacion,
                   d.id AS distrito_id, d.nombre AS distrito,
                   t.id AS turno_id, t.nombre AS turno,
                   vp.nombre_completo AS creado_por
            FROM dbo.distribuciones_personal dp
            INNER JOIN dbo.catalogo_detalles d ON d.id = dp.distrito_id
            INNER JOIN dbo.turnos t ON t.id = dp.turno_id
            LEFT JOIN dbo.vw_personal_detalle vp ON vp.id = dp.creado_por
            WHERE dp.deleted_at IS NULL
            ORDER BY dp.fecha_creacion DESC
        """)
        distributions = _rows(cursor)

        result = []
        for dist in distributions:
            dist_id = int(dist["id"])

            cursor.execute("""
                SELECT dd.ruta_id, r.nombre AS ruta, dd.lugar_id, ls.nombre AS lugar,
                       dd.cantidad_requerida, dd.agente_id, vp.nombre_completo AS agente,
                       dd.tipo_asignacion, dd.estado AS detalle_estado
                FROM dbo.distribucion_personal_detalle dd
                INNER JOIN dbo.rutas r ON r.id = dd.ruta_id
                INNER JOIN dbo.lugares_servicio ls ON ls.id = dd.lugar_id
                LEFT JOIN dbo.vw_personal_detalle vp ON vp.id = dd.agente_id
                WHERE dd.distribucion_id = ? AND dd.deleted_at IS NULL
                ORDER BY r.nombre, ls.nombre
            """, dist_id)
            detalles = _rows(cursor)

            by_ruta: dict[int, dict] = {}
            for det in detalles:
                rid = int(det["ruta_id"])
                if rid not in by_ruta:
                    by_ruta[rid] = {"ruta_id": rid, "ruta": det["ruta"], "lugares": [], "requerido": 0, "asignado": 0, "pendiente": 0}
                lugar_info = {
                    "lugar_id": int(det["lugar_id"]), "lugar": det["lugar"],
                    "requerido": int(det["cantidad_requerida"] or 0),
                    "agente_id": int(det["agente_id"]) if det["agente_id"] else None,
                    "agente": det["agente"], "tipo_asignacion": det["tipo_asignacion"],
                    "estado": det["detalle_estado"],
                }
                by_ruta[rid]["lugares"].append(lugar_info)
                by_ruta[rid]["requerido"] += lugar_info["requerido"]
                if lugar_info["agente_id"]:
                    by_ruta[rid]["asignado"] += 1
                else:
                    by_ruta[rid]["pendiente"] += 1

            rutas = list(by_ruta.values())
            total_requerido = int(dist["total_requerido"] or 0)
            total_asignado = int(dist["total_asignado"] or 0)
            pendientes = max(0, total_requerido - total_asignado)
            incompletas = []
            for ruta in rutas:
                for lugar in ruta["lugares"]:
                    if not lugar["agente_id"]:
                        incompletas.append({
                            "ruta": ruta["ruta"], "lugar": lugar["lugar"],
                            "requerido": lugar["requerido"],
                        })

            es_completa = pendientes == 0 and total_requerido > 0
            result.append({
                "id": dist_id,
                "nombre": dist["nombre"],
                "fecha_distribucion": str(dist["fecha_distribucion"]) if dist["fecha_distribucion"] else None,
                "estado": dist["estado"],
                "porcentaje_cobertura": float(dist["porcentaje_cobertura"] or 0),
                "total_requerido": total_requerido,
                "total_asignado": total_asignado,
                "pendientes": pendientes,
                "fecha_creacion": str(dist["fecha_creacion"]) if dist["fecha_creacion"] else None,
                "distrito": dist["distrito"],
                "turno": dist["turno"],
                "creado_por": dist["creado_por"],
                "es_completa": es_completa,
                "rutas": rutas,
                "lugares_pendientes": incompletas,
                "total_rutas": len(rutas),
                "rutas_completas": sum(1 for r in rutas if r["pendiente"] == 0),
            })

        return {"distribuciones": result}
