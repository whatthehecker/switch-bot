from dataclasses import dataclass
from typing import Union, Optional

import numpy as np
from cv2 import VideoCapture, error
from cv2_enumerate_cameras import enumerate_cameras
# This doesn't get resolved for some reason, but it does exist:
# noinspection PyUnresolvedReferences
from cv2.videoio_registry import getBackendName
from dataclasses_json import dataclass_json


# dataclass has to be below dataclass_json or else everything breaks.
@dataclass_json
@dataclass
class CameraDescriptor:
    name: str
    identifier: Union[str, int]


class VideoConnector:
    """
    Wrapper around OpenCV's functionality for handling
    camera streams.
    """

    def __init__(self):
        self.active_camera_descriptor: Optional[CameraDescriptor] = None
        self.capture: Optional[VideoCapture] = None

    def connect(self, descriptor: CameraDescriptor) -> None:
        if self.is_connected():
            self.disconnect()

        self.active_camera_descriptor = descriptor
        self.capture = VideoCapture(descriptor.identifier)
        # TODO: raise error or return false if opening the camera fails.

    def is_connected(self) -> bool:
        return self.capture is not None

    def disconnect(self) -> None:
        self.active_camera_descriptor = None
        if self.capture is not None:
            self.capture.release()
        self.capture = None

    def read_frame(self) -> Optional[np.ndarray]:
        """
        Wrapper around frame grabbing functionality from OpenCV.
        Waits until a frame is ready and grabs it. If the frame could not be grabbed, None is returned.
        :return: The frame as a np.ndarray containing the image pixels or None if grabbing the frame failed.
        """
        if self.capture is None:
            return None
        try:
            ret, frame = self.capture.read()
            return frame if ret else None
        except error:
            # Rarely throws for some unknown reason, ignore it for now.
            return None

    # noinspection PyMethodMayBeStatic
    def list_cameras(self) -> list[CameraDescriptor]:
        """
        Returns a list of descriptors of the available cameras on the system.

        :return: A list of camera descriptors
        """
        return [CameraDescriptor(
            name=f'{camera.name} (Index {camera.index})',
            identifier=camera.index,
        ) for camera in enumerate_cameras()]
