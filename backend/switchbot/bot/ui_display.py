from random import Random
from typing import List

import socketio

from ..program.dialog import Dialog
from ..server.message_identifiers import MessageIdentifiers
from ..server.messages.show_dialog_message import ShowDialogMessage


class UiDisplay:
    _random: Random = Random()

    def __init__(self, sio: socketio.Server):
        self.sio: socketio.Server = sio

    async def show_dialog(self, title: str, content: str, buttons: List[str], sid=None) -> None:
        message: ShowDialogMessage = ShowDialogMessage(
            dialog=Dialog(
                title=title,
                content=content,
                buttons=buttons
            )
        )
        await self.sio.emit(MessageIdentifiers.SHOW_DIALOG_REQUEST, ShowDialogMessage.to_dict(message), to=sid)
