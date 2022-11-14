from dataclasses import dataclass
from typing import List

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class Dialog:
    title: str
    content: str
    buttons: List[str]
    is_modal: bool = True
