"""Seed script: create 30 inspectores + 50 agentes (25 Agente 1 + 25 Agente 2)."""
import random
import sys
import os

sys.path.insert(0, os.path.dirname(__file__))

from app.core.db import get_connection

NOMBRES_H = [
    "Carlos", "Miguel", "Juan", "Luis", "Francisco", "José", "Antonio", "Manuel",
    "Roberto", "Pedro", "Jorge", "Ricardo", "Fernando", "Eduardo", "Sergio",
    "Andrés", "Diego", "Raúl", "Oscar", "Alberto", "Rafael", "Arturo", "Enrique",
    "Gustavo", "Pablo", "Héctor", "Rubén", "Martín", "Eugenio", "Leonardo",
    "Adrián", "Santiago", "Tomás", "Mateo", "Daniel", "Alejandro", "Sebastián",
    "Nicolás", "Emilio", "Vicente"
]
NOMBRES_M = [
    "María", "Ana", "Carmen", "Rosa", "Laura", "Patricia", "Claudia", "Sandra",
    "Lucía", "Gabriela", "Verónica", "Adriana", "Silvia", "Teresa", "Mónica",
    "Roxana", "Paola", "Diana", "Daniela", "Valeria", "Camila", "Andrea",
    "Fernanda", "Susana", "Gloria", "Tatiana", "Natalia", "Alejandra", "Carolina",
    "Isabel"
]
APELLIDOS = [
    "Ramírez", "Morales", "Vásquez", "López", "García", "Martínez", "Hernández",
    "González", "Rodríguez", "Pérez", "Sánchez", "Torres", "Flores", "Rivera",
    "Gómez", "Díaz", "Cruz", "Reyes", "Ortiz", "Gutiérrez", "Chávez", "Ramos",
    "Ruiz", "Alvarado", "Paredes", "Benítez", "Méndez", "Castillo", "Espinoza",
    "Vera", "Suárez", "Fuentes", "Herrera", "Medina", "Castro", "Guerrero",
    "Loor", "Caicedo", "Zambrano", "Jaramillo"
]
PROVINCIAS = ["09", "01", "02", "03", "04", "05", "06", "07", "08", "10",
              "11", "12", "13", "14", "15", "16", "17", "18", "19", "20",
              "21", "22", "23", "24"]


def random_cedula():
    prov = random.choice(PROVINCIAS)
    core = "".join([str(random.randint(0, 9)) for _ in range(8)])
    return prov + core


def random_phone():
    return "09" + "".join([str(random.randint(0, 9)) for _ in range(8)])


def random_email(nombre, apellido, suffix=""):
    base = f"{nombre.lower()}.{apellido.split()[0].lower()}"
    dominios = ["seguraep.gob.ec", "gcam.gob.ec", "seguridad.gob.ec"]
    return f"{base}{suffix}@{random.choice(dominios)}"


def random_date(start_year=2018, end_year=2025):
    y = random.randint(start_year, end_year)
    m = random.randint(1, 12)
    d = random.randint(1, 28)
    return f"{y:04d}-{m:02d}-{d:02d}"


def random_birth_date():
    y = random.randint(1980, 2000)
    m = random.randint(1, 12)
    d = random.randint(1, 28)
    return f"{y:04d}-{m:02d}-{d:02d}"


def generate_names(gender="random"):
    g = gender if gender != "random" else random.choice(["M", "F"])
    nombres = random.choice(NOMBRES_H if g == "M" else NOMBRES_M)
    a1 = random.choice(APELLIDOS)
    a2 = random.choice([a for a in APELLIDOS if a != a1])
    return nombres, f"{a1} {a2}"


