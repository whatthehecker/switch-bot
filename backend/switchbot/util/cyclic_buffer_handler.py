import collections
import logging
from logging import LogRecord
from typing import Union, Iterable


class CyclicBufferHandler(logging.Handler):
    """
    A handler that keeps the most recent log lines written in a buffer.
    """

    def __init__(self, level: Union[int, str], buffer_size: int = 10):
        super(CyclicBufferHandler, self).__init__(level)
        self._buffer = collections.deque(maxlen=buffer_size)

    def emit(self, record: LogRecord) -> None:
        self._buffer.append(self.format(record))

    def get_buffered_records(self) -> Iterable[str]:
        return self._buffer
