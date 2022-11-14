A = b'A'
B = b'B'
X = b'X'
Y = b'Y'
HOME = b'H'
MINUS = b'M'
PLUS = b'P'
CAPTURE = b'C'
L = b'L'
R = b'R'
ZL = b'ZL'
ZR = b'ZR'
DPAD_LEFT = b'DL'
DPAD_RIGHT = b'DR'
DPAD_UP = b'DU'
DPAD_DOWN = b'DD'
LEFT_JOYSTICK_PREFIX = b'SL'
RIGHT_JOYSTICK_PREFIX = b'SR'

all_commands = [
    A, B, X, Y, HOME, MINUS, PLUS, CAPTURE, L, R, ZL, ZR, DPAD_LEFT, DPAD_RIGHT, DPAD_UP, DPAD_DOWN,
]
all_prefixes = [
    LEFT_JOYSTICK_PREFIX, RIGHT_JOYSTICK_PREFIX
]

RESPONSE_OK = b'.'
RESPONSE_ERROR = b'-'