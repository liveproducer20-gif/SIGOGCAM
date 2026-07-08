USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

IF OBJECT_ID('dbo.personal', 'U') IS NULL
BEGIN
    THROW 50200, 'No existe dbo.personal. Verifique la base de datos BITSAC.', 1;
END;

IF COL_LENGTH('dbo.personal', 'total_cartillas_generadas') IS NULL
BEGIN
    ALTER TABLE dbo.personal
        ADD total_cartillas_generadas INT NOT NULL
            CONSTRAINT DF_personal_total_cartillas_generadas DEFAULT (0);
END;

IF OBJECT_ID('dbo.insignias', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.insignias (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_insignias PRIMARY KEY,
        codigo NVARCHAR(80) NOT NULL,
        titulo NVARCHAR(160) NOT NULL,
        descripcion NVARCHAR(700) NOT NULL,
        meta_cartillas INT NOT NULL,
        categoria NVARCHAR(80) NOT NULL CONSTRAINT DF_insignias_categoria DEFAULT ('cartillas'),
        icono NVARCHAR(20) NULL,
        activo BIT NOT NULL CONSTRAINT DF_insignias_activo DEFAULT (1),
        fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_insignias_fecha_creacion DEFAULT (SYSDATETIME())
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.insignias')
      AND name = 'UX_insignias_codigo'
)
BEGIN
    CREATE UNIQUE INDEX UX_insignias_codigo ON dbo.insignias(codigo);
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.insignias')
      AND name = 'UX_insignias_meta_cartillas'
)
BEGIN
    CREATE UNIQUE INDEX UX_insignias_meta_cartillas ON dbo.insignias(meta_cartillas);
END;

