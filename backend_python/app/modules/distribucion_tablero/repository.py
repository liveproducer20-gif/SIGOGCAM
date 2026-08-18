import json
import random
import uuid
from datetime import date, datetime, time
from decimal import Decimal

from fastapi import HTTPException

from app.core.db import get_connection
from app.core.sanitize import escape_like


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
            SELECT r.id, r.nombre, r.distrito_id, r.hora_inicio, r.hora_fin,
                   d.nombre AS distrito
            FROM dbo.rutas r
            INNER JOIN dbo.catalogo_detalles d ON d.id = r.distrito_id
            WHERE r.id = ? AND r.activo = 1
        """, route_id)
        route = _row(cursor)
        if not route:
            raise HTTPException(404, "La ruta no existe o no esta activa")
        # Attach turns from junction table
        cursor.execute("""
            SELECT t.id, t.nombre
            FROM dbo.ruta_turnos rt
            INNER JOIN dbo.turnos t ON t.id = rt.turno_id
            WHERE rt.ruta_id = ?
            ORDER BY t.id
        """, route_id)
        turns = [{"turno_id": int(r[0]), "turno": str(r[1])} for r in cursor.fetchall()]
        route["turnos"] = turns
        route["turno_id"] = turns[0]["turno_id"] if turns else None
        route["turno"] = ", ".join(t["turno"] for t in turns) if turns else None
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
        where: list[str] = []
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
            {'WHERE ' + ' AND '.join(where) if where else ''}
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


def get_board_data(district_id: int, shift_id: int, distribution_date: date | None = None) -> dict:
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
            SELECT d.id, d.nombre, CAST(1 AS bit) AS asignar_encargado
            FROM dbo.catalogo_detalles d
            WHERE d.id = ? AND d.estado = 1
        """, district_id)
        district = _row(cursor)
        if not district:
            raise HTTPException(404, "El distrito seleccionado no existe o no esta activo")

        if _is_eas_district(cursor, district_id):
            slots = _eas_slots(cursor, district_id, shift_id)
            cursor.execute("""
                SELECT DISTINCT e.id,e.codigo,e.nombre
                FROM dbo.circuito_eas ce
                INNER JOIN dbo.circuitos c ON c.id=ce.circuito_id AND c.distrito_id=? AND c.activo=1 AND c.deleted_at IS NULL
                INNER JOIN dbo.eas_estaciones e ON e.id=ce.eas_id AND e.activo=1
                ORDER BY e.codigo,e.nombre
            """, district_id)
            eas_list = _rows(cursor)
            routes_by_key: dict[tuple[int, int], dict] = {}
            circuits_by_id: dict[int, dict] = {}
            for slot in slots:
                circuits_by_id.setdefault(int(slot["circuito_id"]), {
                    "id": slot["circuito_id"], "nombre": slot["circuito"],
                    "hora_inicio": None, "hora_fin": None, "lugar_formacion": None,
                })
                key = (int(slot["eas_id"]), int(slot["ruta_id"]))
                route = routes_by_key.setdefault(key, {
                    "id": slot["ruta_id"], "nombre": slot["ruta"], "distrito_id": district_id,
                    "circuito_id": slot["circuito_id"], "circuito": slot["circuito"],
                    "eas_id": slot["eas_id"], "eas_nombre": slot["eas_nombre"],
                    "asignar_encargado": False, "lugares": 0,
                    "hora_inicio": slot["hora_inicio"], "hora_fin": slot["hora_fin"], "configuraciones": [],
                })
                route["configuraciones"].append({
                    "id": slot["configuracion_id"], "movil_id": slot["configuracion_movil_id"],
                    "movil_informativo_id": slot["movil_id"],
                    "numero_movil": slot["numero_movil"], "placa": slot["placa"],
                    "orden": slot["orden"], "virtual": slot["configuracion_id"] is None,
                    "sin_movil_configurado": slot["configuracion_movil_id"] is None,
                })
            return {"distrito": district, "turno": shift, "modo_eas": True,
                    "eas": eas_list, "circuitos": list(circuits_by_id.values()), "moviles": [],
                    "rutas": list(routes_by_key.values()), "fecha_distribucion": distribution_date,
                    "distribucion_id": _distribution_id(cursor, district_id, shift_id, distribution_date),
                    "encargados": []}

        cursor.execute("""
            SELECT r.id, r.nombre, r.distrito_id,
                   CAST(CASE
                       WHEN r.asignar_encargado = 1 OR MAX(CASE
                           WHEN UPPER(LTRIM(RTRIM(ISNULL(ls.nombre, '')))) = N'ENCARGADO DE RUTA' THEN 1
                           ELSE 0
                       END) = 1 THEN 1 ELSE 0
                   END AS bit) AS asignar_encargado,
                   cr.circuito_id, c.nombre AS circuito,
                   COALESCE(r.hora_inicio, t.hora_inicio) AS hora_inicio,
                   COALESCE(r.hora_fin, t.hora_fin) AS hora_fin,
                   SUM(CASE
                       WHEN ls.id IS NOT NULL
                        AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre, '')))) <> N'ENCARGADO DE RUTA'
                       THEN 1 ELSE 0
                   END) AS lugares
            FROM dbo.rutas r
            INNER JOIN dbo.ruta_turnos rt ON rt.ruta_id = r.id AND rt.turno_id = ?
            LEFT JOIN dbo.circuito_rutas cr ON cr.ruta_id=r.id AND cr.deleted_at IS NULL
            LEFT JOIN dbo.circuitos c ON c.id=cr.circuito_id AND c.activo=1 AND c.deleted_at IS NULL
            LEFT JOIN dbo.turnos t ON t.id = ?
            LEFT JOIN dbo.lugares_servicio ls ON ls.ruta_id = r.id AND ls.activo = 1
                AND EXISTS (
                    SELECT 1 FROM dbo.lugar_turnos lt
                    WHERE lt.lugar_servicio_id = ls.id AND lt.turno_id = ?
                )
            WHERE r.activo = 1 AND r.distrito_id = ?
            GROUP BY r.id, r.nombre, r.distrito_id, r.asignar_encargado, cr.circuito_id, c.nombre,
                     COALESCE(r.hora_inicio, t.hora_inicio), COALESCE(r.hora_fin, t.hora_fin)
            ORDER BY r.nombre
        """, shift_id, shift_id, shift_id, district_id)
        routes = _rows(cursor)
        cursor.execute("""
            SELECT c.id,c.nombre,c.hora_inicio,c.hora_fin,c.lugar_formacion
            FROM dbo.circuitos c
            WHERE c.distrito_id=? AND c.activo=1 AND c.deleted_at IS NULL
            ORDER BY c.nombre
        """, district_id)
        circuits = _rows(cursor)
        cursor.execute("""
            SELECT m.id,m.numero_movil,m.placa,tm.nombre AS tipo_movil,em.nombre AS estado_movil
            FROM dbo.moviles m
            LEFT JOIN dbo.catalogo_detalles tm ON tm.id=m.tipo_movil_id
            LEFT JOIN dbo.catalogo_detalles em ON em.id=m.estado_movil_id
            WHERE m.activo=1 ORDER BY m.numero_movil
        """)
        mobiles = _rows(cursor)
        distribution_id = None
        managers: list[dict] = []
        if distribution_date is not None:
            cursor.execute("""
                SELECT TOP 1 id FROM dbo.distribuciones_personal
                WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=? AND deleted_at IS NULL
            """, district_id, shift_id, distribution_date)
            saved = cursor.fetchone()
            if saved:
                distribution_id = int(saved[0])
                cursor.execute("""
                    SELECT de.id, de.tipo_responsabilidad, de.ruta_id, de.circuito_id,
                           de.requiere_encargado,de.usar_encargado_distrito,
                           de.agente_id,de.conductor_id,de.auxiliar_1_id,de.auxiliar_2_id,de.movil_id,
                           de.tipo_asignacion, vp.nombre_completo AS agente, vp.cedula,
                           cd.nombre_completo AS conductor,gd.nombre AS conductor_grado,
                           a1.nombre_completo AS auxiliar_1,g1.nombre AS auxiliar_1_grado,
                           a2.nombre_completo AS auxiliar_2,g2.nombre AS auxiliar_2_grado,
                           m.numero_movil,m.placa
                    FROM dbo.distribucion_encargados de
                    LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=de.agente_id
                    LEFT JOIN dbo.vw_personal_detalle cd ON cd.id=de.conductor_id
                    LEFT JOIN dbo.personal pcd ON pcd.id=de.conductor_id LEFT JOIN dbo.grados gd ON gd.id=pcd.grado_id
                    LEFT JOIN dbo.vw_personal_detalle a1 ON a1.id=de.auxiliar_1_id
                    LEFT JOIN dbo.personal pa1 ON pa1.id=de.auxiliar_1_id LEFT JOIN dbo.grados g1 ON g1.id=pa1.grado_id
                    LEFT JOIN dbo.vw_personal_detalle a2 ON a2.id=de.auxiliar_2_id
                    LEFT JOIN dbo.personal pa2 ON pa2.id=de.auxiliar_2_id LEFT JOIN dbo.grados g2 ON g2.id=pa2.grado_id
                    LEFT JOIN dbo.moviles m ON m.id=de.movil_id
                    WHERE de.distribucion_id=? AND de.deleted_at IS NULL
                    ORDER BY CASE WHEN de.tipo_responsabilidad='ENCARGADO_DISTRITO' THEN 0 ELSE 1 END, de.ruta_id
                """, distribution_id)
                managers = _rows(cursor)
        return {"distrito": district, "turno": shift, "circuitos": circuits, "moviles": mobiles, "rutas": routes,
                "fecha_distribucion": distribution_date, "distribucion_id": distribution_id,
                "encargados": managers}


def _is_eas_district(cursor, district_id: int) -> bool:
    cursor.execute("""
        SELECT 1 FROM dbo.catalogo_detalles
        WHERE id=? AND UPPER(LTRIM(RTRIM(nombre))) COLLATE Latin1_General_100_CI_AI=N'ESTACION DE ACCION SEGURA'
    """, district_id)
    return bool(cursor.fetchone())


