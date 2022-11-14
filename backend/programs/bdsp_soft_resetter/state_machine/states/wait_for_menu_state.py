import asyncio
from time import time
from typing import Optional

import numpy as np

from ..state_machine import State
from .launch_game_state import LaunchGameState
from .update_times_state import UpdateTimesState
from switchbot.bot.switch_bot import SwitchBot
from switchbot.program.image_helper import Rect, count_colored_pixels

ENCOUNTER_RECT = Rect(
    x=170,
    y=880,
    width=1580,
    height=160
)
COLOR_WHITE_LOWER = np.array([245, 245, 245])
COLOR_WHITE_UPPER = np.array([255, 255, 255])

BATTLE_MENU_RECT = Rect(
    x=1693,
    y=637,
    width=60,
    height=60
)
COLOR_RED_LOWER = np.array([0, 0, 180])
COLOR_RED_UPPER = np.array([85, 85, 255])


async def wait_for_colored_region(switch_bot: SwitchBot, rect: Rect, lower_color: [float],
                                  upper_color: [float],
                                  minimum_count: int, max_wait_time: float) -> Optional[float]:
    start_time = time()
    pixel_count = 0
    while pixel_count < minimum_count:
        frame = switch_bot.video.read_frame()
        if frame is not None:
            pixel_count = count_colored_pixels(frame, rect, lower_color, upper_color)
        current_time = time()
        if current_time - start_time >= max_wait_time:
            return None
        # Small sleep for 1 frame to allow other processes to run.
        await asyncio.sleep(1.0 / 60.0)

    return time() - start_time


class MeasureTimeState(State):
    async def execute(self) -> Optional[State]:
        encounter_time = await wait_for_colored_region(
            self.context.bot,
            rect=ENCOUNTER_RECT,
            lower_color=COLOR_WHITE_LOWER,
            upper_color=COLOR_WHITE_UPPER,
            minimum_count=0.9 * ENCOUNTER_RECT.area(),
            max_wait_time=10.0
        )
        if encounter_time is None:
            self.context.program.logger.info('Timed out waiting for encounter text, skipping this encounter...')
            return LaunchGameState(self.context)

        self.context.program.logger.info(f'Found encounter text after {encounter_time:.02f} seconds.')
        battle_menu_time = await wait_for_colored_region(
            self.context.bot,
            rect=BATTLE_MENU_RECT,
            lower_color=COLOR_RED_LOWER,
            upper_color=COLOR_RED_UPPER,
            minimum_count=0.9 * BATTLE_MENU_RECT.area(),
            max_wait_time=100.0
        )
        if battle_menu_time is None:
            self.context.program.logger.info('Timed out finding battle menu, skipping encounter.')
            return LaunchGameState(self.context)

        self.context.program.logger.info(f'Found battle menu after another {battle_menu_time:.02f} seconds.')
        # todo: implement taking screenshots here again

        return UpdateTimesState(self.context, battle_menu_time)
