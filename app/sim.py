from __future__ import annotations
import random
from .state import state
from .models import Game

def _score(mu: float, rng: random.Random) -> int:
    raw = int(rng.gauss(mu, 7))
    return max(0, min(60, raw))

def team_strength(team_id: int) -> float:
    roster = [p.overall for p in state.players.values() if p.team_id == team_id]
    roster.sort(reverse=True)
    core = roster[:22] if roster else [60]
    return sum(core) / len(core)

def simulate_game(game: Game, seed: int | None = None) -> Game:
    rng = random.Random(seed)
    s_home = team_strength(game.home_team_id)
    s_away = team_strength(game.away_team_id)
    diff = (s_home - s_away) / 3.0
    home_mu = 21 + diff + 1.5
    away_mu = 21 - diff

    game.home_score = _score(home_mu, rng)
    game.away_score = _score(away_mu, rng)
    if game.home_score == game.away_score:
        if rng.random() < 0.5:
            game.home_score += 3
        else:
            game.away_score += 3
    game.played = True

    home = state.teams[game.home_team_id]
    away = state.teams[game.away_team_id]
    if game.home_score > game.away_score:
        home.wins += 1; away.losses += 1
    else:
        away.wins += 1; home.losses += 1
    return game

def simulate_week() -> dict:
    week = state.week
    week_games = [g for g in state.games.values() if g.week == week and not g.played]
    for g in sorted(week_games, key=lambda x: x.id):
        simulate_game(g)
    if week_games:
        state.week += 1
    return {
        "week_simulated": week,
        "games": [g for g in week_games],
        "next_week": state.week,
    }