def _distribution_id(cursor, district_id: int, shift_id: int, distribution_date: date | None) -> int | None:
    if distribution_date is None:
        return None
    cursor.execute("""SELECT TOP 1 id FROM dbo.distribuciones_personal
                      WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=? AND deleted_at IS NULL""",
                   district_id, shift_id, distribution_date)
    row = cursor.fetchone()
    return int(row[0]) if row else None


def _eas_slots(cursor, district_id: int, shift_id: int) -> list[dict]:
    """One row per active configuration; a route without one gets a virtual slot."""
    cursor.execute("""
        SELECT ce.eas_id,e.nombre AS eas_nombre,cr.circuito_id,c.nombre AS circuito,
               r.id AS ruta_id,r.nombre AS ruta,COALESCE(r.hora_inicio,t.hora_inicio) AS hora_inicio,
               COALESCE(r.hora_fin,t.hora_fin) AS hora_fin,
               ec.id AS configuracion_id,ec.movil_id AS configuracion_movil_id,
               COALESCE(ec.movil_id,CASE WHEN ec.id IS NULL THEN mea.movil_id END) AS movil_id,
               ec.orden,CASE WHEN ec.id IS NULL THEN fm.numero_movil ELSE m.numero_movil END AS numero_movil,
               CASE WHEN ec.id IS NULL THEN fm.placa ELSE m.placa END AS placa
        FROM dbo.circuito_eas ce
        INNER JOIN dbo.eas_estaciones e ON e.id=ce.eas_id AND e.activo=1
        INNER JOIN dbo.circuitos c ON c.id=ce.circuito_id AND c.distrito_id=? AND c.activo=1 AND c.deleted_at IS NULL
        INNER JOIN dbo.circuito_rutas cr ON cr.circuito_id=c.id AND cr.deleted_at IS NULL
        INNER JOIN dbo.rutas r ON r.id=cr.ruta_id AND r.activo=1 AND r.distrito_id=?
        INNER JOIN dbo.ruta_turnos rt ON rt.ruta_id=r.id AND rt.turno_id=?
        LEFT JOIN dbo.turnos t ON t.id=?
        LEFT JOIN dbo.eas_ruta_configuraciones ec ON ec.eas_id=e.id AND ec.ruta_id=r.id AND ec.activo=1
        LEFT JOIN dbo.moviles m ON m.id=ec.movil_id AND m.activo=1
        OUTER APPLY (SELECT TOP 1 a.movil_id FROM dbo.movil_eas_asignaciones a
                     WHERE a.eas_id=e.id AND a.activo=1 ORDER BY a.fecha_asignacion DESC,a.id DESC) mea
        LEFT JOIN dbo.moviles fm ON fm.id=mea.movil_id AND fm.activo=1
        ORDER BY e.nombre,c.nombre,r.nombre,ISNULL(ec.orden,0),ec.id
    """, district_id, district_id, shift_id, shift_id)
    return _rows(cursor)


def get_district_distribution_summaries(distribution_date: date) -> list[dict]:
    """Return saved, cross-shift progress without using browser draft assignments."""
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT d.id,d.nombre
            FROM dbo.catalogo_detalles d
            INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id AND c.codigo='DISTRITOS' AND c.estado=1
            WHERE d.estado=1 ORDER BY d.orden,d.nombre
        """)
        districts = _rows(cursor)
        cursor.execute("SELECT id,nombre FROM dbo.turnos WHERE activo=1 ORDER BY id")
        shifts = _rows(cursor)
        cursor.execute("""
            SELECT c.id,c.distrito_id,c.nombre
            FROM dbo.circuitos c
            WHERE c.activo=1 AND c.deleted_at IS NULL ORDER BY c.distrito_id,c.nombre
        """)
        circuits = _rows(cursor)
        cursor.execute("""
            SELECT r.id,r.distrito_id,r.nombre,r.asignar_encargado,
                   cr.circuito_id,
                   CAST(CASE WHEN EXISTS(
                       SELECT 1 FROM dbo.lugares_servicio er
                       WHERE er.ruta_id=r.id AND er.activo=1
                         AND UPPER(LTRIM(RTRIM(ISNULL(er.nombre,''))))=N'ENCARGADO DE RUTA'
                   ) THEN 1 ELSE 0 END AS bit) AS tiene_encargado_tecnico
            FROM dbo.rutas r
            LEFT JOIN dbo.circuito_rutas cr ON cr.ruta_id=r.id AND cr.deleted_at IS NULL
            WHERE r.activo=1 ORDER BY r.distrito_id,r.nombre
        """)
        routes = _rows(cursor)
        # Attach turn data from junction table for each route
        route_ids = [int(r["id"]) for r in routes]
        route_turns: dict[int, set[int]] = {}
        if route_ids:
            placeholders = ",".join("?" for _ in route_ids)
            for rt in cursor.execute(
                f"SELECT ruta_id,turno_id FROM dbo.ruta_turnos WHERE ruta_id IN ({placeholders})",
                *route_ids,
            ).fetchall():
                route_turns.setdefault(int(rt[0]), set()).add(int(rt[1]))
        for r in routes:
            r["turno_ids"] = list(route_turns.get(int(r["id"]), set()))
        cursor.execute("""
            SELECT ls.id,ls.ruta_id,ls.nombre,
                   CASE WHEN ls.cantidad_requerida<0 THEN 0 ELSE ls.cantidad_requerida END AS cantidad_requerida
            FROM dbo.lugares_servicio ls
            WHERE ls.activo=1
              AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre,''))))<>N'ENCARGADO DE RUTA'
            ORDER BY ls.ruta_id,ls.nombre
        """)
        places = _rows(cursor)
        # Attach turn data from junction table for each place
        place_ids = [int(p["id"]) for p in places]
        place_turns: dict[int, set[int]] = {}
        if place_ids:
            placeholders = ",".join("?" for _ in place_ids)
            for lt in cursor.execute(
                f"SELECT lugar_servicio_id,turno_id FROM dbo.lugar_turnos WHERE lugar_servicio_id IN ({placeholders})",
                *place_ids,
            ).fetchall():
                place_turns.setdefault(int(lt[0]), set()).add(int(lt[1]))
        for p in places:
            p["turno_ids"] = list(place_turns.get(int(p["id"]), set()))
        cursor.execute("""
            SELECT id,distrito_id,turno_id,total_requerido,total_asignado
            FROM dbo.distribuciones_personal
            WHERE fecha_distribucion=? AND deleted_at IS NULL
        """, distribution_date)
        saved = _rows(cursor)
        distribution_ids = [int(item["id"]) for item in saved]
        details: list[dict] = []
        responsibilities: list[dict] = []
        if distribution_ids:
            placeholders = ",".join("?" * len(distribution_ids))
            cursor.execute(f"""
                SELECT dd.distribucion_id,dd.ruta_id,dd.lugar_id,
                       SUM(CASE WHEN dd.agente_id IS NOT NULL AND dd.deleted_at IS NULL THEN 1 ELSE 0 END) AS asignados
                FROM dbo.distribucion_personal_detalle dd
                WHERE dd.distribucion_id IN ({placeholders}) AND dd.deleted_at IS NULL
                GROUP BY dd.distribucion_id,dd.ruta_id,dd.lugar_id
            """, *distribution_ids)
            details = _rows(cursor)
            cursor.execute(f"""
                SELECT distribucion_id,tipo_responsabilidad,circuito_id,ruta_id,requiere_encargado,
                       agente_id,conductor_id,auxiliar_1_id,movil_id
                FROM dbo.distribucion_encargados
                WHERE distribucion_id IN ({placeholders}) AND deleted_at IS NULL
            """, *distribution_ids)
            responsibilities = _rows(cursor)

    circuits_by_district: dict[int, list[dict]] = {}
    routes_by_district: dict[int, list[dict]] = {}
    places_by_route: dict[int, list[dict]] = {}
    saved_by_key = {(int(item["distrito_id"]), int(item["turno_id"])): item for item in saved}
    details_by_distribution: dict[int, dict[int, int]] = {}
    responsibilities_by_distribution: dict[int, list[dict]] = {}
    for item in circuits:
        circuits_by_district.setdefault(int(item["distrito_id"]), []).append(item)
    for item in routes:
        routes_by_district.setdefault(int(item["distrito_id"]), []).append(item)
    for item in places:
        places_by_route.setdefault(int(item["ruta_id"]), []).append(item)
    for item in details:
        details_by_distribution.setdefault(int(item["distribucion_id"]), {})[int(item["lugar_id"])] = int(item["asignados"] or 0)
    for item in responsibilities:
        responsibilities_by_distribution.setdefault(int(item["distribucion_id"]), []).append(item)

    result: list[dict] = []
    for district in districts:
        district_id = int(district["id"])
        district_circuits = circuits_by_district.get(district_id, [])
        district_routes = routes_by_district.get(district_id, [])
        shift_results: list[dict] = []
        total_required = 0
        total_assigned = 0
        for shift in shifts:
            shift_id = int(shift["id"])
            distribution = saved_by_key.get((district_id, shift_id))
            distribution_id = int(distribution["id"]) if distribution else 0
            saved_places = details_by_distribution.get(distribution_id, {})
            saved_responsibilities = responsibilities_by_distribution.get(distribution_id, [])
            applicable_routes = [item for item in district_routes if not item.get("turno_ids") or shift_id in item["turno_ids"]]
            applicable_route_ids = {int(item["id"]) for item in applicable_routes}
            applicable_places = [place for route_id in applicable_route_ids for place in places_by_route.get(route_id, [])
                                 if not place.get("turno_ids") or shift_id in place["turno_ids"]]
            required = sum(int(item["cantidad_requerida"] or 0) for item in applicable_places)
            assigned = sum(min(int(item["cantidad_requerida"] or 0), saved_places.get(int(item["id"]), 0)) for item in applicable_places)
            total_required += required
            total_assigned += assigned

            district_resp = next((item for item in saved_responsibilities if item["tipo_responsabilidad"] == "ENCARGADO_DISTRITO"), None)
            district_resources_complete = bool(district_resp and district_resp["agente_id"] and district_resp["movil_id"]
                                               and district_resp["conductor_id"] and district_resp["auxiliar_1_id"])
            circuit_pending: list[dict] = []
            for circuit in district_circuits:
                circuit_id = int(circuit["id"])
                circuit_resp = next((item for item in saved_responsibilities
                                     if item["tipo_responsabilidad"] == "ENCARGADO_CIRCUITO"
                                     and int(item["circuito_id"] or 0) == circuit_id), None)
                resource_complete = bool(circuit_resp and circuit_resp["agente_id"] and circuit_resp["movil_id"]
                                         and circuit_resp["conductor_id"] and circuit_resp["auxiliar_1_id"])
                route_pending: list[dict] = []
                for route in [item for item in applicable_routes if int(item["circuito_id"] or 0) == circuit_id]:
                    route_id = int(route["id"])
                    pending_places = []
                    for place in [item for item in applicable_places if int(item["ruta_id"]) == route_id]:
                        place_required = int(place["cantidad_requerida"] or 0)
                        place_assigned = min(place_required, saved_places.get(int(place["id"]), 0))
                        if place_assigned < place_required:
                            pending_places.append({"id": int(place["id"]), "nombre": place["nombre"],
                                                   "requerido": place_required, "asignado": place_assigned,
                                                   "faltan": place_required - place_assigned})
                    requires_manager = bool(route["asignar_encargado"] or route["tiene_encargado_tecnico"])
                    route_resp = next((item for item in saved_responsibilities
                                      if item["tipo_responsabilidad"] == "ENCARGADO_RUTA"
                                      and int(item["ruta_id"] or 0) == route_id), None)
                    manager_pending = requires_manager and not route_resp
                    if route_resp and route_resp["requiere_encargado"] and not route_resp["agente_id"]:
                        manager_pending = True
                    if pending_places or manager_pending:
                        route_pending.append({"id": route_id, "nombre": route["nombre"],
                                              "encargado_pendiente": manager_pending, "lugares": pending_places})
                if not resource_complete or route_pending:
                    circuit_pending.append({"id": circuit_id, "nombre": circuit["nombre"],
                                            "recursos_pendientes": not resource_complete, "rutas": route_pending})
            ungrouped_pending: list[dict] = []
            for route in [item for item in applicable_routes if not item["circuito_id"]]:
                route_id = int(route["id"])
                pending_places = []
                for place in [item for item in applicable_places if int(item["ruta_id"]) == route_id]:
                    place_required = int(place["cantidad_requerida"] or 0)
                    place_assigned = min(place_required, saved_places.get(int(place["id"]), 0))
                    if place_assigned < place_required:
                        pending_places.append({"id": int(place["id"]), "nombre": place["nombre"],
                                               "requerido": place_required, "asignado": place_assigned,
                                               "faltan": place_required - place_assigned})
                requires_manager = bool(route["asignar_encargado"] or route["tiene_encargado_tecnico"])
                route_resp = next((item for item in saved_responsibilities
                                  if item["tipo_responsabilidad"] == "ENCARGADO_RUTA"
                                  and int(item["ruta_id"] or 0) == route_id), None)
                manager_pending = requires_manager and (not route_resp or (route_resp["requiere_encargado"] and not route_resp["agente_id"]))
                if pending_places or manager_pending:
                    ungrouped_pending.append({"id": route_id, "nombre": route["nombre"],
                                              "encargado_pendiente": manager_pending, "lugares": pending_places})
            if ungrouped_pending:
                circuit_pending.append({"id": 0, "nombre": "Rutas sin circuito",
                                        "recursos_pendientes": False, "rutas": ungrouped_pending})
            shift_complete = bool(distribution and district_resources_complete and not circuit_pending and assigned >= required)
            shift_results.append({"id": shift_id, "nombre": shift["nombre"], "completo": shift_complete,
                                  "guardado": bool(distribution), "requerido": required, "asignado": assigned,
                                  "encargado_distrito_pendiente": not district_resources_complete,
                                  "circuitos": circuit_pending})
        complete = bool(shift_results) and all(item["completo"] for item in shift_results)
        percentage = round((total_assigned / total_required * 100), 1) if total_required else 0
        result.append({"distrito_id": district_id, "nombre": district["nombre"],
                       "numero_circuitos": len(district_circuits), "puestos_requeridos": total_required,
                       "puestos_asignados": total_assigned, "porcentaje": percentage,
                       "estado_turnos": "COMPLETO" if complete else "TURNO_FALTANTE",
                       "turnos": shift_results})
    return result


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
              AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre, '')))) <> N'ENCARGADO DE RUTA'
              AND EXISTS (
                  SELECT 1 FROM dbo.lugar_turnos lt
                  WHERE lt.lugar_servicio_id = ls.id AND lt.turno_id = ?
              )
            ORDER BY ls.nombre
        """, route_id, shift_id)
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
    circuit_id = int(data["circuito_id"])
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    current = data.get("asignaciones") or []
    used = {int(item["agente_id"]) for item in current} | {int(item) for item in data.get("excluidos", []) if item}
    if len({int(item["agente_id"]) for item in current}) != len(current):
        raise HTTPException(409, "El borrador contiene agentes duplicados")

    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("""
            SELECT r.id
            FROM dbo.circuitos c
            INNER JOIN dbo.circuito_rutas cr ON cr.circuito_id=c.id AND cr.deleted_at IS NULL
            INNER JOIN dbo.rutas r ON r.id=cr.ruta_id AND r.activo=1
            INNER JOIN dbo.ruta_turnos rt ON rt.ruta_id=r.id AND rt.turno_id=?
            WHERE c.id=? AND c.distrito_id=? AND c.activo=1 AND c.deleted_at IS NULL
            ORDER BY r.nombre
        """, shift_id, circuit_id, district_id)
        route_ids = [int(row[0]) for row in cursor.fetchall()]
        if not route_ids:
            raise HTTPException(422, "El circuito no tiene rutas disponibles para el distrito y turno seleccionados")
        places = [place for route_id in route_ids for place in get_route_places(route_id, shift_id)]
        if not places:
            raise HTTPException(422, "El circuito no tiene lugares de servicio para este turno")
        agents = get_board_availability(district_id, shift_id, used)["agentes"]
        agents = [agent for agent in agents if str(agent.get("grado") or "").strip().upper() in {"AGENTE 1", "AGENTE 2", "AGENTE 3"}]
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
            "mensaje": "No existe suficiente personal de grado Agente 1, 2 o 3 para cubrir todo el circuito." if assigned_on_route < required else None,
        }


