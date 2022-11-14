import asyncio
from typing import Optional

from . import enter_encounter_state
from ..state_machine import State


class LaunchGameState(State):
    async def execute(self) -> Optional[State]:
        self.context.encounters += 1
        self.context.program.logger.info(f'Encounter {self.context.encounters} starting...')

        await self.close_game()
        await self.enter_game()

        return enter_encounter_state.EnterEncounterState(self.context)

    async def close_game(self) -> None:
        """
        Closes the game currently running on the Switch.
        """
        self.context.program.logger.info('Entering home')
        self.context.bot.serial.press_home()
        await asyncio.sleep(0.5)
        self.context.program.logger.info('Opening closing dialog')
        self.context.bot.serial.press_x()
        await asyncio.sleep(0.5)
        self.context.program.logger.info('Confirming close dialog')
        self.context.bot.serial.press_a()
        # closed software.
        await asyncio.sleep(2)
        self.context.program.logger.info('Launching user selection dialog')
        self.context.bot.serial.press_a()
        await asyncio.sleep(2)
        self.context.program.logger.info('Selected user')
        self.context.bot.serial.press_a()
        # Launched game.
        await asyncio.sleep(22.5)

    async def enter_game(self) -> None:
        """
        Skips the intro cutscene and waits until the player has loaded into the overworld.
        """
        self.context.program.logger.info('Closing intro animation')
        self.context.bot.serial.press_a()
        await asyncio.sleep(5)
        self.context.program.logger.info('Closing main menu')
        self.context.bot.serial.press_a()
        await asyncio.sleep(15)
