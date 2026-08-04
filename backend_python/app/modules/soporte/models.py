from pydantic import BaseModel, Field


class TicketCreate(BaseModel):
    titulo: str = Field(min_length=3, max_length=200)
    descripcion: str = Field(min_length=5, max_length=3000)
    modulo: str = Field(min_length=2, max_length=100)
    prioridad: str = Field(default="Media", max_length=20)
    imagen: str | None = None


class TicketUpdate(BaseModel):
    estado: str | None = None
    prioridad: str | None = None
    asignado_a: int | None = None
    asignado_nombre: str | None = None


class CommentCreate(BaseModel):
    comentario: str = Field(min_length=2, max_length=3000)
    es_interno: bool = False
