from typing import Dict

from ..bot.command_bytes import *

button_code_mappings: Dict[str, bytes] = {
    'A': A,
    'B': B,
    'X': X,
    'Y': Y,
    'Home': HOME,
    'Minus': MINUS,
    'Plus': PLUS,
    'Capture': CAPTURE,
    'L': L,
    'R': R,
    'ZL': ZL,
    'ZR': ZR,
    'Left': DPAD_LEFT,
    'Right': DPAD_RIGHT,
    'Up': DPAD_UP,
    'Down': DPAD_DOWN,
}
