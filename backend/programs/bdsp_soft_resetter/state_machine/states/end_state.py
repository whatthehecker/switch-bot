from typing import Optional

from ..state_machine import State


class EndState(State):
    async def execute(self) -> Optional[State]:
        self.context.program.logger.info(f'{self.context.program.name} stopped.')
        return None