def _validate_distribution_relations(cursor, district_id: int, shift_id: int, assignments: list[dict]) -> tuple[list[dict], dict[int, dict]]:
    cursor.execute("""
        SELECT ls.id, ls.ruta_id, ls.distrito_id,
               CASE WHEN ls.cantidad_requerida < 0 THEN 0 ELSE ls.cantidad_requerida END AS cantidad_requerida,
               ls.nombre AS lugar, r.nombre AS ruta
        FROM dbo.lugares_servicio ls
        INNER JOIN dbo.rutas r ON r.id = ls.ruta_id AND r.activo = 1
        INNER JOIN dbo.ruta_turnos rt ON rt.ruta_id = r.id AND rt.turno_id = ?
        WHERE ls.activo = 1 AND r.distrito_id = ?
          AND EXISTS (
              SELECT 1 FROM dbo.lugar_turnos lt
              WHERE lt.lugar_servicio_id = ls.id AND lt.turno_id = ?
          )
            ORDER BY r.nombre, ls.nombre
    """, shift_id, district_id, shift_id)
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


def _validate_place_agent_grades(cursor, assignments: list[dict]) -> None:
    agent_ids = sorted({int(item["agente_id"]) for item in assignments})
    if not agent_ids:
        return
    placeholders = ",".join("?" * len(agent_ids))
    cursor.execute(f"""
        SELECT p.id, UPPER(ISNULL(g.nombre,'')) AS grado
        FROM dbo.personal p
        LEFT JOIN dbo.grados g ON g.id=p.grado_id
        WHERE p.id IN ({placeholders})
    """, *agent_ids)
    grades = {int(row[0]): str(row[1]) for row in cursor.fetchall()}
    invalid = [agent_id for agent_id in agent_ids if grades.get(agent_id) not in {"AGENTE 1", "AGENTE 2", "AGENTE 3"}]
    if invalid:
        raise HTTPException(422, "Los lugares de servicio solo permiten personal con grado Agente 1, Agente 2 o Agente 3")


