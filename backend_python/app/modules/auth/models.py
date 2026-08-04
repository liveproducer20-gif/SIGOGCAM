from pydantic import BaseModel, field_validator


class LoginRequest(BaseModel):
    correo: str
    password: str

    @field_validator("correo")
    @classmethod
    def validate_correo(cls, value: str) -> str:
        value = value.strip().lower()
        if "@" not in value:
            raise ValueError("Ingrese un correo institucional válido")
        return value
