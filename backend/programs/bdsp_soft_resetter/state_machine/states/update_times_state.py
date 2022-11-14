from typing import Optional

from .launch_game_state import LaunchGameState
from ...animation_type import AnimationType
from ...bdsp_soft_resetter import BdspContext
from ..state_machine import State
from .end_state import EndState
from switchbot.program.dialog import Dialog

MAX_DIFF = 0.25


class UpdateTimesState(State):
    def __init__(self, context: BdspContext, timeout: float):
        super().__init__(context)
        self.timeout = timeout

    async def handle_first_encounter(self) -> Optional[State]:
        type_response: str = await self.context.program.show_dialog(
            self.context.bot,
            dialog=Dialog(
                'Animation type',
                f'Encounter took {self.timeout:.2f} seconds.\nWas this a normal battle animation?',
                ['Normal', 'Long', 'Shiny']
            )
        )

        # todo: re-introduce writing statistics.
        if type_response == 'Normal':
            self.context.animation_times[AnimationType.normal] = self.timeout
        elif type_response == 'Long':
            self.context.animation_times[AnimationType.special] = self.timeout
        else:
            self.context.program.logger.info('Encounter was shiny, stopping.')
            return EndState(self.context)

        # If we did not exit because this is a shiny, reset and go for the next encounter.
        return LaunchGameState(self.context)

    def _get_matching_animation_type(self) -> Optional[AnimationType]:
        for animation_type, animation_time in self.context.animation_times.items():
            # TODO: make max_diff configurable
            if abs(self.timeout - animation_time) < MAX_DIFF:
                return animation_type
        return None

    async def handle_other_encounter(self) -> Optional[State]:
        # If encounter matches a normal animation type, go to next encounter.
        matching_animation_type = self._get_matching_animation_type()
        if matching_animation_type is not None:
            self.context.program.logger.info(f'Encounter animation type was {matching_animation_type}')
            return LaunchGameState(self.context)

        self.context.program.logger.info('Encounter did not match any known types, might be a shiny.')
        # Both a special and a normal time was set, meaning we either
        # found a shiny or a failed encounter.
        if AnimationType.normal in self.context.animation_times \
                and AnimationType.special in self.context.animation_times:
            return await self._handle_all_times_set()

        # At least one time is missing, set it now.
        if AnimationType.normal not in self.context.animation_times:
            return await self._handle_normal_time_missing()
        else:
            return await self._handle_long_time_missing()

    async def _handle_long_time_missing(self):
        type_response = await self.context.program.show_dialog(
            self.context.bot,
            dialog=Dialog(
                'Long encounter?',
                f'''
Was this a long battle animation? 
Normal animation time is {self.context.animation_times[AnimationType.normal]:.2f} s, this was {self.timeout:.2f} s.
                                    ''',
                ['Long', 'Shiny', 'Ignore']
            )
        )
        if type_response == 'Long':
            self.context.animation_times[AnimationType.special] = self.timeout
            return LaunchGameState(self.context)
        elif type_response == 'Ignore':
            return LaunchGameState(self.context)
        else:
            return EndState(self.context)

    async def _handle_normal_time_missing(self):
        type_response = await self.context.program.show_dialog(
            self.context.bot,
            dialog=Dialog(
                'Normal encounter?',
                f'''
Was this a normal (non-long) battle animation?
Long animation time is {self.context.animation_times[AnimationType.special]:.2f} s, this was {self.timeout:.2f} s.
                        ''',
                ['Normal', 'Shiny', 'Ignore']
            )
        )
        if type_response == 'Normal':
            self.context.animation_times[AnimationType.normal] = self.timeout
            return LaunchGameState(self.context)
        elif type_response == 'Ignore':
            return LaunchGameState(self.context)
        else:
            return EndState(self.context)

    async def _handle_all_times_set(self) -> Optional[State]:
        shiny_response: str = await self.context.program.show_dialog(
            self.context.bot,
            dialog=Dialog(
                'Shiny?',
                f'''
Is this a shiny? Yes to stop the program, No to treat this as a false positive and continue.\n
Encounter time was {self.timeout:.2f} s and known times are normal: 
{self.context.animation_times[AnimationType.normal]:.2f} s 
and special: {self.context.animation_times[AnimationType.special]} with a max diff of {MAX_DIFF} seconds.'
                    ''',
                buttons=['Yes', 'No']
            )
        )
        is_shiny: bool = shiny_response == 'Yes'
        if is_shiny:
            return EndState(self.context)
        else:
            return LaunchGameState(self.context)

    async def execute(self) -> Optional[State]:
        is_first_successful_encounter = len(self.context.animation_times) == 0
        if is_first_successful_encounter:
            return await self.handle_first_encounter()
        return await self.handle_other_encounter()
