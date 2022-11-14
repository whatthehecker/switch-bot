from programs.bdsp_soft_resetter.battle_entry import BattleEntryDelegate, BattleEntry

PRESET_BATTLE_ENTRIES: {str: BattleEntryDelegate} = {
    'Registeel': BattleEntry.simple(pre_battle_animation_timeout=4.0, animation_timeout=7.0),
    'Regirock': BattleEntry.simple(pre_battle_animation_timeout=4.0, animation_timeout=7.0),
    'Regice': BattleEntry.simple(pre_battle_animation_timeout=4.0, animation_timeout=7.0),
    'Darkrai': BattleEntry.simple(pre_battle_animation_timeout=7.0, animation_timeout=7.0),
    'Palkia': BattleEntry.step_forward(steps=1, pre_battle_animation_timeout=3.0, animation_timeout=7.0),
    'Dialga': BattleEntry.step_forward(steps=1, pre_battle_animation_timeout=3.0, animation_timeout=7.0),
    'Giratina': BattleEntry.simple(pre_battle_animation_timeout=4.0, animation_timeout=7.0),
    'Heatran': BattleEntry.simple(pre_battle_animation_timeout=4.0, animation_timeout=10.0)
}