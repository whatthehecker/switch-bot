from dataclasses import dataclass
from typing import List, Optional, Dict

from dataclasses_json import dataclass_json

from switchbot.bot.video_connector import CameraDescriptor
from switchbot.program.dialog import Dialog
from switchbot.program.program import ProgramMetadata


@dataclass_json
@dataclass
class WelcomeMessage:
    available_programs: List[ProgramMetadata]
    current_program_name: Optional[str]
    current_program_options: Optional[Dict[str, object]]
    recent_program_logs: List[str]
    current_video: Optional[CameraDescriptor]
    available_video: List[CameraDescriptor]
    current_serial: Optional[str]
    available_serial: List[str]
    current_dialog: Optional[Dialog]
