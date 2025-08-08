from __future__ import annotations
from typing import Dict
from .models import Team, Player, Game

class State:
    def __init__(self) -> None:
        self.reset()

    def reset(self) -> None:
        self.week: int = 1
        self.teams: Dict[int, Team] = {}
        self.players: Dict[int, Player] = {}
        self.games: Dict[int, Game] = {}
        self._next_team_id = 1
        self._next_player_id = 1
        self._next_game_id = 1

    def next_team_id(self) -> int:
        x = self._next_team_id; self._next_team_id += 1; return x

    def next_player_id(self) -> int:
        x = self._next_player_id; self._next_player_id += 1; return x

    def next_game_id(self) -> int:
        x = self._next_game_id; self._next_game_id += 1; return x

state = State()
