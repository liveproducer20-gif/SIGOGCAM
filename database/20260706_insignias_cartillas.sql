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
('cartillas_020', N'Cronista Operativo', N'Vas por muy buen camino. Has generado 20 cartillas y obtuviste la insignia Cronista Operativo.', 20, N'20'),
('cartillas_030', N'Agente Comprometido', N'Tu constancia comienza a marcar la diferencia. Has completado 30 cartillas y desbloqueaste la insignia Agente Comprometido.', 30, N'30'),
('cartillas_045', N'Reportero Activo', N'Tu productividad sigue creciendo. Has elaborado 45 cartillas y obtuviste la insignia Reportero Activo.', 45, N'45'),
('cartillas_060', N'Guardia de Novedades', N'Excelente desempeno. Alcanzaste 60 cartillas y desbloqueaste la insignia Guardia de Novedades.', 60, N'60'),
('cartillas_075', N'Operador Estrategico', N'Tu experiencia sigue aumentando. Has registrado 75 cartillas y obtuviste la insignia Operador Estrategico.', 75, N'75'),
('cartillas_095', N'Coordinador de Cartillas', N'Ya eres un referente en la generacion de reportes. Has completado 95 cartillas y desbloqueaste la insignia Coordinador de Cartillas.', 95, N'95'),
('cartillas_115', N'Supervisor de Incidencias', N'Tu dedicacion fortalece las operaciones. Has alcanzado 115 cartillas y obtuviste la insignia Supervisor de Incidencias.', 115, N'115'),
('cartillas_135', N'Agente Destacado', N'Gran logro. Llegaste a 135 cartillas y desbloqueaste la insignia Agente Destacado.', 135, N'135'),
('cartillas_155', N'Especialista Operativo', N'Tu compromiso operativo sigue creciendo. Has alcanzado 155 cartillas y desbloqueaste la insignia Especialista Operativo.', 155, N'155'),
('cartillas_175', N'Experto en Reportes', N'Tu dominio en la generacion de cartillas es evidente. Has completado 175 cartillas y obtuviste la insignia Experto en Reportes.', 175, N'175'),
('cartillas_195', N'Centinela Institucional', N'Has demostrado constancia y responsabilidad institucional. Alcanzaste 195 cartillas y desbloqueaste la insignia Centinela Institucional.', 195, N'195'),
('cartillas_215', N'Maestro de Cartillas', N'Tu experiencia te convierte en un referente. Has generado 215 cartillas y obtuviste la insignia Maestro de Cartillas.', 215, N'215'),
('cartillas_235', N'Leyenda Operativa', N'Felicidades. Has completado 235 cartillas y desbloqueaste la insignia Leyenda Operativa.', 235, N'235'),
('cartillas_255', N'Super Agente', N'Felicidades. Has alcanzado 255 cartillas y desbloqueaste la insignia Super Agente. Eres un verdadero ejemplo.', 255, N'255'),
('cartillas_275', N'El mejor de los Papamike', N'Impresionante. Con 275 cartillas te has ganado la insignia El mejor de los Papamike. Nadie te supera.', 275, N'275'),
('cartillas_295', N'El loco de las Cartillas', N'Increible. Has generado 295 cartillas y desbloqueaste la insignia El loco de las Cartillas. Eres una maquina.', 295, N'295'),
('cartillas_315', N'Tiburon de los reportes', N'Excepcional. Con 315 cartillas has desbloqueado la insignia Tiburon de los reportes. Eres un depredador de las cartillas.', 315, N'315'),
('cartillas_335', N'Sniper de novedades', N'Precision absoluta. Con 335 cartillas desbloqueaste la insignia Sniper de novedades. No se te escapa nada.', 335, N'335'),
('cartillas_355', N'Tirador de incidencias', N'Apuntas y aciertas. Has alcanzado 355 cartillas y obtuviste la insignia Tirador de incidencias.', 355, N'355'),
('cartillas_375', N'Perito de cartillas', N'Tu pericia es inigualable. Con 375 cartillas desbloqueaste la insignia Perito de cartillas.', 375, N'375'),
('cartillas_395', N'Jefe de Patrulla', N'Lideras con el ejemplo. Alcanzaste 395 cartillas y obtuviste la insignia Jefe de Patrulla.', 395, N'395'),
('cartillas_415', N'Lluvia de novedades', N'Generas reportes como lluvia. Con 415 cartillas desbloqueaste la insignia Lluvia de novedades.', 415, N'415'),
('cartillas_435', N'Cartillas por doquier', N'Las cartillas te persiguen. Alcanzaste 435 cartillas y obtuviste la insignia Cartillas por doquier.', 435, N'435'),
('cartillas_455', N'Superheroe Operativo', N'Eres un heroe de las operaciones. Con 455 cartillas desbloqueaste la insignia Superheroe Operativo.', 455, N'455'),
('cartillas_475', N'Merodeador de incidencias', N'Siempre en el lugar correcto. Alcanzaste 475 cartillas y obtuviste la insignia Merodeador de incidencias.', 475, N'475'),
('cartillas_500', N'Jefe de asuntos operativos', N'La cima del rendimiento. Con 500 cartillas has desbloqueado la insignia Jefe de asuntos operativos. Eres la maxima autoridad.', 500, N'500'),
('cartillas_530', N'Comisionado de Élite', N'Excelencia comprobada. Con 530 cartillas has desbloqueado la insignia Comisionado de Élite. Tu dedicacion es ejemplar.', 530, N'530'),
('cartillas_565', N'Guardián Supremo', N'Constancia inquebrantable. Al alcanzar 565 cartillas has obtenido la insignia Guardián Supremo. Nadie iguala tu entrega.', 565, N'565'),
('cartillas_605', N'Maestro Consumado', N'Maestria absoluta. Con 605 cartillas desbloqueaste la insignia Maestro Consumado. Eres un verdadero experto.', 605, N'605'),
('cartillas_650', N'Leyenda Viviente', N'Tu nombre es leyenda. Al llegar a 650 cartillas has obtenido la insignia Leyenda Viviente. Tu legado perdura.', 650, N'650'),
('cartillas_700', N'Emblema de Honor', N'Honor y excelencia. Con 700 cartillas desbloqueaste la insignia Emblema de Honor. Representas lo mejor de la institucion.', 700, N'700'),
('cartillas_755', N'Custodio del Sistema', N'Guardian incansable. Al alcanzar 755 cartillas has obtenido la insignia Custodio del Sistema. El sistema te necesita.', 755, N'755'),
('cartillas_800', N'Pináculo del Mérito', N'La cima absoluta. Con 800 cartillas has desbloqueado la insignia Pináculo del Mérito. Eres una leyenda viva.', 800, N'800');

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
