import logging
from typing import List

from switchbot.bot.switch_bot import SwitchBot
from switchbot.program.dialog import Dialog
from switchbot.program.option import StringOption, Option
from switchbot.program.program import Program


class TestProgram(Program):
    def __init__(self, logger: logging.Logger):
        super().__init__(logger)

    @property
    def name(self) -> str:
        return 'Test Program'

    @property
    def options(self) -> List[Option]:
        return [
            StringOption(name='A String option', description='Example option', allow_change_at_runtime=True,
                         default_value='Test')
        ]

    @property
    def description(self):
        return 'Test program, only used for testing'

    async def run(self, switch_bot: SwitchBot) -> None:
        self.logger.info(f'Hello from {self.name}!')
        result = await self.show_dialog(
            switch_bot,
            dialog=Dialog(
                'Test dialog',
                'Press OK to close this dialog.',
                ['OK']
            )
        )
        self.logger.info(f'Finished waiting for dialog, result was: {result}')
        for i in range(10):
            self.logger.info(f'Test message {i}')
