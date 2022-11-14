import logging
from pathlib import Path
from time import strftime
from typing import Optional, Dict, List

import cv2
import numpy as np

from switchbot.bot.switch_bot import SwitchBot
from switchbot.program.option import SelectionOption, BoolOption, StringOption, Option
from switchbot.program.program import Program
from .animation_type import AnimationType
from .battle_entry_presets import PRESET_BATTLE_ENTRIES
from .state_machine.state_machine import StateMachine
from .state_machine.states.start_state import InitializeState


class BdspSoftResetter(Program):

    def __init__(self, logger: logging.Logger):
        super().__init__(logger)

        self.selected_preset_option: SelectionOption = SelectionOption(
            name='Pokemon',
            description='The Pokemon being soft-reset',
            choices=frozenset(list(PRESET_BATTLE_ENTRIES.keys())),
            default_value_index=0
        )
        self.save_screenshots_option = BoolOption(
            name='Save screenshots',
            description='Whether to save screenshots of each encounter to disk',
            default_value=False,
        )
        self.screenshot_dir_option = StringOption(
            name='Screenshot directory',
            description='The directory to save screenshots to. If screenshots are '
                        'enabled and this is left empty, a new directory with the current '
                        'date and time as the name is created in the current working directory.',
            default_value='.'
        )
        self.write_statistics_option = BoolOption(
            name='Write statistics',
            description='Whether to write statistics about each encounter to disk.',
            default_value=False
        )
        self.option_values: Dict[str, object] = {
            self.selected_preset_option.name: list(PRESET_BATTLE_ENTRIES.keys())[0],
            self.save_screenshots_option.name: False,
            self.screenshot_dir_option.name: self.screenshot_dir_option.default_value,
            self.write_statistics_option.name: True,
        }

    @property
    def name(self) -> str:
        return 'BDSP Soft Resetter'

    @property
    def options(self) -> List[Option]:
        return [
            self.selected_preset_option,
            self.save_screenshots_option,
            self.screenshot_dir_option,
            self.write_statistics_option
        ]

    @property
    def description(self):
        return 'Soft resets in Pokémon Brilliant Diamond and Shining Pearl for stationary Pokémon.'

    def save_debug_screen(self, frame: np.ndarray) -> None:
        cv2.imwrite('debug.jpg', frame, params=[cv2.IMWRITE_JPEG_QUALITY, 50])
        print('Wrote debug image to disk.')

    async def run(self, switch_bot: SwitchBot) -> None:
        context = BdspContext(
            program=self,
            bot=switch_bot
        )

        state_machine = StateMachine(initial_state=InitializeState(context))
        await state_machine.run()

    def create_screenshot_directory(self) -> Path:
        path = Path(f'./' + strftime('%Y-%m-%d_%H-%M-%S'))
        path.mkdir(exist_ok=True)
        self.logger.info(f'Created screenshot directory at: {str(path)}')
        return path

    @staticmethod
    def save_screenshot(frame: np.ndarray, directory: Path, file_name: str) -> None:
        file_path = directory / f'{file_name}.jpg'
        cv2.imwrite(str(file_path), frame, params=[cv2.IMWRITE_JPEG_QUALITY, 50])

    def write_encounter(self,
                        csv_writer,
                        csv_file,
                        encounter: int,
                        encounter_time: float,
                        battle_menu_time: float,
                        encounter_type: Optional[AnimationType],
                        shiny: bool):
        csv_writer.writerow([
            encounter,
            encounter_time,
            battle_menu_time,
            encounter_type,
            shiny
        ])
        csv_file.flush()


class BdspContext:
    def __init__(self, program: BdspSoftResetter, bot: SwitchBot):
        self.program: BdspSoftResetter = program
        self.bot = bot
        self.encounters: int = 0
        self.animation_times: Dict[AnimationType, float] = {}
        self.take_screenshots: bool = False
        self.preset_name: str = 'Empty'
        self.write_statistics: bool = False
