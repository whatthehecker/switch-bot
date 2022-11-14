from dataclasses import dataclass
from typing import Optional

from dataclasses_json import dataclass_json

"""
A generic message for marking an action as successful or not, 
optionally with an error message if not successful.
"""


@dataclass_json
@dataclass(kw_only=True)
class ResultMessage:
    success: bool
    error_message: Optional[str] = None
