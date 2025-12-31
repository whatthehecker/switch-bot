import logging
from math import sin, cos
from typing import Optional, List

import serial
from serial import Serial
from serial.tools.list_ports import comports
from serial.tools.list_ports_common import ListPortInfo

logger = logging.getLogger('SerialConnector')


class SerialConnector:
    """
    Handles writing Switch-specific commands over a serial connection.
    """

    def __init__(self):
        self.port_identifier: Optional[str] = None
        self.serial: Optional[Serial] = None

    def connect(self, port_identifier: str) -> None:
        self.serial = Serial(
            port=port_identifier,
            baudrate=115200,
            bytesize=serial.EIGHTBITS,
            parity=serial.PARITY_NONE,
            stopbits=serial.STOPBITS_ONE,
            timeout=1
        )
        self.port_identifier = port_identifier
        logger.info(f'Connected to port "{self.port_identifier}".')

    def is_connected(self) -> None:
        return self.serial is not None

    def disconnect(self) -> None:
        logger.info(f'Disconnecting from port {self.port_identifier}')

        if self.serial is not None and not self.serial.closed:
            self.serial.close()
        self.port_identifier = None
        self.serial = None

    def reconnect(self) -> None:
        logger.info(f'Reconnecting to port "{self.port_identifier}"')

        original_port_identifier = self.port_identifier
        self.disconnect()
        self.connect(original_port_identifier)

    def tap_a(self) -> None:
        self._write_tap_command('A')

    def tap_b(self) -> None:
        self._write_tap_command('B')

    def tap_x(self) -> None:
        self._write_tap_command('X')

    def tap_y(self) -> None:
        self._write_tap_command('Y')

    def tap_home(self) -> None:
        self._write_tap_command('H')

    def tap_minus(self) -> None:
        self._write_tap_command('M')

    def tap_plus(self) -> None:
        self._write_tap_command('P')

    def tap_capture(self) -> None:
        self._write_tap_command('C')

    def tap_l(self) -> None:
        self._write_tap_command('L')

    def tap_r(self) -> None:
        self._write_tap_command('R')

    def tap_zl(self) -> None:
        self._write_tap_command('ZL')

    def tap_zr(self) -> None:
        self._write_tap_command('ZR')

    def tap_left(self) -> None:
        self._write_tap_command('DL')

    def tap_right(self) -> None:
        self._write_tap_command('DR')

    def tap_up(self) -> None:
        self._write_tap_command('DU')

    def tap_down(self) -> None:
        self._write_tap_command('DD')

    def test_connection(self) -> str:
        self.write_command('V')
        return self.serial.readline().decode('ascii', errors='strict')

    def _write_tap_command(self, button_name: str) -> None:
        self.write_command(f'T{button_name}')

    def set_left_joystick(self, angle: float, radius: float) -> None:
        """
        Sets the position of the left joystick using polar coordinates.

        :param angle: The angle in radians. Zero degrees are equal to pointing to the right.
        :param radius: The radius of the circle, or how far the joystick is pressed in the given direction.
        """
        x, y, = self._polar_to_cartesian_joystick(angle, radius)
        self.write_command(f'SL{x:0.2f},{y:0.2f}')

    def set_right_joystick(self, angle: float, radius: float) -> None:
        """
        Sets the position of the right joystick using polar coordinates.

        :param angle: The angle in radians. Zero degrees are equal to pointing to the right.
        :param radius: The radius of the circle, or how far the joystick is pressed in the given direction.
        """

        x, y, = self._polar_to_cartesian_joystick(angle, radius)
        self.write_command(f'SR{x:0.2f},{y:0.2f}')

    @staticmethod
    def _polar_to_cartesian_joystick(angle: float, radius: float) -> tuple[int, int]:
        """
        Converts from polar coordinates to the joystick-specific cartesian coordinate system where
        (128, 128) is the neutral center position, (0, 128) is left, (255, 128) is right and so on.
        :param angle: The angle in radians.
        :param radius: The relative radius, meaning that 0 is no movement in the direction angle is pointing
        in and 1.0 means maximum movement in that direction.
        :return: A pair of (x, y) coordinates describing the same movement.
        """
        assert (0 <= radius <= 1.0)

        x = int(128 + cos(angle) * radius * 128)
        # Inverted Y axis: 1 is down and 1 is up.
        y = int(128 - sin(angle) * radius * 128)
        # Hack: 128 is neutral and 0 is the minimum, but 256 is not the maximum (255 is) so clamp values >= 256.
        return min(x, 255), min(y, 255)

    def write_command(self, command: str) -> None:
        if not self.is_connected():
            raise Exception('Serial connection was not opened yet')

        try:
            command_bytes = command.encode('ascii', errors='strict')
        except UnicodeEncodeError as err:
            logger.error(f'Failed to write command "{command}" to serial: {err}')
            return

        logger.debug(f'Writing bytes "{command_bytes}" to port "{self.port_identifier}"')
        self.serial.write(command_bytes)
        self.serial.write(b'\n')
        # Uncomment when debugging to get diagnostics data from the Pro Micro. This does slow down command sending considerably, so the joysticks may not work correctly with this.
        #response = self.serial.readline()
        #logger.debug(f'Response was: {response}')

    @staticmethod
    def list_serial_ports() -> List[str]:
        """
        Lists all available serial ports which can be used to connect to the controller's Arduino.
        :return: A list of the names of all available serial ports.
        """
        port_infos: list[ListPortInfo] = comports()
        return [port_info.device for port_info in port_infos]
