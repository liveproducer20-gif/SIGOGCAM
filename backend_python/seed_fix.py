"""Delete seed personal records and re-seed with correct IDs."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.core.db import get_connection

with get_connection() as conn:
    c = conn.cursor()

    # Find the admin users to keep (those with password_hash NOT NULL or existing before seeding)
    c.execute("SELECT COUNT(*) FROM dbo.personal WHERE password_hash IS NOT NULL")
    with_pwd = c.fetchone()[0]
    print(f"Personal with password_hash: {with_pwd}")

    # Get IDs of users that existed before our seed (those created before today or with password_hash)
    c.execute("""
        SELECT id FROM dbo.personal
        WHERE password_hash IS NOT NULL
           OR fecha_creacion < DATEADD(HOUR, -2, SYSDATETIME())
    """)
    keep_ids = {row[0] for row in c.fetchall()}
    print(f"Keeping {len(keep_ids)} pre-existing records")

    # Delete all seed records (no FK dependencies on recently-inserted personal)
    c.execute("""
        DELETE FROM dbo.personal
        WHERE id NOT IN (SELECT id FROM dbo.personal WHERE password_hash IS NOT NULL OR fecha_creacion < DATEADD(HOUR, -2, SYSDATETIME()))
    """)
    deleted = c.rowcount
    conn.commit()
    print(f"Deleted {deleted} seed records")

    # Now re-seed with correct IDs
    import random

    NOMBRES_H = ["Carlos","Miguel","Juan","Luis","Francisco","José","Antonio","Manuel","Roberto","Pedro","Jorge","Ricardo","Fernando","Eduardo","Sergio","Andrés","Diego","Raúl","Oscar","Alberto","Rafael","Arturo","Enrique","Gustavo","Pablo","Héctor","Rubén","Martín","Eugenio","Leonardo","Adrián","Santiago","Tomás","Mateo","Daniel","Alejandro","Sebastián","Nicolás","Emilio","Vicente"]
    NOMBRES_M = ["María","Ana","Carmen","Rosa","Laura","Patricia","Claudia","Sandra","Lucía","Gabriela","Verónica","Adriana","Silvia","Teresa","Mónica","Roxana","Paola","Diana","Daniela","Valeria","Camila","Andrea","Fernanda","Susana","Gloria","Tatiana","Natalia","Alejandra","Carolina","Isabel"]
    APELLIDOS = ["Ramírez","Morales","Vásquez","López","García","Martínez","Hernández","González","Rodríguez","Pérez","Sánchez","Torres","Flores","Rivera","Gómez","Díaz","Cruz","Reyes","Ortiz","Gutiérrez","Chávez","Ramos","Ruiz","Alvarado","Paredes","Benítez","Méndez","Castillo","Espinoza","Vera","Suárez","Fuentes","Herrera","Medina","Castro","Guerrero","Loor","Caicedo","Zambrano","Jaramillo"]
    PROVINCIAS = ["09","01","02","03","04","05","06","07","08","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24"]

    def rnd_ced():
        return random.choice(PROVINCIAS) + "".join([str(random.randint(0,9)) for _ in range(8)])
    def rnd_ph():
        return "09" + "".join([str(random.randint(0,9)) for _ in range(8)])
    def rnd_email(n, a, s):
        return f"{n.lower()}.{a.split()[0].lower()}{s}@{random.choice(['seguraep.gob.ec','gcam.gob.ec','seguridad.gob.ec'])}"
    def rnd_dt():
        return f"{random.randint(2018,2025):04d}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    def rnd_bd():
        return f"{random.randint(1980,2000):04d}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    def rnd_names():
        g = random.choice(["M","F"])
        n = random.choice(NOMBRES_H if g=="M" else NOMBRES_M)
        a1 = random.choice(APELLIDOS)
        a2 = random.choice([a for a in APELLIDOS if a!=a1])
        return n, f"{a1} {a2}"

    # Correct IDs from DB
    ROL_INSPECTOR = 6
    ROL_AGENTE = 2
    GRADO_INSPECTOR = 1136
    GRADO_AGENTE1 = 2132
    GRADO_AGENTE2 = 1132
    ESTADO_ACTIVO = 95
    AREA_OPERATIVA = 10  # from catalog
    FUNC_SUPERVISION = None
    FUNC_FILA = None
    JOR_DIURNA = None
    GRUPO_A = None
    GRUPO_B = None

    # Lookup actual catalog IDs
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='OPERATIVA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='AREAS')")
    row = c.fetchone(); AREA_OPERATIVA = row[0] if row else AREA_OPERATIVA
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='SUPERVISION' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='FUNCIONES_OPERATIVAS')")
    row = c.fetchone(); FUNC_SUPERVISION = row[0] if row else None
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='FILA_PEDESTRE' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='FUNCIONES_OPERATIVAS')")
    row = c.fetchone(); FUNC_FILA = row[0] if row else None
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='DIURNA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='JORNADAS')")
    row = c.fetchone(); JOR_DIURNA = row[0] if row else None
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_A' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
    row = c.fetchone(); GRUPO_A = row[0] if row else None
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_B' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
    row = c.fetchone(); GRUPO_B = row[0] if row else None

    print(f"\nIDs correctos: rol_inspector={ROL_INSPECTOR}, rol_agente={ROL_AGENTE}")
    print(f"  grado_inspector={GRADO_INSPECTOR}, grado_agente1={GRADO_AGENTE1}, grado_agente2={GRADO_AGENTE2}")
    print(f"  estado_activo={ESTADO_ACTIVO}, area={AREA_OPERATIVA}")
    print(f"  func_sup={FUNC_SUPERVISION}, func_fila={FUNC_FILA}, jor={JOR_DIURNA}, gA={GRUPO_A}, gB={GRUPO_B}")

    used_cedulas = set()
    c.execute("SELECT cedula FROM dbo.personal")
    for row in c.fetchall():
        used_cedulas.add(row[0])

    # 30 INSPECTORES
    print("\nCreando 30 inspectores...")
    for i in range(30):
        while True:
            cedula = rnd_ced()
            if cedula not in used_cedulas:
                used_cedulas.add(cedula)
                break
        nombres, apellidos = rnd_names()
        email = rnd_email(nombres, apellidos, f".ins{i+1}")
        grupo = GRUPO_A if i % 2 == 0 else GRUPO_B
        c.execute("""
            INSERT INTO dbo.personal
                (cedula, nombres, apellidos, correo_institucional, telefono,
                 fecha_nacimiento, fecha_ingreso, area_id, jornada_id, grupo_id,
                 rol_id, grado_id, estado_personal_id, funcion_operativa_id,
                 password_hash, activo, fecha_creacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, SYSDATETIME())
        """, cedula, nombres, apellidos, email, rnd_ph(),
            rnd_bd(), rnd_dt(), AREA_OPERATIVA, JOR_DIURNA, grupo,
            ROL_INSPECTOR, GRADO_INSPECTOR, ESTADO_ACTIVO, FUNC_SUPERVISION)
        print(f"  [{i+1:2d}/30] {nombres} {apellidos} | C.I. {cedula}")

    # 50 AGENTES (25 Agente 1 + 25 Agente 2)
    print("\nCreando 50 agentes...")
    for i in range(50):
        while True:
            cedula = rnd_ced()
            if cedula not in used_cedulas:
                used_cedulas.add(cedula)
                break
        nombres, apellidos = rnd_names()
        email = rnd_email(nombres, apellidos, f".age{i+1}")
        grado = GRADO_AGENTE1 if i < 25 else GRADO_AGENTE2
        glbl = "Agente 1" if i < 25 else "Agente 2"
        grupo = GRUPO_A if i % 2 == 0 else GRUPO_B
        c.execute("""
            INSERT INTO dbo.personal
                (cedula, nombres, apellidos, correo_institucional, telefono,
                 fecha_nacimiento, fecha_ingreso, area_id, jornada_id, grupo_id,
                 rol_id, grado_id, estado_personal_id, funcion_operativa_id,
                 password_hash, activo, fecha_creacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, SYSDATETIME())
        """, cedula, nombres, apellidos, email, rnd_ph(),
            rnd_bd(), rnd_dt(), AREA_OPERATIVA, JOR_DIURNA, grupo,
            ROL_AGENTE, grado, ESTADO_ACTIVO, FUNC_FILA)
        print(f"  [{i+1:2d}/50] {glbl}: {nombres} {apellidos} | C.I. {cedula}")

    conn.commit()
    print("\nListo: 30 inspectores + 50 agentes creados correctamente")
    print("Contrasena por defecto: numero de cedula")
