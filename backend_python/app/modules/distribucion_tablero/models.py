from datetime import date, time

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


class DraftAssignmentInput(BaseModel):
    lugar_id: int = Field(gt=0)
    agente_id: int = Field(gt=0)
    tipo_asignacion: str = Field(default="MANUAL", max_length=40)


class RouteManagerInput(BaseModel):
    ruta_id: int = Field(gt=0)
    requiere_encargado: bool
    agente_id: int | None = Field(default=None, gt=0)
    tipo_asignacion: str = Field(default="MANUAL", max_length=40)


class CircuitManagerInput(BaseModel):
    circuito_id: int = Field(gt=0)
    usar_encargado_distrito: bool = False
    agente_id: int = Field(gt=0)
    conductor_id: int | None = Field(default=None, gt=0)
    auxiliar_1_id: int | None = Field(default=None, gt=0)
    auxiliar_2_id: int | None = Field(default=None, gt=0)
    movil_id: int | None = Field(default=None, gt=0)
    tipo_asignacion: str = Field(default="MANUAL", max_length=40)


class RandomDraftInput(BaseModel):
    distrito_id: int = Field(gt=0)
    turno_id: int = Field(gt=0)
    circuito_id: int = Field(gt=0)
    asignaciones: list[DraftAssignmentInput] = Field(default_factory=list)
    excluidos: list[int] = Field(default_factory=list)


class SaveDistributionInput(BaseModel):
    distrito_id: int = Field(gt=0)
    turno_id: int = Field(gt=0)
    fecha_distribucion: date
    asignaciones: list[DraftAssignmentInput] = Field(default_factory=list)
    encargado_distrito_id: int | None = Field(default=None, gt=0)
    distrito_movil_id: int | None = Field(default=None, gt=0)
    distrito_conductor_id: int | None = Field(default=None, gt=0)
    distrito_auxiliar_1_id: int | None = Field(default=None, gt=0)
    distrito_auxiliar_2_id: int | None = Field(default=None, gt=0)
    encargados_circuito: list[CircuitManagerInput] = Field(default_factory=list)
    encargados_ruta: list[RouteManagerInput] = Field(default_factory=list)
    guardar_con_pendientes: bool = False


class AgentSearchInput(BaseModel):
    distrito_id: int = Field(gt=0)
    turno_id: int = Field(gt=0)
    ruta_id: int | None = Field(default=None, gt=0)
    lugar_id: int | None = Field(default=None, gt=0)
    tipo_responsabilidad: str = Field(default="AGENTE_LUGAR", max_length=30)
    fecha_distribucion: date | None = None
    excluidos: list[int] = Field(default_factory=list)
    grupo_id: int | None = None
    tipo_servicio_id: int | None = None
    grado_id: int | None = None
    estado: str | None = None
    search: str | None = None
    page: int = Field(default=1, ge=1)
    limit: int = Field(default=20, ge=1, le=100)


class ChangeAgentInput(BaseModel):
    distrito_id: int = Field(gt=0)
    turno_id: int = Field(gt=0)
    ruta_id: int | None = Field(default=None, gt=0)
    lugar_id: int | None = Field(default=None, gt=0)
    tipo_responsabilidad: str = Field(default="AGENTE_LUGAR", max_length=30)
    agente_nuevo_id: int = Field(gt=0)
    agente_anterior_id: int | None = None
    forzado: bool = False
    motivo_forzado: str | None = None
