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
            SELECT s.id, s.nombre, s.cantidad_agentes_requeridos, s.orden_distribucion,
                   s.distrito_id, s.ruta_id,
                   (SELECT COUNT(*) FROM dbo.asignaciones_ruta ar
                    WHERE ar.sector_id = s.id AND ar.estado IN ('PENDIENTE', 'ACTIVA')
                    AND ar.deleted_at IS NULL) AS agentes_asignados
            FROM dbo.sectores s
            WHERE s.activo = 1 AND s.ruta_id = ?
            ORDER BY s.orden_distribucion, s.nombre
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
                (SELECT COUNT(*) FROM dbo.sectores WHERE ruta_id = ? AND activo = 1) AS total_sectores,
                (SELECT ISNULL(SUM(cantidad_agentes_requeridos), 0) FROM dbo.sectores WHERE ruta_id = ? AND activo = 1) AS agentes_requeridos,
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
            SELECT vp.id, vp.nombre_completo, vp.cedula, vp.cargo, vp.area,
                   vp.estado_personal, vp.grado_id, vp.funcion_operativa_id
            FROM dbo.vw_personal_detalle vp
            WHERE vp.estado_personal = 'ACTIVO'
              AND vp.id NOT IN (
                  SELECT ar.agente_id FROM dbo.asignaciones_ruta ar
                  WHERE ar.fecha_asignacion = ? AND ar.estado IN ('PENDIENTE', 'ACTIVA')
                    AND ar.deleted_at IS NULL
                    AND ar.hora_inicio < ? AND ar.hora_fin > ?
              )
              AND vp.id NOT IN (
                  SELECT ap.personal_id FROM dbo.asignaciones_punto ap
                  WHERE ap.fecha_inicio <= ? AND (ap.fecha_fin IS NULL OR ap.fecha_fin >= ?)
                    AND ap.activo = 1 AND ap.estado IN ('ACTIVA', 'PENDIENTE')
                    AND ap.hora_inicio < ? AND ap.hora_fin > ?
              )
              AND vp.id NOT IN (
                  SELECT ae.personal_id FROM dbo.evento_personal ae
                  INNER JOIN dbo.eventos e ON e.id = ae.evento_id
                  WHERE ae.fecha_asignacion = ?
                    AND e.fecha >= ?
                    AND e.fecha <= ?
              )
            ORDER BY vp.nombre_completo
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
                   ar.sector_id, s.nombre AS sector_nombre,
                   ar.fecha_asignacion, ar.turno, ar.hora_inicio, ar.hora_fin,
                   ar.estado, ar.tipo_asignacion, ar.sorteo_id, ar.observacion,
                   ar.fecha_creacion
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.vw_personal_detalle vp ON vp.id = ar.agente_id
            INNER JOIN dbo.sectores s ON s.id = ar.sector_id
            WHERE ar.ruta_id = ? AND ar.fecha_asignacion = ? AND ar.turno = ?
              AND ar.deleted_at IS NULL
            ORDER BY s.orden_distribucion, s.nombre, vp.nombre_completo
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
                UPDATE dbo.sectores
                SET cantidad_agentes_requeridos = ?, actualizado_por = ?, fecha_actualizacion = SYSDATETIME()
                WHERE id = ? AND ruta_id = ? AND activo = 1
            """, item["cantidad_agentes_requeridos"], user_id, item["sector_id"], route_id)
            updated += cursor.rowcount
        _audit(cursor, user_id, "CONFIGURAR_REQUERIMIENTO", f"config-{route_id}", {
            "ruta_id": route_id, "sectores_actualizados": updated
        })
        return {"sectores_actualizados": updated}
