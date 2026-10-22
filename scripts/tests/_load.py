"""Load a repo script as a module by path (scripts/ is not a package, and `mailbox` is also a stdlib name)."""

import importlib.util
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]


def load(name: str, relative_path: str):
    if name in sys.modules:
        return sys.modules[name]
    spec = importlib.util.spec_from_file_location(name, REPO / relative_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module
