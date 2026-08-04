USE BITSAC;
GO

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- ============================================================
-- 1. AGREGAR CAMPOS A TABLA SECTORES
-- ============================================================
IF COL_LENGTH('dbo.sectores', 'cantidad_agentes_requeridos') IS NULL
    ALTER TABLE dbo.sectores ADD cantidad_agentes_requeridos INT NOT NULL CONSTRAINT DF_sectores_cantidad DEFAULT (1);

IF COL_LENGTH('dbo.sectores', 'orden_distribucion') IS NULL
    ALTER TABLE dbo.sectores ADD orden_distribucion INT NOT NULL CONSTRAINT DF_sectores_orden DEFAULT (0);

-- ============================================================
-- 2. TABLA DE ASIGNACIONES DE RUTA (asignaciones_ruta)
-- ============================================================
IF OBJECT_ID(N'dbo.asignaciones_ruta', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.asignaciones_ruta (
        id                  BIGINT IDENTITY(1,1) PRIMARY KEY,
        agente_id           INT NOT NULL,
        distrito_id         INT NOT NULL,
        ruta_id             INT NOT NULL,
        sector_id           INT NOT NULL,
        fecha_asignacion    DATE NOT NULL,
        turno               NVARCHAR(80) NOT NULL,
        hora_inicio         TIME(0) NOT NULL,
        hora_fin            TIME(0) NOT NULL,
        estado              NVARCHAR(30) NOT NULL CONSTRAINT DF_asig_ruta_estado DEFAULT (N'PENDIENTE'),
        tipo_asignacion     NVARCHAR(40) NOT NULL CONSTRAINT DF_asig_ruta_tipo DEFAULT (N'MANUAL'),
        sorteo_id           NVARCHAR(80) NULL,
        asignado_por        INT NOT NULL,
        observacion         NVARCHAR(500) NULL,
        fecha_creacion      DATETIME2 NOT NULL CONSTRAINT DF_asig_ruta_fecha DEFAULT (SYSDATETIME()),
        fecha_actualizacion DATETIME2 NULL,
        deleted_at          DATETIME2 NULL,
        CONSTRAINT FK_asig_ruta_agente FOREIGN KEY (agente_id) REFERENCES dbo.personal(id),
        CONSTRAINT FK_asig_ruta_distrito FOREIGN KEY (distrito_id) REFERENCES dbo.catalogo_detalles(id),
        CONSTRAINT FK_asig_ruta_ruta FOREIGN KEY (ruta_id) REFERENCES dbo.rutas(id),
        CONSTRAINT FK_asig_ruta_sector FOREIGN KEY (sector_id) REFERENCES dbo.sectores(id),
        CONSTRAINT CK_asig_ruta_estado CHECK (estado IN (N'PENDIENTE', N'ACTIVA', N'COMPLETADA', N'CANCELADA', N'INACTIVA'))
    );
END;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asig_ruta_conflicto' AND object_id = OBJECT_ID('dbo.asignaciones_ruta'))
    CREATE INDEX IX_asig_ruta_conflicto ON dbo.asignaciones_ruta (agente_id, fecha_asignacion, hora_inicio, hora_fin, estado)
    INCLUDE (ruta_id, sector_id, turno);

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_asig_ruta_ruta_fecha' AND object_id = OBJECT_ID('dbo.asignaciones_ruta'))
    CREATE INDEX IX_asig_ruta_ruta_fecha ON dbo.asignaciones_ruta (ruta_id, fecha_asignacion, estado)
    INCLUDE (sector_id, agente_id);

-- ============================================================
-- 3. TABLA DE HISTORIAL DE SORTEOS (sorteos_historial)
-- ============================================================
IF OBJECT_ID(N'dbo.sorteos_historial', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.sorteos_historial (
        id                          BIGINT IDENTITY(1,1) PRIMARY KEY,
        sorteo_id                   NVARCHAR(80) NOT NULL,
        usuario_id                  INT NOT NULL,
        distrito_id                 INT NOT NULL,
        ruta_id                     INT NOT NULL,
        fecha_servicio              DATE NOT NULL,
        turno                       NVARCHAR(80) NOT NULL,
        hora_inicio                 TIME(0) NOT NULL,
        hora_fin                    TIME(0) NOT NULL,
        sectores_incluidos          NVARCHAR(MAX) NOT NULL,
        agentes_requeridos          INT NOT NULL,
        agentes_disponibles         INT NOT NULL,
        agentes_seleccionados       INT NOT NULL,
        agentes_cambiados           INT NOT NULL DEFAULT 0,
        agentes_confirmados         INT NOT NULL DEFAULT 0,
        veces_sorteo                INT NOT NULL DEFAULT 1,
        resultado                   NVARCHAR(30) NOT NULL DEFAULT N'CONFIRMADO',
        motivo_error                NVARCHAR(500) NULL,
        ip                          NVARCHAR(80) NULL,
        fecha_ejecucion             DATETIME2 NOT NULL CONSTRAINT DF_sorteo_fecha DEFAULT (SYSDATETIME()),
        CONSTRAINT CK_sorteo_resultado CHECK (resultado IN (N'CONFIRMADO', N'CANCELADO', N'ERROR', N'PARCIAL'))
    );
END;
GO

-- ============================================================
-- 4. PERMISOS PARA TABLERO DE DISTRIBUCION
-- ============================================================
DECLARE @permisos TABLE (codigo NVARCHAR(120), descripcion NVARCHAR(255));
INSERT INTO @permisos VALUES
(N'tablero_distribucion.ver',        N'Ver tablero de distribucion'),
(N'tablero_distribucion.asignar',    N'Ejecutar asignacion aleatoria'),
(N'tablero_distribucion.configurar', N'Configurar requerimiento de personal'),
(N'tablero_distribucion.limpiar',    N'Limpiar asignaciones de ruta');

MERGE dbo.permisos AS target
USING @permisos AS source ON target.codigo = source.codigo
WHEN MATCHED THEN UPDATE SET descripcion = source.descripcion, modulo = N'distribucion', activo = 1
WHEN NOT MATCHED THEN INSERT (codigo, descripcion, modulo, activo) VALUES (source.codigo, source.descripcion, N'distribucion', 1);

-- Asignar permisos por rol
INSERT INTO dbo.rol_permiso (rol_id, permiso_id)
SELECT r.id, p.id
FROM dbo.roles r
CROSS JOIN dbo.permisos p
WHERE p.codigo LIKE N'tablero_distribucion.%'
  AND (
      r.nombre IN (N'Administrador', N'Operaciones')
      OR (r.nombre = N'Supervisor' AND p.codigo IN (N'tablero_distribucion.ver', N'tablero_distribucion.asignar'))
      OR (r.nombre IN (N'Auditor', N'Auditoria') AND p.codigo = N'tablero_distribucion.ver')
  )
  AND NOT EXISTS (SELECT 1 FROM dbo.rol_permiso rp WHERE rp.rol_id = r.id AND rp.permiso_id = p.id);

COMMIT TRANSACTION;
GO
