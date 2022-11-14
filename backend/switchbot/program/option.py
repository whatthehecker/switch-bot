from dataclasses import dataclass, field
from typing import Optional, FrozenSet


@dataclass(eq=True, frozen=True, kw_only=True)
class Option:
    type: str = field(init=False)
    name: str
    description: str
    allow_change_at_runtime: bool = field(init=True, default=False)


@dataclass(eq=True, frozen=True, kw_only=True)
class SelectionOption(Option):
    choices: FrozenSet[str]
    type = 'selection'
    default_value_index: int = 0


@dataclass(eq=True, frozen=True, kw_only=True)
class IntOption(Option):
    default_value: int
    type = 'int'
    max_value: Optional[int] = None
    min_value: Optional[int] = None


@dataclass(eq=True, frozen=True, kw_only=True)
class BoolOption(Option):
    type = 'bool'
    default_value: bool


@dataclass(eq=True, frozen=True, kw_only=True)
class StringOption(Option):
    type = 'string'
    default_value: str
