import platform
from pathlib import Path

sys = platform.system()

PATH = Path("/Users/deven367") if sys == "Darwin" else Path("/home/demistry")
