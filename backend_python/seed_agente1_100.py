"""Create 100 additional Agente 1 users."""
import random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from app.core.db import get_connection

NOMBRES_H = ["Carlos","Miguel","Juan","Luis","Francisco","José","Antonio","Manuel","Roberto","Pedro","Jorge","Ricardo","Fernando","Eduardo","Sergio","Andrés","Diego","Raúl","Oscar","Alberto","Rafael","Arturo","Enrique","Gustavo","Pablo","Héctor","Rubén","Martín","Eugenio","Leonardo","Adrián","Santiago","Tomás","Mateo","Daniel","Alejandro","Sebastián","Nicolás","Emilio","Vicente"]
NOMBRES_M = ["María","Ana","Carmen","Rosa","Laura","Patricia","Claudia","Sandra","Lucía","Gabriela","Verónica","Adriana","Silvia","Teresa","Mónica","Roxana","Paola","Diana","Daniela","Valeria","Camila","Andrea","Fernanda","Susana","Gloria","Tatiana","Natalia","Alejandra","Carolina","Isabel"]
APELLIDOS = ["Ramírez","Morales","Vásquez","López","García","Martínez","Hernández","González","Rodríguez","Pérez","Sánchez","Torres","Flores","Rivera","Gómez","Díaz","Cruz","Reyes","Ortiz","Gutiérrez","Chávez","Ramos","Ruiz","Alvarado","Paredes","Benítez","Méndez","Castillo","Espinoza","Vera","Suárez","Fuentes","Herrera","Medina","Castro","Guerrero","Loor","Caicedo","Zambrano","Jaramillo"]
PROVINCIAS = ["09","01","02","03","04","05","06","07","08","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24"]

with get_connection() as conn:
    c = conn.cursor()

    c.execute("SELECT cedula FROM dbo.personal")
    used = {row[0] for row in c.fetchall()}

    ROL_AGENTE = 2
    GRADO_AGENTE1 = 2132
    ESTADO_ACTIVO = 95

    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='OPERATIVA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='AREAS')")
    AREA = c.fetchone()[0]
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='FILA_PEDESTRE' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='FUNCIONES_OPERATIVAS')")
    FUNC = c.fetchone()[0]
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='DIURNA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='JORNADAS')")
    JOR = c.fetchone()[0]
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_A' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
    GA = c.fetchone()[0]
    c.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_B' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
    GB = c.fetchone()[0]

    print(f"Creando 100 Agentes 1...")
    for i in range(100):
        while True:
            cedula = random.choice(PROVINCIAS) + "".join([str(random.randint(0,9)) for _ in range(8)])
            if cedula not in used:
                used.add(cedula)
                break
        g = random.choice(["M","F"])
        nombre = random.choice(NOMBRES_H if g=="M" else NOMBRES_M)
        a1 = random.choice(APELLIDOS)
        a2 = random.choice([a for a in APELLIDOS if a != a1])
        apellidos = f"{a1} {a2}"
        email = f"{nombre.lower()}.{a1.lower()}.a{i+1}@{random.choice(['seguraep.gob.ec','gcam.gob.ec'])}"
        tel = "09" + "".join([str(random.randint(0,9)) for _ in range(8)])
        fnac = f"{random.randint(1980,2000):04d}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        fing = f"{random.randint(2018,2025):04d}-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
        grupo = GA if i % 2 == 0 else GB
        c.execute("""
            INSERT INTO dbo.personal
                (cedula, nombres, apellidos, correo_institucional, telefono,
                 fecha_nacimiento, fecha_ingreso, area_id, jornada_id, grupo_id,
                 rol_id, grado_id, estado_personal_id, funcion_operativa_id,
                 password_hash, activo, fecha_creacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, SYSDATETIME())
        """, cedula, nombre, apellidos, email, tel, fnac, fing, AREA, JOR, grupo,
            ROL_AGENTE, GRADO_AGENTE1, ESTADO_ACTIVO, FUNC)
        if (i+1) % 20 == 0 or i == 99:
            print(f"  [{i+1:3d}/100] completados")

    conn.commit()
    print(f"\nListo: 100 Agentes 1 creados")
