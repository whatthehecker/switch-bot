import logging
from math import sin, cos
from typing import Optional, List

import serial
from serial import Serial
from serial.tools.list_ports import comports
from serial.tools.list_ports_common import ListPortInfo

from ..bot.command_bytes import *

logger = logging.getLogger('SerialConnector')


class SerialConnector:
    """
    Handles writing Switch-specific commands over a serial connection.
    """

    def __init__(self):
        self.port_identifier: Optional[str] = None
        self.serial: Optional[Serial] = None

    def connect(self, port_identifier: str) -> None:
        self.serial = Serial(port_identifier, bytesize=serial.EIGHTBITS, parity=serial.PARITY_NONE,
                             stopbits=serial.STOPBITS_ONE, timeout=1)
        self.port_identifier = port_identifier
        logger.info(f'Connected to port "{self.port_identifier}.')

    def is_connected(self) -> None:
        return self.serial is not None

    def disconnect(self) -> None:
        logger.info(f'Disconnecting from port {self.port_identifier}')

        if self.serial is not None and not self.serial.closed:
            self.serial.close()
        self.port_identifier = None
        self.serial = None

    def reconnect(self) -> None:
        logger.info(f'Reconnecting to port "{self.port_identifier}')

        original_port_identifier = self.port_identifier
        self.disconnect()
        self.connect(original_port_identifier)

    def press_a(self) -> None:
        self.write_command(A)

    def press_b(self) -> None:
        self.write_command(B)

    def press_x(self) -> None:
        self.write_command(X)

    def press_y(self) -> None:
        self.write_command(Y)

    def press_home(self) -> None:
        self.write_command(HOME)

    def press_minus(self) -> None:
        self.write_command(MINUS)

    def press_plus(self) -> None:
        self.write_command(PLUS)

    def press_capture(self) -> None:
        self.write_command(CAPTURE)

    def press_l(self) -> None:
        self.write_command(L)

    def press_r(self) -> None:
        self.write_command(R)

    def press_zl(self) -> None:
        self.write_command(ZL)

    def press_zr(self) -> None:
        self.write_command(ZR)

    def press_left(self) -> None:
        self.write_command(DPAD_LEFT)

    def press_right(self) -> None:
        self.write_command(DPAD_RIGHT)

    def press_up(self) -> None:
        self.write_command(DPAD_UP)

    def press_down(self) -> None:
        self.write_command(DPAD_DOWN)

    def _set_left_joystick_raw(self, x: int, y: int) -> None:
        assert (0 <= x <= 255)
        assert (0 <= y <= 255)

        self.write_command(LEFT_JOYSTICK_PREFIX + x.to_bytes(1) + y.to_bytes(1))

    def _set_right_joystick_raw(self, x: int, y: int) -> None:
        assert (0 <= x <= 255)
        assert (0 <= y <= 255)

        self.write_command(RIGHT_JOYSTICK_PREFIX + x.to_bytes(1) + y.to_bytes(1))

    def set_left_joystick(self, angle: float, radius: float) -> None:
        """
        Sets the position of the left joystick using polar coordinates.

        :param angle: The angle in radians. Zero degrees are equal to pointing to the right.
        :param radius: The radius of the circle, or how far the joystick is pressed in the given direction.
        """
        x, y, = self._polar_to_cartesian_joystick(angle, radius)
        self._set_left_joystick_raw(round(x), round(y))

    def set_right_joystick(self, angle: float, radius: float) -> None:
        """
        Sets the position of the right joystick using polar coordinates.

        :param angle: The angle in radians. Zero degrees are equal to pointing to the right.
        :param radius: The radius of the circle, or how far the joystick is pressed in the given direction.
        """

        x, y, = self._polar_to_cartesian_joystick(angle, radius)
        self._set_right_joystick_raw(round(x), round(y))

    def _polar_to_cartesian_joystick(self, angle: float, radius: float) -> (int, int):
        """
        Converts from polar coordinates to the joystick-specific cartesion coordinate system where
        (128, 128) is the neutral center position, (0, 128) is left, (255, 128) is right and so on.
        :param angle: The angle in radians.
        :param radius: The relative radius, meaning that 0 is no movement in the direction angle is pointing
        in and 1.0 means maximum movement in that direction.
        :return: A pair of (x, y) coordinates describing the same movement.
        """
        assert (0 <= radius <= 1.0)

        x = 128 + cos(angle) * radius * 128
        # Inverted Y axis: 1 is down and 1 is up.
        y = 128 - sin(angle) * radius * 128
        # Hack: 128 is neutral and 0 is the minimum, but 256 is not the maximum (255 is) so clamp values >= 256.
        return min(x, 255), min(y, 255)

    def write_command(self, button_bytes: bytes) -> None:
        if not self.is_connected():
            raise Exception('Serial connection was not opened yet')

        if button_bytes not in all_commands and not any(button_bytes.startswith(prefix) for prefix in all_prefixes):
            raise Exception(f'Unknown button bytes: {button_bytes}')

        logger.debug(f'Writing bytes "{button_bytes}" to port {self.port_identifier}')
        self.serial.write(button_bytes)
        # Terminate each command with a newline.
        self.serial.write(b'\n')
        response_byte = self.serial.read()
        if response_byte == RESPONSE_OK:
            logger.debug('Response was OK')
        elif response_byte == RESPONSE_ERROR:
            logger.debug('Response was ERROR')
        else:
            logger.debug(f'Unknown response! Was: {response_byte}')

    @staticmethod
    def list_serial_ports() -> List[str]:
        """
        Lists all available serial ports which can be used to connect to the controller's Arduino.
        :return: A list of the names of all available serial ports.
        """
        port_infos: [ListPortInfo] = comports()
        return [port_info.device for port_info in port_infos]
