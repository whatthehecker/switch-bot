from dataclasses import dataclass
from typing import Dict

from dataclasses_json import dataclass_json


@dataclass_json
@dataclass(kw_only=True)
class StartProgramMessage:
    program_name: str
    option_values: Dict[str, object]