IF OBJECT_ID('dbo.usuario_insignias', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.usuario_insignias (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_usuario_insignias PRIMARY KEY,
        usuario_id INT NOT NULL,
        insignia_id INT NOT NULL,
        total_cartillas_al_desbloquear INT NOT NULL,
        fecha_desbloqueo DATETIME2(0) NOT NULL CONSTRAINT DF_usuario_insignias_fecha_desbloqueo DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_usuario_insignias_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_usuario_insignias_insignias FOREIGN KEY (insignia_id) REFERENCES dbo.insignias(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.usuario_insignias')
      AND name = 'UX_usuario_insignias_usuario_insignia'
)
BEGIN
    CREATE UNIQUE INDEX UX_usuario_insignias_usuario_insignia
        ON dbo.usuario_insignias(usuario_id, insignia_id);
END;

IF OBJECT_ID('dbo.cartillas_generadas', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.cartillas_generadas (
        id INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_cartillas_generadas PRIMARY KEY,
        usuario_id INT NOT NULL,
        causa NVARCHAR(160) NULL,
        contenido NVARCHAR(MAX) NOT NULL,
        fecha_creacion DATETIME2(0) NOT NULL CONSTRAINT DF_cartillas_generadas_fecha_creacion DEFAULT (SYSDATETIME()),
        CONSTRAINT FK_cartillas_generadas_personal FOREIGN KEY (usuario_id) REFERENCES dbo.personal(id)
    );
END;

IF NOT EXISTS (
    SELECT 1
    FROM sys.indexes
    WHERE object_id = OBJECT_ID('dbo.cartillas_generadas')
      AND name = 'IX_cartillas_generadas_usuario_fecha'
)
BEGIN
    CREATE INDEX IX_cartillas_generadas_usuario_fecha
        ON dbo.cartillas_generadas(usuario_id, fecha_creacion DESC);
END;

DECLARE @insignias TABLE (
    codigo NVARCHAR(80) NOT NULL,
    titulo NVARCHAR(160) NOT NULL,
    descripcion NVARCHAR(700) NOT NULL,
    meta_cartillas INT NOT NULL,
    icono NVARCHAR(20) NULL
);

INSERT INTO @insignias (codigo, titulo, descripcion, meta_cartillas, icono)
VALUES
('cartillas_005', N'Agente Amateur', N'Felicidades, por haber realizado 5 cartillas has obtenido la insignia Agente Amateur. Sigue asi y seras el mejor.', 5, N'5'),
('cartillas_010', N'Redactor Novato', N'Excelente trabajo. Ya llevas 10 cartillas realizadas y desbloqueaste la insignia Redactor Novato.', 10, N'10'),
('cartillas_015', N'Cronista Operativo', N'Vas por muy buen camino. Has generado 15 cartillas y obtuviste la insignia Cronista Operativo.', 15, N'15'),
('cartillas_020', N'Agente Comprometido', N'Tu constancia comienza a marcar la diferencia. Has completado 20 cartillas y desbloqueaste la insignia Agente Comprometido.', 20, N'20'),
('cartillas_025', N'Reportero Activo', N'Tu productividad sigue creciendo. Has elaborado 25 cartillas y obtuviste la insignia Reportero Activo.', 25, N'25'),
('cartillas_030', N'Guardia de Novedades', N'Excelente desempeno. Alcanzaste 30 cartillas y desbloqueaste la insignia Guardia de Novedades.', 30, N'30'),
('cartillas_035', N'Operador Estrategico', N'Tu experiencia sigue aumentando. Has registrado 35 cartillas y obtuviste la insignia Operador Estrategico.', 35, N'35'),
('cartillas_040', N'Coordinador de Cartillas', N'Ya eres un referente en la generacion de reportes. Has completado 40 cartillas y desbloqueaste la insignia Coordinador de Cartillas.', 40, N'40'),
('cartillas_045', N'Supervisor de Incidencias', N'Tu dedicacion fortalece las operaciones. Has alcanzado 45 cartillas y obtuviste la insignia Supervisor de Incidencias.', 45, N'45'),
('cartillas_050', N'Agente Destacado', N'Gran logro. Llegaste a 50 cartillas y desbloqueaste la insignia Agente Destacado.', 50, N'50'),
('cartillas_060', N'Especialista Operativo', N'Tu compromiso operativo sigue creciendo. Has alcanzado 60 cartillas y desbloqueaste la insignia Especialista Operativo.', 60, N'60'),
('cartillas_070', N'Experto en Reportes', N'Tu dominio en la generacion de cartillas es evidente. Has completado 70 cartillas y obtuviste la insignia Experto en Reportes.', 70, N'70'),
('cartillas_080', N'Centinela Institucional', N'Has demostrado constancia y responsabilidad institucional. Alcanzaste 80 cartillas y desbloqueaste la insignia Centinela Institucional.', 80, N'80'),
('cartillas_090', N'Maestro de Cartillas', N'Tu experiencia te convierte en un referente. Has generado 90 cartillas y obtuviste la insignia Maestro de Cartillas.', 90, N'90'),
('cartillas_100', N'Leyenda Operativa', N'Felicidades. Has completado 100 cartillas y desbloqueaste la insignia Leyenda Operativa.', 100, N'100'),
('cartillas_110', N'Super Agente', N'Felicidades. Has alcanzado 110 cartillas y desbloqueaste la insignia Super Agente. Eres un verdadero ejemplo.', 110, N'110'),
('cartillas_120', N'El mejor de los Papamike', N'Impresionante. Con 120 cartillas te has ganado la insignia El mejor de los Papamike. Nadie te supera.', 120, N'120'),
('cartillas_130', N'El loco de las Cartillas', N'Increible. Has generado 130 cartillas y desbloqueaste la insignia El loco de las Cartillas. Eres una maquina.', 130, N'130'),
('cartillas_140', N'Tiburon de los reportes', N'Excepcional. Con 140 cartillas has desbloqueado la insignia Tiburon de los reportes. Eres un depredador de las cartillas.', 140, N'140');

MERGE dbo.insignias AS target
USING @insignias AS source
ON target.codigo = source.codigo
WHEN MATCHED THEN
    UPDATE SET
        titulo = source.titulo,
        descripcion = source.descripcion,
        meta_cartillas = source.meta_cartillas,
        categoria = 'cartillas',
        icono = source.icono,
        activo = 1
WHEN NOT MATCHED THEN
    INSERT (codigo, titulo, descripcion, meta_cartillas, categoria, icono, activo)
    VALUES (source.codigo, source.titulo, source.descripcion, source.meta_cartillas, 'cartillas', source.icono, 1);

IF OBJECT_ID('dbo.permisos', 'U') IS NOT NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dbo.permisos WHERE codigo = 'insignias.ver')
    BEGIN
        INSERT INTO dbo.permisos (codigo, descripcion, modulo)
        VALUES ('insignias.ver', 'Ver insignias', 'insignias');
    END;

    IF OBJECT_ID('dbo.roles', 'U') IS NOT NULL AND OBJECT_ID('dbo.rol_permiso', 'U') IS NOT NULL
    BEGIN
        INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
        SELECT r.id, p.id
        FROM dbo.roles r
        CROSS JOIN dbo.permisos p
        WHERE p.codigo = 'insignias.ver'
          AND NOT EXISTS (
              SELECT 1
              FROM dbo.rol_permiso rp
              WHERE rp.rol_id = r.id
                AND rp.permiso_id = p.id
          );

        IF EXISTS (SELECT 1 FROM dbo.permisos WHERE codigo = 'cartillas.generar')
        BEGIN
            INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
            SELECT DISTINCT rp_ver.rol_id, p_generar.id
            FROM dbo.rol_permiso rp_ver
            INNER JOIN dbo.permisos p_ver ON p_ver.id = rp_ver.permiso_id
            CROSS JOIN dbo.permisos p_generar
            WHERE p_ver.codigo = 'cartillas.ver'
              AND p_generar.codigo = 'cartillas.generar'
              AND NOT EXISTS (
                  SELECT 1
                  FROM dbo.rol_permiso rp
                  WHERE rp.rol_id = rp_ver.rol_id
                    AND rp.permiso_id = p_generar.id
              );
        END;
    END;
END;

COMMIT TRANSACTION;
GO
