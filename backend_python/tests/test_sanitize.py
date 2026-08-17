"""Pruebas de las utilidades de saneamiento (app/core/sanitize.py)."""

import pytest

from app.core.sanitize import clean_text, escape_like, strip_control_chars


# ---------------------------------------------------------------------------
# escape_like
# ---------------------------------------------------------------------------

class TestEscapeLike:
    def test_escapa_porcentaje(self):
        assert escape_like("100% real") == r"100\% real"

    def test_escapa_guion_bajo(self):
        assert escape_like("a_b") == r"a\_b"

    def test_escapa_corchetes(self):
        assert escape_like("[a]") == r"\[a\]"

    def test_escapa_backslash(self):
        assert escape_like(r"c:\x") == r"c:\\x"

    def test_escapa_combinacion(self):
        assert escape_like("100%_a[1]\\x") == r"100\%\_a\[1\]\\x"

    def test_cadena_vacia(self):
        assert escape_like("") == ""

    def test_none_devuelve_none(self):
        assert escape_like(None) is None

    def test_no_texto_se_convierte(self):
        assert escape_like(123) == "123"
        assert escape_like(1.5) == "1.5"

    def test_unicode_intacto(self):
        assert escape_like("José 100%") == "José 100\\%"

    @pytest.mark.parametrize(
        "raw,esperado",
        [
            ("%", r"\%"),
            ("_", r"\_"),
            ("[", r"\["),
            ("]", r"\]"),
            ("\\", r"\\"),
            ("%%%", r"\%\%\%"),
        ],
    )
    def test_cada_comodin(self, raw, esperado):
        assert escape_like(raw) == esperado


# ---------------------------------------------------------------------------
# strip_control_chars
# ---------------------------------------------------------------------------

class TestStripControlChars:
    def test_elimina_bytes_nulos(self):
        assert strip_control_chars("a\x00b") == "ab"

    def test_elimina_controles_ascii(self):
        assert strip_control_chars("a\x01\x1f\x7fb") == "ab"

    def test_conserva_tab_nueva_linea_y_retorno(self):
        assert strip_control_chars("l1\nl2\tl3\rl4") == "l1\nl2\tl3\rl4"

    def test_no_recorta_espacios(self):
        assert strip_control_chars("  hola  ") == "  hola  "

    def test_sin_cambios_en_texto_limpio(self):
        assert strip_control_chars("texto normal 123") == "texto normal 123"


# ---------------------------------------------------------------------------
# clean_text
# ---------------------------------------------------------------------------

class TestCleanText:
    def test_recorta_espacios(self):
        assert clean_text("  hola  ") == "hola"

    def test_elimina_controles_y_recorta(self):
        assert clean_text(" \x00 hola \x1f ") == "hola"

    def test_conserva_multilinea(self):
        assert clean_text("l1\nl2") == "l1\nl2"

    def test_max_len_trunca(self):
        assert clean_text("abcdefgh", max_len=5) == "abcde"

    def test_max_len_no_trunca_lo_que_cabe(self):
        assert clean_text("abc", max_len=5) == "abc"

    def test_none_devuelve_none(self):
        assert clean_text(None) is None

    def test_no_texto_pasa_intacto(self):
        assert clean_text(5) == 5
        assert clean_text(True) is True
        assert clean_text(3.14) == 3.14
