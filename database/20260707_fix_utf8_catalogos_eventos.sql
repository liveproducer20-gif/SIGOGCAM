-- Limpieza de textos mojibake frecuentes en catalogos de eventos.
-- Ejecutar una sola vez si la tabla ya contiene valores con mojibake.

UPDATE catalogo_detalles
SET nombre = N'Reunión'
WHERE nombre IN (
    N'Reuni' + NCHAR(195) + NCHAR(179) + N'n',
    N'Reuni' + NCHAR(65533) + N'n',
    N'Reunion'
)
  AND (
    codigo LIKE N'%REUNION%'
    OR nombre LIKE N'%Reuni%'
  );

UPDATE catalogo_detalles
SET nombre = N'Capacitación'
WHERE nombre IN (
    N'Capacitaci' + NCHAR(195) + NCHAR(179) + N'n',
    N'Capacitaci' + NCHAR(65533) + N'n',
    N'Capacitacion'
)
  AND (
    codigo LIKE N'%CAPACIT%'
    OR nombre LIKE N'%Capacit%'
  );

UPDATE catalogo_detalles
SET nombre = N'Operativo'
WHERE nombre IN (N'Operativo', N'OPERATIVO')
  AND (
    codigo LIKE N'%OPERATIVO%'
    OR nombre LIKE N'%Operativo%'
  );
