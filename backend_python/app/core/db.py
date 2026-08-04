from contextlib import contextmanager

import pyodbc

from app.core.config import settings


def build_connection_string() -> str:
    parts = [
        f"DRIVER={{{settings.db_driver}}}",
        f"SERVER={settings.db_server}",
        f"DATABASE={settings.db_database}",
        f"Encrypt={settings.db_encrypt}",
        f"TrustServerCertificate={settings.db_trust_server_certificate}",
    ]

    if settings.db_user and settings.db_password:
        parts.extend([f"UID={settings.db_user}", f"PWD={settings.db_password}"])
    else:
        parts.append(f"Trusted_Connection={settings.db_trusted_connection}")

    return ";".join(parts)


@contextmanager
def get_connection():
    connection = pyodbc.connect(build_connection_string(), autocommit=False)
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()

