import csv
from datetime import datetime
from typing import Optional

from .animation_type import AnimationType


class StatisticsWriter:
    def __init__(self, csv_path: str):
        self.file = open(csv_path, 'w', newline='')
        self.writer = csv.writer(self.file)

    def write_header(self):
        self.writer.writerow([
            'encounter',
            'encounter_time',
            'battle_menu_time',
            'encounter_type',
            'shiny'
        ])
        self.file.flush()

    def write_encounter(self,
                        encounter: int,
                        encounter_timestamp: datetime,
                        encounter_animation_time: float,
                        battle_menu_animation_time: float,
                        encounter_type: Optional[AnimationType],
                        shiny: bool):
        self.writer.writerow([
            encounter,
            encounter_timestamp.isoformat(),
            encounter_animation_time,
            battle_menu_animation_time,
            encounter_type,
            shiny
        ])
        self.file.flush()

    def close(self):
        self.file.close()