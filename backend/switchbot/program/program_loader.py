import importlib.machinery
import importlib.util
from pathlib import Path
from typing import Type, Optional

from .program import Program


def import_program_from_directory(directory_path: Path) -> Optional[Type[Program]]:
    target_module_name: str = directory_path.stem
    main_file_path = directory_path / f'{target_module_name}.py'

    if not main_file_path.exists():
        return None

    for module_path in directory_path.glob('**/*.py'):
        if module_path.stem == target_module_name:
            continue
        # -1 because '.' does not really count: https://stackoverflow.com/a/69572091
        depth = len(module_path.parents) - 1
        if depth <= 2:
            importlib.import_module('.' + module_path.stem, f'programs.{target_module_name}')
        else:
            # Assume that first parent is the one with the most directory depth.
            longest_parent = module_path.parents[0]
            # Extremely ugly.
            # Also ignore the first two directories since those are "programs" and "<the program being imported>"
            parent_joined = '.'.join(longest_parent.as_posix().split('/')[2:])
            importlib.import_module('.' + module_path.stem, f'programs.{target_module_name}.{parent_joined}')

    main_module_spec = importlib.util.spec_from_file_location(f'programs.{target_module_name}.{target_module_name}', main_file_path)
    main_module = importlib.util.module_from_spec(main_module_spec)
    main_module_spec.loader.exec_module(main_module)

    # Search and load main program class.
    for attribute in dir(main_module):
        attribute = getattr(main_module, attribute)
        # Check whether the found attribute is a class inheriting from Program but is not the
        # imported program class itself.
        if isinstance(attribute, type) and issubclass(attribute, Program) and attribute is not Program:
            return attribute

    return None
