from datetime import date, time
from typing import Literal

from pydantic import BaseModel, Field


class SectorRequirementInput(BaseModel):
    sector_id: int
    cantidad_agentes_requeridos: int = Field(ge=0, le=100)


class RouteRequirementInput(BaseModel):
    ruta_id: int
    sectores: list[SectorRequirementInput] = Field(default_factory=list)
    cantidad_total_ruta: int | None = Field(default=None, ge=0, le=500)
    cantidad_por_sector: int | None = Field(default=None, ge=0, le=100)


class RandomAssignmentInput(BaseModel):
    ruta_id: int
    fecha_servicio: date
    turno: str = Field(min_length=1, max_length=80)
    hora_inicio: time
    hora_fin: time


class SubstituteAgentInput(BaseModel):
    sorteo_id: str = Field(min_length=1, max_length=80)
    sector_id: int
    nuevo_agente_id: int


class ConfirmAssignmentInput(BaseModel):
    sorteo_id: str = Field(min_length=1, max_length=80)
    asignaciones: list[dict] = Field(default_factory=list)


class CleanAssignmentsInput(BaseModel):
    ruta_id: int
    fecha_servicio: date
    turno: str = Field(min_length=1, max_length=80)
