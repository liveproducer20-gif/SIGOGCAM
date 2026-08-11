from datetime import date

from fastapi import APIRouter, Depends, Query

from app.core.responses import ok
from app.middleware.auth import current_user, require_permission
from app.modules.asistencia import repository
from app.modules.asistencia.models import (
    AttendanceBatchInput,
    AttendanceRegisterInput,
    AttendanceUpdateInput,
)

router = APIRouter(tags=["asistencia"])


@router.get("/asistencia/catalogos")
def get_catalogs(user: dict = Depends(require_permission("asistencia.ver"))):
    return ok(repository.get_catalogs())


@router.get("/asistencia/personal-asignado")
def get_assigned(
    distrito_id: int = Query(..., gt=0),
    turno_id: int = Query(..., gt=0),
    fecha: date = Query(...),
    ruta_id: int | None = Query(default=None),
    user: dict = Depends(require_permission("asistencia.ver")),
):
    return ok(repository.get_assigned_personnel(distrito_id, ruta_id, turno_id, fecha))


@router.post("/asistencia/registrar")
def register_attendance(
    payload: AttendanceRegisterInput,
    user: dict = Depends(require_permission("asistencia.registrar")),
):
    record_id = repository.register_attendance(payload.model_dump(), int(user["id"]))
    return ok({"id": record_id}, "Asistencia registrada correctamente")


@router.post("/asistencia/lote")
def batch_register(
    payload: AttendanceBatchInput,
    user: dict = Depends(require_permission("asistencia.registrar")),
):
    result = repository.batch_register([r.model_dump() for r in payload.registros], int(user["id"]))
    return ok(result, "Proceso de asistencia completado")


@router.put("/asistencia/{asistencia_id}")
def update_attendance(
    asistencia_id: int,
    payload: AttendanceUpdateInput,
    user: dict = Depends(require_permission("asistencia.editar")),
):
    repository.update_attendance(asistencia_id, payload.model_dump(exclude_unset=True), int(user["id"]))
    return ok(None, "Asistencia actualizada correctamente")


@router.get("/asistencia/lista")
def list_attendance(
    distrito_id: int | None = Query(default=None),
    ruta_id: int | None = Query(default=None),
    turno: str | None = Query(default=None),
    fecha_desde: date | None = Query(default=None),
    fecha_hasta: date | None = Query(default=None),
    estado_asistencia: str | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=200),
    user: dict = Depends(require_permission("asistencia.ver")),
):
    return ok(repository.get_attendance_list(
        distrito_id, ruta_id, turno, fecha_desde, fecha_hasta,
        estado_asistencia, page, limit
    ))


@router.get("/asistencia/estadisticas")
def get_stats(
    distrito_id: int | None = Query(default=None),
    fecha: date = Query(...),
    turno: str | None = Query(default=None),
    user: dict = Depends(require_permission("asistencia.ver")),
):
    return ok(repository.get_attendance_stats(distrito_id, fecha, turno))


@router.post("/asistencia/poblar-distribucion")
def populate_from_distribution(
    distrito_id: int = Query(..., gt=0),
    turno_id: int = Query(..., gt=0),
    fecha: date = Query(...),
    ruta_id: int | None = Query(default=None),
    user: dict = Depends(require_permission("asistencia.registrar")),
):
    result = repository.populate_from_distribution(distrito_id, ruta_id, turno_id, fecha, int(user["id"]))
    return ok(result, "Personal de distribucion cargado a asistencia")