def _prepare_responsibilities(cursor, district_id: int, shift_id: int, data: dict) -> tuple[list[dict], list[int]]:
    cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE id=? AND estado=1", district_id)
    district = cursor.fetchone()
    if not district:
        raise HTTPException(422, "El distrito seleccionado no es valido")

    district_manager_id = data.get("encargado_distrito_id")
    if not district_manager_id:
        raise HTTPException(422, "Debe asignar el encargado de distrito")
    district_manager_id = int(district_manager_id)
    district_mobile_id = int(data["distrito_movil_id"]) if data.get("distrito_movil_id") else None
    district_driver_id = int(data["distrito_conductor_id"]) if data.get("distrito_conductor_id") else None
    district_aux1_id = int(data["distrito_auxiliar_1_id"]) if data.get("distrito_auxiliar_1_id") else None
    district_aux2_id = int(data["distrito_auxiliar_2_id"]) if data.get("distrito_auxiliar_2_id") else None
    if not district_mobile_id or not district_driver_id or not district_aux1_id:
        raise HTTPException(422, "El encargado de distrito requiere movil, conductor y auxiliar 1")
    district_people = [district_manager_id, district_driver_id, district_aux1_id] + ([district_aux2_id] if district_aux2_id else [])
    if len(district_people) != len(set(district_people)):
        raise HTTPException(422, "No se puede repetir una persona dentro de los recursos del distrito")
    cursor.execute("SELECT id FROM dbo.moviles WHERE id=? AND activo=1", district_mobile_id)
    if not cursor.fetchone():
        raise HTTPException(422, "El movil seleccionado para el distrito no esta activo")
    responsibilities: list[dict] = []
    responsibilities.append({
        "tipo_responsabilidad": "ENCARGADO_DISTRITO", "ruta_id": None, "circuito_id": None,
        "requiere_encargado": True, "agente_id": district_manager_id,
        "conductor_id": district_driver_id, "auxiliar_1_id": district_aux1_id,
        "auxiliar_2_id": district_aux2_id, "movil_id": district_mobile_id,
        "usar_encargado_distrito": False, "tipo_asignacion": "MANUAL",
    })

    cursor.execute("""
        SELECT id,nombre FROM dbo.circuitos
        WHERE distrito_id=? AND activo=1 AND deleted_at IS NULL ORDER BY nombre
    """, district_id)
    enabled_circuits = {int(row[0]): str(row[1]) for row in cursor.fetchall()}
    circuit_inputs = data.get("encargados_circuito") or []
    circuit_map: dict[int, dict] = {}
    used_people: set[int] = set(district_people)
    used_mobiles: set[int] = {district_mobile_id}
    for item in circuit_inputs:
        circuit_id = int(item["circuito_id"])
        if circuit_id in circuit_map:
            raise HTTPException(422, f"El circuito {circuit_id} tiene un encargado duplicado")
        if circuit_id not in enabled_circuits:
            raise HTTPException(422, f"El circuito {circuit_id} no pertenece al distrito seleccionado")
        manager_id = int(item["agente_id"])
        conductor_id = int(item["conductor_id"]) if item.get("conductor_id") else None
        use_district = bool(item.get("usar_encargado_distrito"))
        if use_district and manager_id != district_manager_id:
            raise HTTPException(422, f"El encargado de {enabled_circuits[circuit_id]} debe coincidir con el encargado del distrito")
        auxiliar_1_id = int(item["auxiliar_1_id"]) if item.get("auxiliar_1_id") else None
        auxiliar_2_id = int(item["auxiliar_2_id"]) if item.get("auxiliar_2_id") else None
        mobile_id = int(item["movil_id"]) if item.get("movil_id") else None
        if not mobile_id or not conductor_id or not auxiliar_1_id:
            raise HTTPException(422, f"{enabled_circuits[circuit_id]} requiere movil, conductor y auxiliar 1")
        if use_district and (conductor_id != district_driver_id or auxiliar_1_id != district_aux1_id
                             or auxiliar_2_id != district_aux2_id or mobile_id != district_mobile_id):
            raise HTTPException(422, f"Los recursos de {enabled_circuits[circuit_id]} deben coincidir con los recursos del distrito")
        local_people = [person_id for person_id in (manager_id, conductor_id, auxiliar_1_id, auxiliar_2_id) if person_id]
        if len(local_people) != len(set(local_people)):
            raise HTTPException(422, f"No se puede repetir una persona dentro de {enabled_circuits[circuit_id]}")
        for person_id in local_people:
            if use_district and person_id in set(district_people):
                continue
            if person_id in used_people:
                raise HTTPException(409, f"El agente {person_id} ya tiene otra responsabilidad en la distribucion")
            used_people.add(person_id)
        cursor.execute("SELECT id FROM dbo.moviles WHERE id=? AND activo=1", mobile_id)
        if not cursor.fetchone():
            raise HTTPException(422, f"El movil seleccionado para {enabled_circuits[circuit_id]} no esta activo")
        if mobile_id in used_mobiles and not (use_district and mobile_id == district_mobile_id):
            raise HTTPException(409, f"El movil seleccionado para {enabled_circuits[circuit_id]} ya esta asignado")
        if not use_district:
            used_mobiles.add(mobile_id)
        circuit_map[circuit_id] = item
        responsibilities.append({
            "tipo_responsabilidad": "ENCARGADO_CIRCUITO", "ruta_id": None, "circuito_id": circuit_id,
            "requiere_encargado": True, "agente_id": manager_id,
            "conductor_id": conductor_id, "auxiliar_1_id": auxiliar_1_id,
            "auxiliar_2_id": auxiliar_2_id, "movil_id": mobile_id,
            "usar_encargado_distrito": use_district,
            "tipo_asignacion": str(item.get("tipo_asignacion") or "MANUAL").upper(),
        })

    cursor.execute("""
        SELECT id, nombre FROM dbo.rutas
        WHERE distrito_id=? AND activo=1
          AND (asignar_encargado=1 OR EXISTS (
              SELECT 1 FROM dbo.lugares_servicio ls
              WHERE ls.ruta_id=rutas.id AND ls.activo=1
                AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre,''))))=N'ENCARGADO DE RUTA'
          ))
          AND (turno_id IS NULL OR turno_id=?)
        ORDER BY nombre
    """, district_id, shift_id)
    enabled_routes = {int(row[0]): str(row[1]) for row in cursor.fetchall()}
    route_inputs = data.get("encargados_ruta") or []
    route_map: dict[int, dict] = {}
    for item in route_inputs:
        route_id = int(item["ruta_id"])
        if route_id in route_map:
            raise HTTPException(422, f"La ruta {route_id} tiene decisiones de encargado duplicadas")
        if route_id not in enabled_routes:
            raise HTTPException(422, f"La ruta {route_id} no permite asignar encargado")
        requires = bool(item.get("requiere_encargado"))
        manager_id = item.get("agente_id")
        if requires and not manager_id:
            raise HTTPException(422, f"Debe seleccionar el encargado de la ruta {enabled_routes[route_id]}")
        if not requires and manager_id:
            raise HTTPException(422, f"La ruta {enabled_routes[route_id]} no puede conservar un encargado cuando la opcion esta desactivada")
        route_map[route_id] = item

    missing = [name for route_id, name in enabled_routes.items() if route_id not in route_map]
    if missing:
        raise HTTPException(422, "Debe definir si las rutas requieren encargado: " + ", ".join(missing))
    if any(not bool(item.get("requiere_encargado")) for item in route_map.values()) and not district_manager_id:
        raise HTTPException(422, "Una ruta solo puede quedar sin encargado cuando existe un encargado de distrito responsable")
    for route_id, item in route_map.items():
        agent_ids = []
        if item.get("agente_id"):
            agent_ids.append(int(item["agente_id"]))
        if item.get("agente_2_id"):
            agent_ids.append(int(item["agente_2_id"]))
        if not agent_ids:
            agent_ids.append(None)
        for idx, agente_id in enumerate(agent_ids):
            responsibilities.append({
                "tipo_responsabilidad": "ENCARGADO_RUTA", "ruta_id": route_id, "circuito_id": None,
                "requiere_encargado": bool(item.get("requiere_encargado")),
                "agente_id": agente_id,
                "conductor_id": None, "auxiliar_1_id": None, "auxiliar_2_id": None, "movil_id": None,
                "usar_encargado_distrito": False,
                "tipo_asignacion": str(item.get("tipo_asignacion") or "MANUAL").upper(),
            })

    for item in responsibilities:
        if item["tipo_responsabilidad"] != "ENCARGADO_RUTA" or not item.get("agente_id"):
            continue
        person_id = int(item["agente_id"])
        if person_id in used_people:
            raise HTTPException(409, f"El agente {person_id} ya tiene otra responsabilidad en la distribucion")
        used_people.add(person_id)
    for item in responsibilities:
        person_id = item.get("agente_id")
        if not person_id:
            continue
        responsibility = item["tipo_responsabilidad"]
        allowed = ({"INSPECTOR", "SUBINSPECTOR"} if responsibility in {"ENCARGADO_DISTRITO", "ENCARGADO_CIRCUITO"}
                   else {"AGENTE 2", "AGENTE 3", "AGENTE 4"} if responsibility == "ENCARGADO_RUTA" else None)
        if not allowed:
            continue
        cursor.execute("""
            SELECT UPPER(REPLACE(ISNULL(g.nombre,''),'-',''))
            FROM dbo.personal p LEFT JOIN dbo.grados g ON g.id=p.grado_id WHERE p.id=?
        """, int(person_id))
        row = cursor.fetchone()
        if not row or str(row[0]) not in allowed:
            label = "distrito o circuito" if responsibility in {"ENCARGADO_DISTRITO", "ENCARGADO_CIRCUITO"} else "ruta"
            raise HTTPException(422, f"El grado del encargado de {label} no cumple la regla operativa")
    support_ids = sorted({int(person_id) for item in responsibilities for person_id in
                          (item.get("conductor_id"), item.get("auxiliar_1_id"), item.get("auxiliar_2_id")) if person_id})
    if support_ids:
        placeholders = ",".join("?" * len(support_ids))
        cursor.execute(f"""
            SELECT p.id,UPPER(ISNULL(g.nombre,''))
            FROM dbo.personal p LEFT JOIN dbo.grados g ON g.id=p.grado_id
            WHERE p.id IN ({placeholders})
        """, *support_ids)
        grades = {int(row[0]):str(row[1]) for row in cursor.fetchall()}
        if any(grades.get(person_id) not in {"AGENTE 1","AGENTE 2","AGENTE 3","AGENTE 4"} for person_id in support_ids):
            raise HTTPException(422, "Conductores y auxiliares deben tener grado Agente 1, 2, 3 o 4")
    manager_ids = sorted(used_people)
    return responsibilities, manager_ids


def _insert_responsibilities(cursor, distribution_id: int, district_id: int, responsibilities: list[dict], user_id: int) -> None:
    for item in responsibilities:
        cursor.execute("""
            INSERT INTO dbo.distribucion_encargados
                (distribucion_id,distrito_id,ruta_id,circuito_id,tipo_responsabilidad,requiere_encargado,
                 agente_id,conductor_id,auxiliar_1_id,auxiliar_2_id,movil_id,usar_encargado_distrito,
                 tipo_asignacion,estado,creado_por,fecha_creacion)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,SYSDATETIME())
        """, distribution_id, district_id, item["ruta_id"], item["circuito_id"], item["tipo_responsabilidad"],
             1 if item["requiere_encargado"] else 0, item["agente_id"],item["conductor_id"],item["auxiliar_1_id"],
             item["auxiliar_2_id"],item["movil_id"],1 if item["usar_encargado_distrito"] else 0,item["tipo_asignacion"],
              "ASIGNADO" if item["agente_id"] else "NO_REQUERIDO", user_id)


