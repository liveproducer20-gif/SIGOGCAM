from pydantic import BaseModel


class EventCreate(BaseModel):
    titulo: str
    tipoEventoId: int
    fechaInicio: str
    fechaFin: str
    lugar: str
    descripcion: str | None = None
    prioridad: str | None = None
    imagenUrl: str | None = None
    pdfNombre: str | None = None
    pdfUrl: str | None = None
    notificar: bool = True
    personalIds: list[int] | None = None


class EventStatusUpdate(BaseModel):
    estado: str
