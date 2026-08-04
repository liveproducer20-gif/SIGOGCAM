from functools import lru_cache
from typing import List

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "SIGO-GCAM"
    app_env: str = "development"
    api_prefix: str = "/api"
    host: str = "127.0.0.1"
    port: int = 8000

    jwt_secret: str = "cambie_esta_clave_por_una_segura"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 720

    db_driver: str = "ODBC Driver 18 for SQL Server"
    db_server: str = r"localhost\SQLEXPRESS"
    db_database: str = "BITSAC"
    db_user: str = ""
    db_password: str = ""
    db_trusted_connection: str = "yes"
    db_encrypt: str = "optional"
    db_trust_server_certificate: str = "yes"

    cors_origins: List[str] = ["http://127.0.0.1:8080", "http://localhost:8080"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
