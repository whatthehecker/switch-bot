from dataclasses import dataclass
from typing import Optional, Dict

from dataclasses_json import dataclass_json

from switchbot.program.program import ProgramMetadata


@dataclass_json
@dataclass(kw_only=True)
class CurrentProgramMessage:
    metadata: Optional[ProgramMetadata]
    option_values: Optional[Dict[str, object]]