def _validate_eas_agent(cursor, agent_id: int, distribution_date: date, shift_id: int, shift_name: str,
                        distribution_id: int | None = None) -> None:
    cursor.execute("""
        SELECT UPPER(ISNULL(g.nombre,''))
        FROM dbo.personal p WITH (UPDLOCK,HOLDLOCK)
        LEFT JOIN dbo.catalogo_detalles ep ON ep.id=p.estado_personal_id
        LEFT JOIN dbo.grados g ON g.id=p.grado_id
        INNER JOIN dbo.roles r ON r.id=p.rol_id AND r.activo=1
        WHERE p.id=? AND p.activo=1 AND UPPER(ISNULL(ep.nombre,''))='ACTIVO'
          AND UPPER(ISNULL(r.codigo,'')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')
    """, agent_id)
    row = cursor.fetchone()
    if not row or str(row[0]) not in {"AGENTE 1", "AGENTE 2", "AGENTE 3"}:
        raise HTTPException(422, f"El agente {agent_id} no esta habilitado para una asignacion EAS")
    checks = [
        ("SELECT TOP 1 id FROM dbo.asignaciones_ruta WITH (UPDLOCK,HOLDLOCK) WHERE agente_id=? AND fecha_asignacion=? AND turno=? AND estado IN ('PENDIENTE','ACTIVA') AND deleted_at IS NULL", (agent_id, distribution_date, shift_name)),
        ("SELECT TOP 1 id FROM dbo.asignaciones_punto WITH (UPDLOCK,HOLDLOCK) WHERE personal_id=? AND turno_id=? AND activo=1 AND estado IN ('ACTIVA','PENDIENTE') AND fecha_inicio<=? AND (fecha_fin IS NULL OR fecha_fin>=?)", (agent_id, shift_id, distribution_date, distribution_date)),
        ("SELECT TOP 1 de.id FROM dbo.distribucion_encargados de WITH (UPDLOCK,HOLDLOCK) INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id WHERE (de.agente_id=? OR de.conductor_id=? OR de.auxiliar_1_id=? OR de.auxiliar_2_id=?) AND dp.fecha_distribucion=? AND dp.turno_id=? AND de.deleted_at IS NULL AND dp.deleted_at IS NULL" + (" AND de.distribucion_id<>?" if distribution_id else ""), (agent_id, agent_id, agent_id, agent_id, distribution_date, shift_id, *([distribution_id] if distribution_id else []))),
        ("SELECT TOP 1 ed.id FROM dbo.distribucion_eas_detalle ed WITH (UPDLOCK,HOLDLOCK) INNER JOIN dbo.distribuciones_personal dp ON dp.id=ed.distribucion_id WHERE ed.agente_id=? AND ed.deleted_at IS NULL AND dp.deleted_at IS NULL AND dp.fecha_distribucion=? AND dp.turno_id=?" + (" AND ed.distribucion_id<>?" if distribution_id else ""), (agent_id, distribution_date, shift_id, *([distribution_id] if distribution_id else []))),
    ]
    for sql, params in checks:
        cursor.execute(sql, *params)
        if cursor.fetchone():
            raise HTTPException(409, f"El agente {agent_id} ya tiene una asignacion en la misma fecha y turno")


def _save_eas_distribution(cursor, data: dict, user_id: int, ip: str | None, distribution_id: int | None = None) -> dict:
    district_id, shift_id = int(data["distrito_id"]), int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    if data.get("asignaciones") or data.get("encargados_circuito") or data.get("encargados_ruta") or data.get("encargado_distrito_id"):
        raise HTTPException(422, "El distrito EAS solo admite asignaciones EAS")
    cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
    cursor.execute("SELECT id,nombre FROM dbo.turnos WITH (UPDLOCK,HOLDLOCK) WHERE id=? AND activo=1", shift_id)
    shift = _row(cursor)
    if not shift:
        raise HTTPException(422, "El turno seleccionado no es valido")
    slots = _eas_slots(cursor, district_id, shift_id)
    if not slots:
        raise HTTPException(422, "No existen EAS, circuitos y rutas activos para el distrito y turno seleccionados")
    slot_map = {(int(s["eas_id"]), int(s["ruta_id"]), int(s["configuracion_id"]) if s["configuracion_id"] is not None else None): s for s in slots}
    provided: dict[tuple[int, int, int | None, str], dict] = {}
    for item in data.get("asignaciones_eas") or []:
        key = (int(item["eas_id"]), int(item["ruta_id"]), int(item["configuracion_id"]) if item.get("configuracion_id") else None)
        role = str(item["rol"]).upper()
        if key not in slot_map:
            raise HTTPException(422, "La configuracion EAS no pertenece al distrito, circuito, ruta o turno seleccionado")
        full_key = (*key, role)
        if full_key in provided:
            raise HTTPException(409, "Existe una asignacion EAS duplicada para la misma configuracion y rol")
        provided[full_key] = item
    people = [int(item["agente_id"]) for item in provided.values() if item.get("agente_id")]
    if len(people) != len(set(people)):
        raise HTTPException(409, "Un agente no puede repetirse entre roles EAS")
    is_update = distribution_id is not None
    if distribution_id is None:
        cursor.execute("""SELECT TOP 1 id FROM dbo.distribuciones_personal WITH (UPDLOCK,HOLDLOCK)
                          WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=? AND deleted_at IS NULL""",
                       district_id, shift_id, distribution_date)
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe una distribucion guardada para ese distrito, turno y fecha")
    else:
        cursor.execute("SELECT id FROM dbo.distribuciones_personal WITH (UPDLOCK,HOLDLOCK) WHERE id=? AND deleted_at IS NULL", distribution_id)
        if not cursor.fetchone():
            raise HTTPException(404, "La distribucion no existe")
        cursor.execute("""SELECT TOP 1 id FROM dbo.distribuciones_personal WITH (UPDLOCK,HOLDLOCK)
                          WHERE distrito_id=? AND turno_id=? AND fecha_distribucion=? AND id<>? AND deleted_at IS NULL""",
                       district_id, shift_id, distribution_date, distribution_id)
        if cursor.fetchone():
            raise HTTPException(409, "Ya existe otra distribucion para ese distrito, turno y fecha")
        cursor.execute("UPDATE dbo.distribucion_eas_detalle SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME() WHERE distribucion_id=? AND deleted_at IS NULL", distribution_id)
    for agent_id in people:
        _validate_eas_agent(cursor, agent_id, distribution_date, shift_id, shift["nombre"], distribution_id)
    required = len(slot_map) * 2
    assigned = sum(1 for key, item in provided.items() if key[3] in {"CP", "JP"} and item.get("agente_id"))
    pending = required - assigned
    coverage = round(assigned / required * 100, 2) if required else 0
    status = "COMPLETA" if pending == 0 else "PARCIAL"
    name = f"DISTRIBUCIÓN EAS FECHA {distribution_date.strftime('%d/%m/%Y')}"
    if distribution_id is None:
        cursor.execute("""INSERT INTO dbo.distribuciones_personal(nombre,fecha_distribucion,creado_por,distrito_id,turno_id,estado,porcentaje_cobertura,total_requerido,total_asignado,fecha_creacion)
                          OUTPUT INSERTED.id VALUES(?,?,?,?,?,?,?,?,?,SYSDATETIME())""",
                       name, distribution_date, user_id, district_id, shift_id, status, coverage, required, assigned)
        distribution_id = int(cursor.fetchone()[0])
    else:
        cursor.execute("""UPDATE dbo.distribuciones_personal SET nombre=?,fecha_distribucion=?,distrito_id=?,turno_id=?,estado=?,porcentaje_cobertura=?,total_requerido=?,total_asignado=?,fecha_actualizacion=SYSDATETIME() WHERE id=?""",
                       name, distribution_date, district_id, shift_id, status, coverage, required, assigned, distribution_id)
    for key in slot_map:
        for role in ("CP", "JP", "AUX"):
            item = provided.get((*key, role))
            agent_id = int(item["agente_id"]) if item and item.get("agente_id") else None
            cursor.execute("""INSERT INTO dbo.distribucion_eas_detalle(distribucion_id,eas_id,ruta_id,configuracion_id,rol,agente_id,tipo_asignacion,estado,fecha_creacion)
                              VALUES(?,?,?,?,?,?,?,?,SYSDATETIME())""",
                           distribution_id, key[0], key[1], key[2], role, agent_id,
                           str(item.get("tipo_asignacion") or "MANUAL").upper() if item else None,
                           "ASIGNADO" if agent_id else "PENDIENTE")
    _audit(cursor, user_id, "EDITAR_DISTRIBUCION_EAS" if is_update else "GUARDAR_DISTRIBUCION_EAS", str(distribution_id), {"fecha": str(distribution_date), "ip": ip})
    return {"id": distribution_id, "nombre": name, "fecha_distribucion": distribution_date, "estado": status,
            "porcentaje_cobertura": coverage, "total_requerido": required, "total_asignado": assigned, "pendientes": pending}


