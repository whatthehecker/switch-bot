from typing import Optional

from ...battle_entry import BattleEntryDelegate
from ..state_machine import State
from .wait_for_menu_state import MeasureTimeState
from ...battle_entry_presets import PRESET_BATTLE_ENTRIES


class EnterEncounterState(State):
    async def execute(self) -> Optional[State]:
        self.context.program.logger.info('Entering encounter using chosen preset method...')
        preset: BattleEntryDelegate = PRESET_BATTLE_ENTRIES[self.context.preset_name]
        await preset(self.context.bot)

        self.context.program.logger.info('Preset should have started battle now, waiting for battle menu...')
        return MeasureTimeState(self.context)
