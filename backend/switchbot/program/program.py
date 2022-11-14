import logging
from abc import abstractmethod, ABC
from asyncio import Event
from dataclasses import dataclass
from typing import List, Dict, Optional

from dataclasses_json import dataclass_json

from .dialog import Dialog
from ..bot.switch_bot import SwitchBot
from .option import Option


@dataclass_json
@dataclass
class ProgramMetadata:
    options: List[Option]
    name: str
    description: str


class Program(ABC):
    """
    Base class for any user-created programs that can be run.
    """

    @abstractmethod
    def __init__(self, logger: logging.Logger):
        self.logger = logger
        self.option_values: Dict[str, object] = {}
        # An event that can be used to wait indefinitely until a dialog has been answered by the user.
        self.dialog_flag: Event = Event()
        # Stores the last result for a dialog that was closed.
        self.dialog_result: Optional[str] = None
        self.current_dialog: Optional[Dialog] = None

    @property
    @abstractmethod
    def name(self) -> str:
        return 'Unnamed Program'

    @property
    @abstractmethod
    def options(self) -> List[Option]:
        return []

    @property
    @abstractmethod
    def description(self):
        return 'No description.'

    @property
    def metadata(self) -> ProgramMetadata:
        """
        Builds a container with this program's metadata.

        Mostly exists so all these properties can be passed around in a single object.
        :return: A metadata object describing this program.
        """

        return ProgramMetadata(
            options=self.options,
            name=self.name,
            description=self.description
        )

    @abstractmethod
    async def run(self, switch_bot: SwitchBot) -> None:
        """
        The main entry point for running a custom program.

        Override this to implement the functionality of your program.
        """
        pass

    async def show_dialog(self, switch_bot: SwitchBot, dialog: Dialog) -> str:
        # Remember the currently active dialog so any clients joining afterward can receive it.
        self.current_dialog = dialog

        # Reset flag so we don't instantly go past the wait statement.
        self.dialog_flag.clear()
        await switch_bot.display.show_dialog(dialog.title, dialog.content, dialog.buttons)
        await self.dialog_flag.wait()
        # Get the last result as it was set by on_user_interaction
        result: str = self.dialog_result
        self.dialog_result = None
        self.current_dialog = None
        return result

    def on_user_interaction(self, pressed_button: str) -> None:
        # Store the content of the button that was pressed and resume regular program flow.
        self.dialog_result = pressed_button
        self.dialog_flag.set()

    def update_option_values(self, option_values: Dict[str, object]) -> None:
        """
        Called when the values chosen for any option are changed.

        Might be called even when a program is already running. The default implementation updates all options.

        If your program should react differently, override this method.

        :param option_values: The new values for all options.
        """
        self.option_values = option_values
        self.logger.info(f'Updated option values to: {self.option_values}')
