SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

IF OBJECT_ID(N'dbo.circuitos', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.circuitos (
        id                          INT IDENTITY(1,1) NOT NULL,
        distrito_id                 INT NOT NULL,
        nombre                      NVARCHAR(180) NOT NULL,
        encargado_id                INT NOT NULL,
        usar_encargado_distrito     BIT NOT NULL CONSTRAINT DF_circuitos_encargado_distrito DEFAULT (0),
        auxiliar_1_id               INT NULL,
        auxiliar_2_id               INT NULL,
        movil_id                    INT NULL,
        hora_inicio                 TIME(0) NULL,
        hora_fin                    TIME(0) NULL,
        lugar_formacion             NVARCHAR(300) NULL,
        consignas                   NVARCHAR(MAX) NULL,
        observaciones               NVARCHAR(MAX) NULL,
        perimetro                   NVARCHAR(MAX) NULL,
        activo                      BIT NOT NULL CONSTRAINT DF_circuitos_activo DEFAULT (1),
        fecha_creacion              DATETIME2 NOT NULL CONSTRAINT DF_circuitos_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion         DATETIME2 NULL,
        deleted_at                  DATETIME2 NULL,
        CONSTRAINT PK_circuitos PRIMARY KEY (id),
        CONSTRAINT FK_circuitos_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_circuitos_encargado FOREIGN KEY (encargado_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_circuitos_auxiliar_1 FOREIGN KEY (auxiliar_1_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_circuitos_auxiliar_2 FOREIGN KEY (auxiliar_2_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_circuitos_movil FOREIGN KEY (movil_id) REFERENCES dbo.moviles(id),
        CONSTRAINT CK_circuitos_personal_distinto CHECK (
            (auxiliar_1_id IS NULL OR auxiliar_1_id <> encargado_id) AND
            (auxiliar_2_id IS NULL OR auxiliar_2_id <> encargado_id) AND
            (auxiliar_1_id IS NULL OR auxiliar_2_id IS NULL OR auxiliar_1_id <> auxiliar_2_id)
        )
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_circuitos_distrito_nombre_activo' AND object_id = OBJECT_ID(N'dbo.circuitos'))
    CREATE UNIQUE INDEX UX_circuitos_distrito_nombre_activo
        ON dbo.circuitos(distrito_id, nombre)
        WHERE deleted_at IS NULL;
GO

IF OBJECT_ID(N'dbo.circuito_rutas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.circuito_rutas (
        id                  BIGINT IDENTITY(1,1) NOT NULL,
        circuito_id         INT NOT NULL,
        ruta_id             INT NOT NULL,
        fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_circuito_rutas_fecha DEFAULT (SYSDATETIME()),
        deleted_at          DATETIME2 NULL,
        CONSTRAINT PK_circuito_rutas PRIMARY KEY (id),
        CONSTRAINT FK_circuito_rutas_circuito FOREIGN KEY (circuito_id) REFERENCES dbo.circuitos(id),
        CONSTRAINT FK_circuito_rutas_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id)
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_circuito_rutas_circuito_ruta_activa' AND object_id = OBJECT_ID(N'dbo.circuito_rutas'))
    CREATE UNIQUE INDEX UX_circuito_rutas_circuito_ruta_activa
        ON dbo.circuito_rutas(circuito_id, ruta_id)
        WHERE deleted_at IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_circuito_rutas_ruta_activa' AND object_id = OBJECT_ID(N'dbo.circuito_rutas'))
    CREATE UNIQUE INDEX UX_circuito_rutas_ruta_activa
        ON dbo.circuito_rutas(ruta_id)
        WHERE deleted_at IS NULL;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.modulos_sistema WHERE codigo = N'circuitos')
    INSERT INTO dbo.modulos_sistema(codigo,nombre,ruta,icono,plataforma,orden_global,tiene_submenus,estado,fecha_creacion)
    VALUES(N'circuitos',N'Circuitos',N'/admin?tab=circuitos',N'route',N'web',16,0,1,SYSDATETIME());
GO

DECLARE @permisos TABLE(codigo NVARCHAR(120), descripcion NVARCHAR(255), accion NVARCHAR(80));
INSERT INTO @permisos VALUES
    (N'circuitos.ver', N'Consultar circuitos', N'ver'),
    (N'circuitos.crear', N'Crear circuitos', N'crear'),
    (N'circuitos.editar', N'Editar circuitos', N'editar'),
    (N'circuitos.rutas', N'Asignar y desasignar rutas de circuitos', N'rutas'),
    (N'circuitos.eliminar', N'Eliminar circuitos', N'eliminar');

INSERT INTO dbo.permisos(codigo,descripcion,modulo,recurso,accion,activo,fecha_creacion)
SELECT p.codigo,p.descripcion,N'administracion',N'circuitos',p.accion,1,SYSDATETIME()
FROM @permisos p
WHERE NOT EXISTS (SELECT 1 FROM dbo.permisos x WHERE x.codigo=p.codigo);

INSERT INTO dbo.rol_permiso(rol_id,permiso_id,permitido,heredado,fecha_asignacion)
SELECT r.id,p.id,1,0,SYSDATETIME()
FROM dbo.roles r
CROSS JOIN dbo.permisos p
WHERE (UPPER(r.codigo)=N'ADMINISTRADOR' OR UPPER(r.nombre)=N'ADMINISTRADOR')
  AND p.codigo LIKE N'circuitos.%'
  AND NOT EXISTS (SELECT 1 FROM dbo.rol_permiso rp WHERE rp.rol_id=r.id AND rp.permiso_id=p.id);
GO

PRINT 'Circuitos instalados correctamente.';
GO