def generate_eas_draft_assignments(data: dict) -> list[dict]:
    district_id, shift_id = int(data["distrito_id"]), int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    with get_connection() as connection:
        cursor = connection.cursor()
        if not _is_eas_district(cursor, district_id):
            raise HTTPException(422, "La asignacion aleatoria EAS solo esta disponible para el distrito EAS")
        cursor.execute("SELECT nombre FROM dbo.turnos WHERE id=? AND activo=1", shift_id)
        shift = cursor.fetchone()
        if not shift:
            raise HTTPException(422, "El turno seleccionado no es valido")
        slots = _eas_slots(cursor, district_id, shift_id)
        existing = data.get("asignaciones_eas") or []
        occupied_roles = {(int(x["eas_id"]), int(x["ruta_id"]), int(x["configuracion_id"]) if x.get("configuracion_id") else None, str(x["rol"]).upper())
                          for x in existing if x.get("agente_id")}
        used = {int(x["agente_id"]) for x in existing if x.get("agente_id")}
        used.update(int(x) for x in data.get("excluidos", []) if x)
        candidates = [a for a in _active_agents(cursor, used) if str(a.get("grado") or "").upper() in {"AGENTE 1", "AGENTE 2", "AGENTE 3"}]
        available: list[dict] = []
        for candidate in candidates:
            agent_id = int(candidate["id"])
            cursor.execute("""
                SELECT TOP 1 1 FROM (
                    SELECT ar.agente_id AS agente FROM dbo.asignaciones_ruta ar WHERE ar.agente_id=? AND ar.fecha_asignacion=? AND ar.turno=? AND ar.estado IN ('PENDIENTE','ACTIVA') AND ar.deleted_at IS NULL
                    UNION ALL SELECT ap.personal_id FROM dbo.asignaciones_punto ap WHERE ap.personal_id=? AND ap.turno_id=? AND ap.fecha_inicio<=? AND (ap.fecha_fin IS NULL OR ap.fecha_fin>=?) AND ap.activo=1 AND ap.estado IN ('ACTIVA','PENDIENTE')
                    UNION ALL SELECT de.agente_id FROM dbo.distribucion_encargados de INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id WHERE (de.agente_id=? OR de.conductor_id=? OR de.auxiliar_1_id=? OR de.auxiliar_2_id=?) AND dp.fecha_distribucion=? AND dp.turno_id=? AND de.deleted_at IS NULL AND dp.deleted_at IS NULL
                    UNION ALL SELECT ed.agente_id FROM dbo.distribucion_eas_detalle ed INNER JOIN dbo.distribuciones_personal dp ON dp.id=ed.distribucion_id WHERE ed.agente_id=? AND dp.fecha_distribucion=? AND dp.turno_id=? AND ed.deleted_at IS NULL AND dp.deleted_at IS NULL
                ) x
            """, agent_id, distribution_date, shift[0], agent_id, shift_id, distribution_date, distribution_date,
                 agent_id, agent_id, agent_id, agent_id, distribution_date, shift_id, agent_id, distribution_date, shift_id)
            if not cursor.fetchone():
                available.append(candidate)
        random.SystemRandom().shuffle(available)
        generated: list[dict] = []
        position = 0
        roles = ("CP", "JP", "AUX") if data.get("include_aux") else ("CP", "JP")
        for role in roles:
            for slot in slots:
                key = (int(slot["eas_id"]), int(slot["ruta_id"]), int(slot["configuracion_id"]) if slot["configuracion_id"] is not None else None, role)
                if key in occupied_roles or position >= len(available):
                    continue
                agent = available[position]
                position += 1
                generated.append({"eas_id": key[0], "ruta_id": key[1], "configuracion_id": key[2], "rol": role,
                                  "agente_id": int(agent["id"]), "tipo_asignacion": "ALEATORIA", "agente": agent})
        return generated


def save_distribution(data: dict, user_id: int, ip: str | None = None) -> dict:
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    assignments = data.get("asignaciones") or []
    with get_connection() as connection:
        cursor = connection.cursor()
        if _is_eas_district(cursor, district_id):
            return _save_eas_distribution(cursor, data, user_id, ip)
    place_agent_ids = [int(item["agente_id"]) for item in assignments]
    if len(place_agent_ids) != len(set(place_agent_ids)):
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

        responsibilities, manager_ids = _prepare_responsibilities(cursor, district_id, shift_id, data)
        agent_ids = place_agent_ids + manager_ids
        if len(agent_ids) != len(set(agent_ids)):
            raise HTTPException(409, "Un agente no puede repetirse entre encargados y lugares de servicio")

        places, place_map = _validate_distribution_relations(cursor, district_id, shift_id, assignments)
        _validate_place_agent_grades(cursor, assignments)
        required = sum(int(place["cantidad_requerida"] or 0) for place in places)
        assigned = len(assignments)
        pending = max(0, required - assigned)
        # Una distribución parcial es un registro válido: los cupos no cubiertos
        # se persisten como detalles PENDIENTE y se informan en el dashboard.

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
            cursor.execute("""
                SELECT TOP 1 de.id
                FROM dbo.distribucion_encargados de WITH (UPDLOCK, HOLDLOCK)
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id
                WHERE (de.agente_id=? OR de.conductor_id=? OR de.auxiliar_1_id=? OR de.auxiliar_2_id=?) AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND de.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id,agent_id,agent_id,agent_id, distribution_date, shift_id)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya es encargado en la misma fecha y turno")
            cursor.execute("""
                SELECT TOP 1 ed.id FROM dbo.distribucion_eas_detalle ed WITH (UPDLOCK,HOLDLOCK)
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=ed.distribucion_id
                WHERE ed.agente_id=? AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND ed.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id, distribution_date, shift_id)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya tiene una asignacion EAS en la misma fecha y turno")

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
        _insert_responsibilities(cursor, distribution_id, district_id, responsibilities, user_id)

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
                    dp.distrito_id, dp.turno_id, d.nombre AS distrito, t.nombre AS turno,
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
        cursor.execute("""
            SELECT de.id,de.tipo_responsabilidad,de.ruta_id,de.circuito_id,de.requiere_encargado,
                   de.usar_encargado_distrito,de.agente_id,de.conductor_id,de.auxiliar_1_id,de.auxiliar_2_id,de.movil_id,
                   de.tipo_asignacion,vp.nombre_completo AS agente,vp.cedula,
                   cd.nombre_completo AS conductor,gd.nombre AS conductor_grado,
                   a1.nombre_completo AS auxiliar_1,g1.nombre AS auxiliar_1_grado,
                   a2.nombre_completo AS auxiliar_2,g2.nombre AS auxiliar_2_grado,
                   m.numero_movil,m.placa,c.nombre AS circuito
            FROM dbo.distribucion_encargados de
            LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=de.agente_id
            LEFT JOIN dbo.vw_personal_detalle cd ON cd.id=de.conductor_id
            LEFT JOIN dbo.personal pcd ON pcd.id=de.conductor_id LEFT JOIN dbo.grados gd ON gd.id=pcd.grado_id
            LEFT JOIN dbo.vw_personal_detalle a1 ON a1.id=de.auxiliar_1_id
            LEFT JOIN dbo.personal pa1 ON pa1.id=de.auxiliar_1_id LEFT JOIN dbo.grados g1 ON g1.id=pa1.grado_id
            LEFT JOIN dbo.vw_personal_detalle a2 ON a2.id=de.auxiliar_2_id
            LEFT JOIN dbo.personal pa2 ON pa2.id=de.auxiliar_2_id LEFT JOIN dbo.grados g2 ON g2.id=pa2.grado_id
            LEFT JOIN dbo.moviles m ON m.id=de.movil_id
            LEFT JOIN dbo.circuitos c ON c.id=de.circuito_id
            WHERE de.distribucion_id=? AND de.deleted_at IS NULL
            ORDER BY CASE de.tipo_responsabilidad WHEN 'ENCARGADO_DISTRITO' THEN 0 WHEN 'ENCARGADO_CIRCUITO' THEN 1 ELSE 2 END,
                     de.circuito_id,de.ruta_id
        """, distribution_id)
        header["encargados"] = _rows(cursor)
        cursor.execute("""
            SELECT ed.id,ed.eas_id,e.nombre AS eas_nombre,ed.ruta_id,r.nombre AS ruta,
                   ed.configuracion_id,ec.orden,ec.movil_id,
                   CASE WHEN ec.id IS NULL THEN fm.numero_movil ELSE m.numero_movil END AS numero_movil,
                   CASE WHEN ec.id IS NULL THEN fm.placa ELSE m.placa END AS placa,
                   CASE WHEN ec.id IS NULL THEN mea.movil_id END AS movil_informativo_id,
                   ed.rol,ed.agente_id,vp.nombre_completo AS agente,vp.cedula,
                   ed.tipo_asignacion,ed.estado
            FROM dbo.distribucion_eas_detalle ed
            INNER JOIN dbo.eas_estaciones e ON e.id=ed.eas_id
            INNER JOIN dbo.rutas r ON r.id=ed.ruta_id
            LEFT JOIN dbo.eas_ruta_configuraciones ec ON ec.id=ed.configuracion_id
            LEFT JOIN dbo.moviles m ON m.id=ec.movil_id
            OUTER APPLY (SELECT TOP 1 a.movil_id FROM dbo.movil_eas_asignaciones a
                         WHERE a.eas_id=ed.eas_id AND a.activo=1 ORDER BY a.fecha_asignacion DESC,a.id DESC) mea
            LEFT JOIN dbo.moviles fm ON fm.id=mea.movil_id AND fm.activo=1
            LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=ed.agente_id
            WHERE ed.distribucion_id=? AND ed.deleted_at IS NULL
            ORDER BY e.nombre,r.nombre,ISNULL(ec.orden,0),ed.rol
        """, distribution_id)
        header["eas_detalles"] = _rows(cursor)
        return header


