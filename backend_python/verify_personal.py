"""Verify seeded personal counts."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.core.db import get_connection

with get_connection() as conn:
    c = conn.cursor()
    c.execute("SELECT COUNT(*) FROM dbo.personal WHERE activo=1")
    total = c.fetchone()[0]
    print(f"Total personal activo: {total}")

    c.execute("""
        SELECT r.nombre AS rol, g.nombre AS grado, COUNT(*) AS cnt
        FROM dbo.personal p
        LEFT JOIN dbo.roles r ON r.id = p.rol_id
        LEFT JOIN dbo.grados g ON g.id = p.grado_id
        WHERE p.activo = 1
        GROUP BY r.nombre, g.nombre
        ORDER BY r.nombre, g.nombre
    """)
    print("\nDesglose por rol y grado:")
    for row in c.fetchall():
        rol = row[0] or "Sin rol"
        grado = row[1] or "Sin grado"
        print(f"  {rol:20s} | {grado:20s} | {row[2]} personas")
