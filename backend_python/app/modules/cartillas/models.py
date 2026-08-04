from typing import Any

from pydantic import BaseModel


class CartillaCreate(BaseModel):
    causa: str | None = None
    contenido: str
    tipo: str | None = None
    subtipo: str | None = None
    datos: dict[str, Any] | None = None

