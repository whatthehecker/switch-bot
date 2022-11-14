import socketio

from .serial_connector import SerialConnector
from .ui_display import UiDisplay
from .video_connector import VideoConnector


class SwitchBot:
    """
    Base functionality for interacting with the controller and receiving input from the
    camera.
    """

    def __init__(self, sio: socketio.Server):
        self.video: VideoConnector = VideoConnector()
        self.serial: SerialConnector = SerialConnector()
        self.display: UiDisplay = UiDisplay(sio)
