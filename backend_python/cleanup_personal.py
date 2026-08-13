"""Remove the seed records we just created and re-seed."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.core.db import get_connection

with get_connection() as conn:
    c = conn.cursor()
    # Delete all seed personal we just created (those with NULL password_hash)
    c.execute("DELETE FROM dbo.personal WHERE password_hash IS NULL AND activo=1")
    deleted = c.rowcount
    conn.commit()
    print(f"Eliminados {deleted} registros de personal con password_hash=NULL")
