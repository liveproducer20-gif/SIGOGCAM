from pydantic import BaseModel, Field


class PersonalInput(BaseModel):
    cedula: str = Field(min_length=3, max_length=20)
    nombres: str = Field(min_length=2, max_length=120)
    apellidos: str = Field(min_length=2, max_length=120)
    correo_institucional: str = Field(min_length=5, max_length=180)
    telefono: str | None = Field(default=None, max_length=30)
    cargo_id: int | None = None
    area_id: int | None = None
    grupo_id: int | None = None
    jornada_id: int | None = None
    rol_id: int | None = None
    grado_id: int | None = None
    estado_personal_id: int | None = None
    password: str | None = Field(default=None, min_length=4, max_length=128)
    activo: bool = True
