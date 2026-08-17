"""Saneamiento de entrada (defensa en profundidad).

La capa de acceso a datos ya usa consultas parametrizadas (placeholders ``?``)
en toda la API, por lo que la inyección SQL estructural no es posible. Estas
utilidades cubren los riesgos residuales de la entrada de usuario:

- Caracteres de control y bytes nulos incrustados en textos.
- Comodines del operador ``LIKE`` (``%``, ``_``, ``[``, ``\\``) inyectados en
  búsquedas, que ampliarían el filtro y podrían exponer datos ajenos (fuga de
  datos por filtro).

Uso:

    from app.core.sanitize import clean_text, escape_like

    nombre = clean_text(payload.get("nombre"), max_len=200)
    termino = f"%{escape_like(busqueda.lower())}%"
    cursor.execute("... WHERE nombre LIKE ? ESCAPE '\\\\' ...", termino)
"""

import re

# Caracteres de control ASCII que nunca son legítimos en datos de negocio.
# Se conservan \t, \n y \r (pueden aparecer en textos multilínea).
_CONTROL_CHARS = re.compile(r"[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")

# Comodines del operador LIKE de SQL Server.
_LIKE_WILDCARDS = re.compile(r"([\\%_\[\]])")


def strip_control_chars(value: str) -> str:
    """Elimina caracteres de control ASCII (incluidos bytes nulos) de un texto.

    Conserva ``\t``, ``\n`` y ``\r`` (válidos en textos multilínea). No recorta
    espacios: útil para saneamiento global de cuerpos JSON sin alterar valores
    legítimos (p. ej. contraseñas).
    """
    return _CONTROL_CHARS.sub("", value)


def clean_text(value, max_len: int | None = None) -> str | None:
    """Limpia un texto: elimina caracteres de control, recorta espacios y trunca.

    Devuelve ``None`` cuando la entrada es ``None`` y deja intactos los valores
    que no son texto (números, booleanos, fechas).
    """
    if value is None:
        return None
    if not isinstance(value, str):
        return value
    cleaned = strip_control_chars(value).strip()
    if max_len is not None and len(cleaned) > max_len:
        cleaned = cleaned[:max_len]
    return cleaned


def escape_like(term) -> str | None:
    """Escapa los comodines ``LIKE`` (``% _ [ \\``) de un término de búsqueda.

    Debe combinarse con la cláusula ``ESCAPE '\\'`` en la consulta. Sin esto, un
    usuario podría enviar ``%`` o ``_`` y ampliar el alcance del filtro.
    """
    if term is None:
        return None
    return _LIKE_WILDCARDS.sub(r"\\\1", str(term))
