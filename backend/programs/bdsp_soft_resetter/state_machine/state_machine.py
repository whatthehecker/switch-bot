import logging
import typing
from abc import ABC, abstractmethod
from typing import Optional

if typing.TYPE_CHECKING:
    from programs.bdsp_soft_resetter.bdsp_soft_resetter import BdspContext

logger = logging.getLogger('StateMachine')


class State(ABC):
    def __init__(self, context: 'BdspContext'):
        self.context = context

    @abstractmethod
    async def execute(self) -> Optional['State']:
        pass

    def __str__(self):
        return self.__class__.__name__


class StateMachine:

    def __init__(self, initial_state: 'State'):
        self.state = initial_state

    def change_state(self, state: 'State'):
        self.state = state
        logger.debug(f'Changed to new state: {state}')

    async def run(self):
        logger.info('State machine starting.')
        while (next_state := await self.state.execute()) is not None:
            self.change_state(next_state)
        logger.info('State machine stopped.')
