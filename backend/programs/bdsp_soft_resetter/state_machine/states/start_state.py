from typing import Optional, cast

from ..state_machine import State
from .launch_game_state import LaunchGameState


class InitializeState(State):
    async def execute(self) -> Optional[State]:
        self.context.encounters = 0
        self.context.animation_times = {}

        self.context.take_screenshots = self.context.program.option_values[
                                            self.context.program.save_screenshots_option.name] is True
        self.context.preset_name = cast(str, self.context.program.option_values[
            self.context.program.selected_preset_option.name])
        self.context.write_statistics = self.context.program.option_values[
                                            self.context.program.write_statistics_option.name] is True
        self.context.program.logger.info(f'Starting soft resetter with preset: {self.context.preset_name}')

        return LaunchGameState(self.context)
