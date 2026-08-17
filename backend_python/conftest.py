"""Bootstrap para pytest: asegura que el paquete ``app`` sea importable.

Permite ejecutar ``pytest`` desde cualquier directorio, no solo desde
``backend_python/``.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