def update_distribution(distribution_id: int, data: dict, user_id: int, ip: str | None = None) -> dict:
    district_id = int(data["distrito_id"])
    shift_id = int(data["turno_id"])
    distribution_date: date = data["fecha_distribucion"]
    assignments = data.get("asignaciones") or []
    with get_connection() as connection:
        cursor = connection.cursor()
        if _is_eas_district(cursor, district_id):
            return _save_eas_distribution(cursor, data, user_id, ip, distribution_id)
    place_agent_ids = [int(item["agente_id"]) for item in assignments]
    if len(place_agent_ids) != len(set(place_agent_ids)):
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
            UPDATE dbo.distribucion_encargados SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME()
            WHERE distribucion_id=? AND deleted_at IS NULL
        """, distribution_id)
        cursor.execute("""
            UPDATE dbo.distribucion_eas_detalle SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME()
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
        responsibilities, manager_ids = _prepare_responsibilities(cursor, district_id, shift_id, data)
        agent_ids = place_agent_ids + manager_ids
        if len(agent_ids) != len(set(agent_ids)):
            raise HTTPException(409, "Un agente no puede repetirse entre encargados y lugares de servicio")
        places, place_map = _validate_distribution_relations(cursor, district_id, shift_id, assignments)
        _validate_place_agent_grades(cursor, assignments)
        required = sum(int(place["cantidad_requerida"] or 0) for place in places)
        assigned = len(assignments)
        pending = max(0, required - assigned)
        # Al editar también se conserva la distribución aunque queden pendientes.

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
            cursor.execute("""
                SELECT TOP 1 de.id
                FROM dbo.distribucion_encargados de WITH (UPDLOCK, HOLDLOCK)
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id
                WHERE (de.agente_id=? OR de.conductor_id=? OR de.auxiliar_1_id=? OR de.auxiliar_2_id=?) AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND de.distribucion_id<>? AND de.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id,agent_id,agent_id,agent_id, distribution_date, shift_id, distribution_id)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya es encargado en la misma fecha y turno")
            cursor.execute("""
                SELECT TOP 1 ed.id FROM dbo.distribucion_eas_detalle ed WITH (UPDLOCK,HOLDLOCK)
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=ed.distribucion_id
                WHERE ed.agente_id=? AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND ed.distribucion_id<>? AND ed.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id, distribution_date, shift_id, distribution_id)
            if cursor.fetchone():
                raise HTTPException(409, f"El agente {agent_id} ya tiene una asignacion EAS en la misma fecha y turno")

        name = f"DISTRIBUCIÓN DE PERSONAL FECHA {distribution_date.strftime('%d/%m/%Y')}"
        coverage = round((assigned / required * 100), 2) if required else 0
        status = "COMPLETA" if pending == 0 else "PARCIAL"
        cursor.execute("""
            UPDATE dbo.distribuciones_personal
            SET nombre=?, fecha_distribucion=?, distrito_id=?, turno_id=?, estado=?,
                porcentaje_cobertura=?, total_requerido=?, total_asignado=?, fecha_actualizacion=SYSDATETIME()
            WHERE id=?
        """, name, distribution_date, district_id, shift_id, status, coverage, required, assigned, distribution_id)
        _insert_responsibilities(cursor, distribution_id, district_id, responsibilities, user_id)

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
        ruta_id = int(data["ruta_id"]) if data.get("ruta_id") else None
        lugar_id = int(data["lugar_id"]) if data.get("lugar_id") else None
        excluded_ids = [int(x) for x in data.get("excluidos", []) if x]
        page = int(data.get("page", 1))
        limit = int(data.get("limit", 20))
        offset = (page - 1) * limit

        cursor.execute("SELECT nombre FROM dbo.turnos WHERE id = ? AND activo = 1", turno_id)
        turno_row = cursor.fetchone()
        turno_nombre = turno_row[0] if turno_row else ""

        lugar_nombre = ""
        ruta_nombre = ""
        if lugar_id and ruta_id:
            cursor.execute("""
                SELECT ls.nombre AS lugar_nombre, r.nombre AS ruta_nombre
                FROM dbo.lugares_servicio ls
                INNER JOIN dbo.rutas r ON r.id = ls.ruta_id
                WHERE ls.id = ? AND ls.ruta_id = ?
            """, lugar_id, ruta_id)
            place_row = cursor.fetchone()
            lugar_nombre = place_row[0] if place_row else ""
            ruta_nombre = place_row[1] if place_row else ""
        elif ruta_id:
            cursor.execute("SELECT nombre FROM dbo.rutas WHERE id=? AND distrito_id=?", ruta_id, distrito_id)
            route_row = cursor.fetchone()
            ruta_nombre = route_row[0] if route_row else ""

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

        responsibility = str(data.get("tipo_responsabilidad") or "AGENTE_LUGAR").upper()
        where = ["p.activo = 1", "UPPER(ISNULL(r.codigo, '')) IN ('AGENTE','ENCARGADO','INSPECTOR','OPERACIONES','SUPERVISOR')"]
        params: list = []
        if responsibility in {"ENCARGADO_DISTRITO", "ENCARGADO_CIRCUITO"}:
            where.append("UPPER(REPLACE(ISNULL(g.nombre,''),'-','')) IN ('INSPECTOR','SUBINSPECTOR')")
        elif responsibility == "ENCARGADO_RUTA":
            where.append("UPPER(ISNULL(g.nombre,'')) IN ('AGENTE 2','AGENTE 3','AGENTE 4')")
        elif responsibility in {"CONDUCTOR", "AUXILIAR"}:
            where.append("UPPER(ISNULL(g.nombre,'')) IN ('AGENTE 1','AGENTE 2','AGENTE 3','AGENTE 4')")
        elif responsibility in {"AGENTE_LUGAR", "EAS_CP", "EAS_JP", "EAS_AUX"}:
            where.append("UPPER(ISNULL(g.nombre,'')) IN ('AGENTE 1','AGENTE 2','AGENTE 3')")

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
            where.append("(p.nombres LIKE ? ESCAPE '\\' OR p.apellidos LIKE ? ESCAPE '\\' OR p.cedula LIKE ? ESCAPE '\\')")
            search = f"%{escape_like(data['search'])}%"
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

        today = data.get("fecha_distribucion") or datetime.now().date()
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
                  AND ar.fecha_asignacion=? AND ar.turno=?
            """, agent_id, today, turno_name)
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

            cursor.execute("""
                SELECT TOP 1 de.tipo_responsabilidad
                FROM dbo.distribucion_encargados de
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=de.distribucion_id
                WHERE (de.agente_id=? OR de.conductor_id=? OR de.auxiliar_1_id=? OR de.auxiliar_2_id=?)
                  AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND de.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id,agent_id,agent_id,agent_id,today,turno_id)
            manager = cursor.fetchone()
            if manager:
                disponible = False
                motivo_no_disponible = "Ya tiene una responsabilidad para esta fecha y turno"

            cursor.execute("""
                SELECT TOP 1 ed.id FROM dbo.distribucion_eas_detalle ed
                INNER JOIN dbo.distribuciones_personal dp ON dp.id=ed.distribucion_id
                WHERE ed.agente_id=? AND dp.fecha_distribucion=? AND dp.turno_id=?
                  AND ed.deleted_at IS NULL AND dp.deleted_at IS NULL
            """, agent_id, today, turno_id)
            if cursor.fetchone():
                disponible = False
                motivo_no_disponible = "Ya tiene una asignacion EAS para esta fecha y turno"

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
        anterior_id = int(data["agente_anterior_id"]) if data.get("agente_anterior_id") else None
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
              AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre, '')))) <> N'ENCARGADO DE RUTA'
        """, lugar_id, ruta_id)
        lugar = _row(cursor)
        if not lugar:
            raise HTTPException(422, "El lugar de servicio no es valido")

        cursor.execute("""
            SELECT p.id, LTRIM(RTRIM(ISNULL(g.nombre + ' ', '') + ISNULL(p.nombres, '') + ' ' + ISNULL(p.apellidos, ''))) AS nombre_completo,
                   p.cedula, ISNULL(ep.nombre, 'SIN ESTADO') AS estado_laboral,
                   UPPER(ISNULL(g.nombre,'')) AS grado
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
        if str(nuevo["grado"]) not in {"AGENTE 1", "AGENTE 2", "AGENTE 3"}:
            raise HTTPException(422, "Los lugares de servicio solo permiten personal con grado Agente 1, Agente 2 o Agente 3")

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
        cursor.execute("UPDATE dbo.distribucion_encargados SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME() WHERE distribucion_id=? AND deleted_at IS NULL", distribution_id)
        cursor.execute("UPDATE dbo.distribucion_eas_detalle SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME() WHERE distribucion_id=? AND deleted_at IS NULL", distribution_id)
        cursor.execute("""
            UPDATE dbo.distribuciones_personal
            SET estado='ELIMINADA', eliminado_por=?, deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            WHERE id=?
        """, user_id, distribution_id)
        _audit(cursor, user_id, "ELIMINAR_DISTRIBUCION", str(distribution_id), {"ip": ip})


def delete_distribution_group(turno_id: int, distribution_date: date, user_id: int, ip: str | None = None) -> int:
    """Soft-delete every district record that belongs to one dashboard distribution."""
    with get_connection() as connection:
        cursor = connection.cursor()
        cursor.execute("SET TRANSACTION ISOLATION LEVEL SERIALIZABLE")
        cursor.execute("""
            SELECT id FROM dbo.distribuciones_personal WITH (UPDLOCK, HOLDLOCK)
            WHERE turno_id=? AND fecha_distribucion=? AND deleted_at IS NULL
        """, turno_id, distribution_date)
        distribution_ids = [int(row[0]) for row in cursor.fetchall()]
        if not distribution_ids:
            raise HTTPException(404, "No se encontro la distribucion para ese turno y fecha")
        placeholders = ",".join("?" for _ in distribution_ids)
        cursor.execute(f"""
            UPDATE ar SET estado='CANCELADA', deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
            FROM dbo.asignaciones_ruta ar
            INNER JOIN dbo.distribucion_personal_detalle dd ON dd.asignacion_ruta_id=ar.id
            WHERE dd.distribucion_id IN ({placeholders}) AND ar.deleted_at IS NULL
        """, *distribution_ids)
        cursor.execute(f"""UPDATE dbo.distribucion_personal_detalle
                            SET deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
                            WHERE distribucion_id IN ({placeholders}) AND deleted_at IS NULL""", *distribution_ids)
        cursor.execute(f"""UPDATE dbo.distribucion_encargados
                            SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME()
                            WHERE distribucion_id IN ({placeholders}) AND deleted_at IS NULL""", *distribution_ids)
        cursor.execute(f"""UPDATE dbo.distribucion_eas_detalle
                            SET deleted_at=SYSDATETIME(),fecha_actualizacion=SYSDATETIME()
                            WHERE distribucion_id IN ({placeholders}) AND deleted_at IS NULL""", *distribution_ids)
        cursor.execute(f"""UPDATE dbo.distribuciones_personal
                            SET estado='ELIMINADA', eliminado_por=?, deleted_at=SYSDATETIME(), fecha_actualizacion=SYSDATETIME()
                            WHERE id IN ({placeholders}) AND deleted_at IS NULL""", user_id, *distribution_ids)
        for distribution_id in distribution_ids:
            _audit(cursor, user_id, "ELIMINAR_DISTRIBUCION", str(distribution_id), {
                "ip": ip, "fecha_distribucion": str(distribution_date), "turno_id": turno_id,
                "eliminacion_desde": "dashboard",
            })
        return len(distribution_ids)


