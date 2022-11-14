import asyncio
import logging
from logging import LogRecord
from typing import Union

import socketio

from ..server.message_identifiers import MessageIdentifiers


class EmittingSocketHandler(logging.Handler):
    def __init__(self, socket: socketio.Server, level: Union[int, str], event_name: str = MessageIdentifiers.LOG_LINE_EMITTED):
        super(EmittingSocketHandler, self).__init__(level)
        self.socket = socket
        self.event_name = event_name

    def emit(self, record: LogRecord) -> None:
        loop = asyncio.get_event_loop()
        emitter_coroutine = self.socket.emit(self.event_name, self.format(record))
        # This should run the coroutine later on the existing loop.
        asyncio.ensure_future(emitter_coroutine, loop=loop)
