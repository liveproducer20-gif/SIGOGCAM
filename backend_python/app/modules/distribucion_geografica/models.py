from datetime import date, time
from decimal import Decimal

from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


class AssignmentInput(BaseModel):
    personal_id: int
    tipo_asignacion: str = "FIJA"
    fecha_inicio: date
    fecha_fin: date | None = None
    turno_id: int
    hora_inicio: time
    hora_fin: time
    funcion: str | None = None
    observaciones: str | None = None

    @model_validator(mode="after")
    def valid_dates(self):
        if self.fecha_fin and self.fecha_fin < self.fecha_inicio:
            raise ValueError("La fecha de finalización no puede ser anterior a la fecha de inicio")
        return self


class PointInput(BaseModel):
    distrito_id: int
    ruta_id: int
    sector_id: int | None = None
    nombre: str = Field(min_length=3, max_length=180)
    ubicacion_especifica: str = Field(min_length=3, max_length=220)
    direccion: str = Field(min_length=3, max_length=300)
    latitud: Decimal
    longitud: Decimal
    tipo_servicio_id: int
    turno_id: int
    hora_inicio: time
    hora_fin: time
    cantidad_requerida: int = Field(ge=1, le=100)
    observaciones: str | None = Field(default=None, max_length=500)
    estado: Literal["CUBIERTO", "SIN_ASIGNACION", "FUERA_TURNO", "INACTIVO", "NOVEDAD", "PENDIENTE"] = "SIN_ASIGNACION"
    asignaciones: list[AssignmentInput] = Field(default_factory=list)

    @field_validator("latitud")
    @classmethod
    def valid_latitude(cls, value: Decimal):
        if value < Decimal("-90") or value > Decimal("90"):
            raise ValueError("La latitud no es válida")
        return value

    @field_validator("longitud")
    @classmethod
    def valid_longitude(cls, value: Decimal):
        if value < Decimal("-180") or value > Decimal("180"):
            raise ValueError("La longitud no es válida")
        return value


class AssignmentUpdate(AssignmentInput):
    estado: str = "ACTIVA"


class RouteInput(BaseModel):
    distrito_id: int
    nombre: str = Field(min_length=3, max_length=180)
    turno_id: int | None = None
    hora_inicio: time | None = None
    hora_fin: time | None = None


class SectorInput(BaseModel):
    distrito_id: int
    ruta_id: int
    nombre: str = Field(min_length=3, max_length=180)