def get_distributions_dashboard() -> dict:
    """Group distributions by date/shift and include every operational district for that shift."""
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
            ORDER BY dp.fecha_distribucion DESC, t.nombre, d.nombre
        """)
        distributions = _rows(cursor)

        groups: dict[str, dict] = {}
        for dist in distributions:
            fecha = str(dist["fecha_distribucion"]) if dist["fecha_distribucion"] else ""
            turno_id = int(dist["turno_id"])
            group_key = f"{fecha}:{turno_id}"

            if group_key not in groups:
                groups[group_key] = {
                    "fecha_distribucion": fecha,
                    "turno_id": turno_id,
                    "turno": dist["turno"],
                    "creado_por": dist["creado_por"],
                    "fecha_creacion": str(dist["fecha_creacion"]) if dist["fecha_creacion"] else None,
                    "distritos": [],
                    "total_requerido": 0,
                    "total_asignado": 0,
                }

            groups[group_key].setdefault("registros", {})[int(dist["distrito_id"])] = int(dist["id"])

        result = []
        for key, group in groups.items():
            cursor.execute("""
                SELECT d.id AS distrito_id, d.nombre AS distrito, dp.id AS distribucion_id,
                       r.id AS ruta_id, r.nombre AS ruta, ls.id AS lugar_id, ls.nombre AS lugar,
                       ls.cantidad_requerida, dd.id AS detalle_id, dd.agente_id,
                       vp.nombre_completo AS agente,
                       COALESCE(ar.hora_inicio, t.hora_inicio, r.hora_inicio, ls.hora_inicio) AS hora_ingreso,
                       COALESCE(ar.hora_fin, t.hora_fin, r.hora_fin, ls.hora_fin) AS hora_salida,
                       ls.consignas, COALESCE(ar.observacion, ls.observacion) AS observaciones
                FROM dbo.catalogo_detalles d
                INNER JOIN dbo.catalogos c ON c.id=d.catalogo_id AND c.codigo='DISTRITOS' AND c.estado=1
                LEFT JOIN dbo.rutas r ON r.distrito_id=d.id AND r.activo=1 AND r.turno_id=?
                LEFT JOIN dbo.lugares_servicio ls ON ls.ruta_id=r.id AND ls.activo=1
                    AND UPPER(LTRIM(RTRIM(ISNULL(ls.nombre, '')))) <> N'ENCARGADO DE RUTA'
                LEFT JOIN dbo.distribuciones_personal dp ON dp.distrito_id=d.id AND dp.turno_id=?
                    AND dp.fecha_distribucion=? AND dp.deleted_at IS NULL
                LEFT JOIN dbo.distribucion_personal_detalle dd ON dd.distribucion_id=dp.id
                    AND dd.ruta_id=r.id AND dd.lugar_id=ls.id AND dd.deleted_at IS NULL
                LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=dd.agente_id
                LEFT JOIN dbo.asignaciones_ruta ar ON ar.id=dd.asignacion_ruta_id AND ar.deleted_at IS NULL
                LEFT JOIN dbo.turnos t ON t.id=?
                WHERE d.estado=1 AND dp.id IS NOT NULL
                ORDER BY d.nombre, r.nombre, ls.nombre, dd.id
            """, group["turno_id"], group["turno_id"], group["fecha_distribucion"], group["turno_id"])
            rows = _rows(cursor)
            by_district: dict[int, dict] = {}
            place_requirements: dict[int, dict[int, int]] = {}
            route_lookup: dict[int, dict[int, dict]] = {}
            for row in rows:
                district_id = int(row["distrito_id"])
                if district_id not in by_district:
                    by_district[district_id] = {
                        "id": int(row["distribucion_id"]) if row["distribucion_id"] is not None else None,
                        "distrito_id": district_id, "distrito": row["distrito"], "total_asignado": 0,
                        "rutas": [], "faltantes_detalle": [],
                    }
                    place_requirements[district_id] = {}
                    route_lookup[district_id] = {}
                district = by_district[district_id]
                if row["lugar_id"] is None:
                    continue
                place_id = int(row["lugar_id"])
                place_requirements[district_id][place_id] = max(1, int(row["cantidad_requerida"] or 1))
                if row["agente_id"] is not None:
                    district["total_asignado"] += 1
                else:
                    district["faltantes_detalle"].append({
                        "ruta": row["ruta"], "lugar": row["lugar"],
                    })
                route_id = int(row["ruta_id"])
                if route_id not in route_lookup[district_id]:
                    route = {"id": route_id, "ruta": row["ruta"], "filas": []}
                    route_lookup[district_id][route_id] = route
                    district["rutas"].append(route)
                route_lookup[district_id][route_id]["filas"].append({
                    "lugar": row["lugar"], "agente": row["agente"] or "Sin asignar",
                    "hora_ingreso": row["hora_ingreso"], "hora_salida": row["hora_salida"],
                    "consignas": row["consignas"] or "—", "observaciones": row["observaciones"] or "—",
                })

            # EAS uses CP/JP/AUX roles rather than lugares_servicio. Include those
            # details in the same dashboard grouping without treating AUX as required.
            cursor.execute("""
                SELECT dp.id AS distribucion_id,d.id AS distrito_id,d.nombre AS distrito,
                       ed.id AS detalle_id,ed.eas_id,e.nombre AS eas_nombre,
                       ed.ruta_id,r.nombre AS ruta,ed.configuracion_id,ed.rol,ed.agente_id,
                       vp.nombre_completo AS agente
                FROM dbo.distribuciones_personal dp
                INNER JOIN dbo.catalogo_detalles d ON d.id=dp.distrito_id
                INNER JOIN dbo.distribucion_eas_detalle ed ON ed.distribucion_id=dp.id AND ed.deleted_at IS NULL
                INNER JOIN dbo.eas_estaciones e ON e.id=ed.eas_id
                INNER JOIN dbo.rutas r ON r.id=ed.ruta_id
                LEFT JOIN dbo.vw_personal_detalle vp ON vp.id=ed.agente_id
                WHERE dp.turno_id=? AND dp.fecha_distribucion=? AND dp.deleted_at IS NULL
                ORDER BY d.nombre,e.nombre,r.nombre,ed.configuracion_id,ed.rol
            """, group["turno_id"], group["fecha_distribucion"])
            for row in _rows(cursor):
                district_id = int(row["distrito_id"])
                if district_id not in by_district:
                    by_district[district_id] = {
                        "id": int(row["distribucion_id"]), "distrito_id": district_id,
                        "distrito": row["distrito"], "total_asignado": 0,
                        "rutas": [], "faltantes_detalle": [],
                    }
                    place_requirements[district_id] = {}
                    route_lookup[district_id] = {}
                district = by_district[district_id]
                if row["rol"] == "AUX":
                    continue
                detail_id = int(row["detalle_id"])
                place_requirements[district_id][detail_id] = 1
                if row["agente_id"] is not None:
                    district["total_asignado"] += 1
                else:
                    district["faltantes_detalle"].append({"ruta": row["ruta"], "lugar": f"{row['eas_nombre']} · {row['rol']}"})
                route_key = (int(row["ruta_id"]), int(row["eas_id"]), int(row["configuracion_id"] or 0))
                if route_key not in route_lookup[district_id]:
                    route = {"id": f"eas-{route_key[0]}-{route_key[1]}-{route_key[2]}", "ruta": f"{row['eas_nombre']} · {row['ruta']}", "filas": []}
                    route_lookup[district_id][route_key] = route
                    district["rutas"].append(route)
                route_lookup[district_id][route_key]["filas"].append({
                    "lugar": row["rol"], "agente": row["agente"] or "Sin asignar",
                    "hora_ingreso": None, "hora_salida": None, "consignas": "—", "observaciones": "—",
                })

            dists = []
            group["total_requerido"] = 0
            group["total_asignado"] = 0
            for district_id, district in by_district.items():
                required = sum(place_requirements[district_id].values())
                assigned = int(district["total_asignado"])
                pending = max(0, required - assigned)
                complete = district["id"] is not None and required > 0 and pending == 0
                district.update({
                    "estado": "COMPLETA" if complete else "INCOMPLETA",
                    "porcentaje_cobertura": round(assigned / required * 100, 1) if required else 0,
                    "total_requerido": required, "pendientes": pending, "es_completa": complete,
                })
                dists.append(district)
                group["total_requerido"] += required
                group["total_asignado"] += assigned
            total_req = group["total_requerido"]
            total_asg = group["total_asignado"]
            total_pend = max(0, total_req - total_asg)
            cobertura = round(total_asg / total_req * 100, 1) if total_req > 0 else 0
            todos_completos = bool(dists) and all(d["es_completa"] for d in dists)
            nombre = f"DISTRIBUCION FECHA {group['fecha_distribucion']}" if group["fecha_distribucion"] else "Sin fecha"

            result.append({
                "id": f"{group['fecha_distribucion']}_{group['turno_id']}",
                "nombre": nombre,
                "fecha_distribucion": group["fecha_distribucion"],
                "turno": group["turno"],
                "turno_id": group["turno_id"],
                "creado_por": group["creado_por"],
                "fecha_creacion": group["fecha_creacion"],
                "distritos": dists,
                "total_requerido": total_req,
                "total_asignado": total_asg,
                "pendientes": total_pend,
                "porcentaje_cobertura": cobertura,
                "es_completa": todos_completos,
                "total_distritos": len(dists),
                "distritos_completos": sum(1 for d in dists if d["es_completa"]),
            })

        return {"distribuciones": result}