def main():
    used_cedulas = set()

    with get_connection() as conn:
        cursor = conn.cursor()

        # Look up IDs from DB
        cursor.execute("SELECT id FROM dbo.roles WHERE codigo='inspector'")
        row = cursor.fetchone()
        rol_inspector = row[0] if row else 4

        cursor.execute("SELECT id FROM dbo.roles WHERE codigo='agente'")
        row = cursor.fetchone()
        rol_agente = row[0] if row else 5

        cursor.execute("SELECT id FROM dbo.grados WHERE nombre='Inspector'")
        row = cursor.fetchone()
        grado_inspector = row[0] if row else 6

        cursor.execute("SELECT id FROM dbo.grados WHERE nombre='Agente 1'")
        row = cursor.fetchone()
        grado_agente1 = row[0] if row else 1

        cursor.execute("SELECT id FROM dbo.grados WHERE nombre='Agente 2'")
        row = cursor.fetchone()
        grado_agente2 = row[0] if row else 2

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='ACTIVO' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='ESTADOS_PERSONAL')")
        row = cursor.fetchone()
        estado_activo = row[0] if row else 95

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='OPERATIVA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='AREAS')")
        row = cursor.fetchone()
        area_operativa = row[0] if row else None

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='SUPERVISION' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='FUNCIONES_OPERATIVAS')")
        row = cursor.fetchone()
        func_supervision = row[0] if row else None

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='FILA_PEDESTRE' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='FUNCIONES_OPERATIVAS')")
        row = cursor.fetchone()
        func_fila = row[0] if row else None

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='DIURNA' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='JORNADAS')")
        row = cursor.fetchone()
        jor_diurna = row[0] if row else None

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_A' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
        row = cursor.fetchone()
        grupo_a = row[0] if row else None

        cursor.execute("SELECT id FROM dbo.catalogo_detalles WHERE codigo='GRUPO_B' AND catalogo_id IN (SELECT id FROM dbo.catalogos WHERE codigo='GRUPOS')")
        row = cursor.fetchone()
        grupo_b = row[0] if row else None

        print(f"IDs: rol_inspector={rol_inspector}, rol_agente={rol_agente}, grado_inspector={grado_inspector}, "
              f"grado_agente1={grado_agente1}, grado_agente2={grado_agente2}, estado_activo={estado_activo}")

        # === 30 INSPECTORES ===
        print("\nCreando 30 inspectores...")
        for i in range(30):
            while True:
                cedula = random_cedula()
                if cedula not in used_cedulas:
                    used_cedulas.add(cedula)
                    break
            nombres, apellidos = generate_names()
            email = random_email(nombres, apellidos, f".{i+1}")
            grupo = grupo_a if i % 2 == 0 else grupo_b
            cursor.execute("""
                INSERT INTO dbo.personal
                    (cedula, nombres, apellidos, correo_institucional, telefono,
                     fecha_nacimiento, fecha_ingreso, area_id, jornada_id, grupo_id,
                     rol_id, grado_id, estado_personal_id, funcion_operativa_id,
                     password_hash, activo, fecha_creacion)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, SYSDATETIME())
            """, cedula, nombres, apellidos, email, random_phone(),
                random_birth_date(), random_date(), area_operativa, jor_diurna, grupo,
                rol_inspector, grado_inspector, estado_activo, func_supervision)
            print(f"  [{i+1:2d}/30] Inspector: {nombres} {apellidos} | C.I. {cedula}")

        # === 50 AGENTES (25 Agente 1 + 25 Agente 2) ===
        print("\nCreando 50 agentes...")
        for i in range(50):
            while True:
                cedula = random_cedula()
                if cedula not in used_cedulas:
                    used_cedulas.add(cedula)
                    break
            nombres, apellidos = generate_names()
            email = random_email(nombres, apellidos, f".{i+31}")
            grado = grado_agente1 if i < 25 else grado_agente2
            grado_label = "Agente 1" if i < 25 else "Agente 2"
            grupo = grupo_a if i % 2 == 0 else grupo_b
            cursor.execute("""
                INSERT INTO dbo.personal
                    (cedula, nombres, apellidos, correo_institucional, telefono,
                     fecha_nacimiento, fecha_ingreso, area_id, jornada_id, grupo_id,
                     rol_id, grado_id, estado_personal_id, funcion_operativa_id,
                     password_hash, activo, fecha_creacion)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NULL, 1, SYSDATETIME())
            """, cedula, nombres, apellidos, email, random_phone(),
                random_birth_date(), random_date(), area_operativa, jor_diurna, grupo,
                rol_agente, grado, estado_activo, func_fila)
            num = i + 1
            print(f"  [{num:2d}/50] {grado_label}: {nombres} {apellidos} | C.I. {cedula}")

        conn.commit()
        print(f"\n✅ Listo: 30 inspectores + 50 agentes creados (total 80 registros)")
        print("   Contraseña por defecto: número de cédula")


if __name__ == "__main__":
    main()
