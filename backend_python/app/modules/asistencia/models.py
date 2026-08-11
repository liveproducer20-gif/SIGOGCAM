from datetime import date, datetime
from pydantic import BaseModel, Field


class AttendanceRegisterInput(BaseModel):
    personal_id: int = Field(gt=0)
    distrito_id: int = Field(gt=0)
    ruta_id: int | None = Field(default=None, gt=0)
    lugar_id: int | None = Field(default=None, gt=0)
    fecha: date
    turno: str = Field(min_length=1, max_length=80)
    hora_ingreso: datetime | None = None
    estado_asistencia: str = Field(min_length=1, max_length=50)
    tipo_asignacion: str | None = Field(default=None, max_length=50)
    observaciones: str | None = Field(default=None, max_length=500)


class AttendanceUpdateInput(BaseModel):
    estado_asistencia: str | None = Field(default=None, max_length=50)
    hora_ingreso: datetime | None = None
    hora_salida: datetime | None = None
    observaciones: str | None = Field(default=None, max_length=500)


class AttendanceBatchInput(BaseModel):
    registros: list[AttendanceRegisterInput]


class AttendanceQueryInput(BaseModel):
    distrito_id: int | None = Field(default=None, gt=0)
    ruta_id: int | None = Field(default=None, gt=0)
    turno: str | None = Field(default=None, max_length=80)
    fecha_desde: date | None = None
    fecha_hasta: date | None = None
    estado_asistencia: str | None = Field(default=None, max_length=50)
    page: int = Field(default=1, ge=1)
    limit: int = Field(default=50, ge=1, le=200)
