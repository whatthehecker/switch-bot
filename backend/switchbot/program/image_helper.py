import cv2
import numpy as np


class Rect:
    def __init__(self, x: int, y: int, width: int, height: int):
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    def area(self):
        return self.width * self.height


def count_colored_pixels(frame: np.ndarray, rect: Rect, lower_color: [float], upper_color: [float]):
    """
    Counts the number of pixels whose color lies between the given lower and upper colors.
    :param frame: The image to search in
    :param rect: A rectangle describing the region to search in
    :param lower_color: The lower color
    :param upper_color: The upper color
    :return: The number of pixels with a color between lower and upper
    """

    # Y value before X value
    box = frame[rect.y:rect.y + rect.height, rect.x:rect.x + rect.width]
    # OpenCV uses BGR instead of RGB, so index 2 is red
    mask = cv2.inRange(box, lower_color, upper_color)
    return cv2.countNonZero(mask)
