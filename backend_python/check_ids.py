"""Check actual grado and role IDs, then fix seed data."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.core.db import get_connection

with get_connection() as conn:
    c = conn.cursor()
    print("=== ROLES ===")
    c.execute("SELECT id, nombre, codigo FROM dbo.roles ORDER BY id")
    for row in c.fetchall():
        print(f"  id={row[0]:3d} | {row[1]:20s} | {row[2]}")

    print("\n=== GRADOS ===")
    c.execute("SELECT id, nombre FROM dbo.grados ORDER BY id")
    for row in c.fetchall():
        print(f"  id={row[0]:4d} | {row[1]}")

    print("\n=== ESTADOS PERSONAL ===")
    c.execute("""
        SELECT cd.id, cd.nombre, cd.codigo FROM dbo.catalogo_detalles cd
        INNER JOIN dbo.catalogos c ON c.id = cd.catalogo_id
        WHERE c.codigo = 'ESTADOS_PERSONAL' ORDER BY cd.orden
    """)
    for row in c.fetchall():
        print(f"  id={row[0]:3d} | {row[1]:20s} | {row[2]}")

    print("\n=== PERSONAL: Cuentas por grado (seed recientes) ===")
    c.execute("""
        SELECT g.id, g.nombre, COUNT(*) AS cnt
        FROM dbo.personal p
        LEFT JOIN dbo.grados g ON g.id = p.grado_id
        WHERE p.activo = 1
        GROUP BY g.id, g.nombre
        ORDER BY cnt DESC
    """)
    for row in c.fetchall():
        gid = row[0] or "NULL"
        gname = row[1] or "Sin grado"
        print(f"  grado_id={gid} | {gname:25s} | {row[2]}")
