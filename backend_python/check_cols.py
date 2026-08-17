from app.core.db import get_connection

with get_connection() as connection:
    cursor = connection.cursor()

    print("=== Catálogos relevantes ===")
    cursor.execute("""
        SELECT c.codigo, cd.id, cd.codigo AS detalle, cd.nombre
        FROM dbo.catalogos c
        INNER JOIN dbo.catalogo_detalles cd ON cd.catalogo_id = c.id AND cd.estado = 1
        WHERE c.codigo IN ('HORARIOS','INTERVALOS_ROTACION','TIPOS_FRANCO','TIPOS_ROTACION')
        ORDER BY c.codigo, cd.orden
    """)
    for codigo, cid, detalle, nombre in cursor.fetchall():
        print(f"  {codigo:22s} id={cid:<4d} {detalle:18s} {nombre}")

    print("\n=== Valores actuales de tipo_rotacion_id (29 filas) ===")
    cursor.execute("""
        SELECT r.nombre AS rol, cd.nombre AS rotacion, COUNT(*) AS n
        FROM dbo.personal p
        LEFT JOIN dbo.roles r ON r.id = p.rol_id
        LEFT JOIN dbo.catalogo_detalles cd ON cd.id = p.tipo_rotacion_id
        WHERE p.tipo_rotacion_id IS NOT NULL
        GROUP BY r.nombre, cd.nombre ORDER BY COUNT(*) DESC
    """)
    for rol, rotacion, n in cursor.fetchall():
        print(f"  {str(rol):16s} -> {rotacion} x{n}")

    print("\n=== ¿Alguna vista/procedimiento referencia las columnas candidatas? ===")
    cursor.execute("""
        SELECT OBJECT_NAME(object_id) AS objeto, definition
        FROM sys.sql_modules
        WHERE definition LIKE N'%horario_id%' OR definition LIKE N'%foto_perfil_url%'
           OR definition LIKE N'%tipo_rotacion_id%' OR definition LIKE N'%intervalo_rotacion_id%'
           OR definition LIKE N'%tipo_franco_id%' OR definition LIKE N'%plantilla_rotacion_id%'
           OR definition LIKE N'%fecha_inicio_rotacion%' OR definition LIKE N'%orden_inicio_rotacion%'
           OR definition LIKE N'%observacion%'
        ORDER BY OBJECT_NAME(object_id)
    """)
    for obj, definition in cursor.fetchall():
        print(f"  objeto: {obj}")

    print("\n=== ¿La vista vw_personal_detalle referencia esas columnas? ===")
    cursor.execute("""
        SELECT c.name
        FROM sys.columns c
        WHERE c.object_id = OBJECT_ID(N'dbo.vw_personal_detalle')
        ORDER BY c.column_id
    """)
    print("  columnas de vw_personal_detalle:", [r[0] for r in cursor.fetchall()])

    print("\n=== Índices/FKs sobre dbo.personal que usen esas columnas ===")
    cursor.execute("""
        SELECT i.name AS indice, col.name AS columna
        FROM sys.index_columns ic
        INNER JOIN sys.indexes i ON i.object_id = ic.object_id AND i.index_id = ic.index_id
        INNER JOIN sys.columns col ON col.object_id = ic.object_id AND col.column_id = ic.column_id
        WHERE ic.object_id = OBJECT_ID(N'dbo.personal')
          AND col.name IN ('horario_id','intervalo_rotacion_id','tipo_franco_id','tipo_rotacion_id',
                           'plantilla_rotacion_id','fecha_inicio_rotacion','orden_inicio_rotacion',
                           'foto_perfil_url','observacion')
    """)
    filas = cursor.fetchall()
    print("  ", filas if filas else "ninguna")
