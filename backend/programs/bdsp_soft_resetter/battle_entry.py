"""
A callable function that has the purpose to enter the encounter for a given Pokémon.
This method is expected to advance the game until the game starts the battle animation and the screen
turns dark or does whatever animation is played for the Pokémon.
"""
from asyncio import sleep
from typing import Callable, Awaitable

from switchbot.bot.switch_bot import SwitchBot

BattleEntryDelegate = Callable[[SwitchBot], Awaitable[None]]


class BattleEntry:
    @staticmethod
    def step_forward(steps: int, pre_battle_animation_timeout: float,
                     animation_timeout: float) -> BattleEntryDelegate:
        async def do_entry(switch_bot: SwitchBot) -> None:
            for _ in range(steps):
                switch_bot.serial.tap_up()
                # TODO: fine-tune these timeouts
                await sleep(0.5)
            await sleep(1.5)
            switch_bot.serial.tap_a()
            await sleep(pre_battle_animation_timeout)
            switch_bot.serial.tap_a()
            await sleep(animation_timeout)

        return do_entry

    @staticmethod
    def simple(pre_battle_animation_timeout: float, animation_timeout: float) -> BattleEntryDelegate:
        async def do_entry(switch_bot: SwitchBot) -> None:
            # Press A to start the pre-battle animation which results in a textbox with the Pokémon's
            # scream being displayed.
            print('Opening encounter text box...')
            switch_bot.serial.tap_a()
            await sleep(pre_battle_animation_timeout)
            print('Closing encounter text box...')
            # Press A to close the textbox and play the animation of entering the battle.
            switch_bot.serial.tap_a()
            await sleep(animation_timeout)

        return do_entry
