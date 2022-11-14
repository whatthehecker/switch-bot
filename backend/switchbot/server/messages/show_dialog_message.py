from dataclasses import dataclass

from dataclasses_json import dataclass_json

from switchbot.program.dialog import Dialog


@dataclass_json
@dataclass
class ShowDialogMessage:
    dialog: Dialog
