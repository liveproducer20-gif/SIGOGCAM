from pydantic import BaseModel


class AnnouncementCreate(BaseModel):
    titulo: str
    descripcion: str
    prioridad: str | None = "Normal"
    imagenNombre: str | None = None
    imagenUrl: str | None = None
    fechaExpiracion: str | None = None
    publicado: bool = True
    notificar: bool = True
    personalIds: list[int] | None = None


class PublishedUpdate(BaseModel):
    publicado: bool
