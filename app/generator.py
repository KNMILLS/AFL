from __future__ import annotations
import random
from typing import List, Dict, Tuple
from .models import Team, Player, Game, Position
from .state import state

FIRST_NAMES = ["Alex","Jordan","Chris","Taylor","Casey","Dakota","Riley","Jamie","Cameron","Drew",
               "Sam","Jesse","Avery","Reese","Shawn","Evan","Peyton","Corey","Morgan","Brett"]
LAST_NAMES  = ["Johnson","Smith","Williams","Brown","Jones","Miller","Davis","Garcia","Rodriguez","Wilson",
               "Martinez","Anderson","Taylor","Thomas","Hernandez","Moore","Martin","Lee","Perez","Thompson"]

CITIES = ["Arlington","Brooklyn","Cincinnati","Denver","Everett","Fresno","Glendale","Hartford",
          "Irvine","Jacksonville","Knoxville","Louisville","Memphis","Nashville","Orlando","Phoenix"]
NICKNAMES = ["Guardians","Hawks","Lancers","Mustangs","Rangers","Redwoods","Suns","Sharks",
             "Storm","Titans","Warriors","Wolves","Comets","Lightning","Falcons","Pioneers"]

ROSTER_53: List[Tuple[Position, int]] = [
    ("QB",3), ("RB",4), ("WR",6), ("TE",3), ("OT",4), ("IOL",5),
    ("EDGE",5), ("IDL",5), ("LB",6), ("CB",6), ("S",4), ("K",1), ("P",1)
]

def _rand_name(rng: random.Random) -> str:
    return f"{rng.choice(FIRST_NAMES)} {rng.choice(LAST_NAMES)}"

def _abbr(city: str, name: str, taken: set[str]) -> str:
    base = (city[:1] + name[:2]).upper()
    x = base; i = 0
    while x in taken:
        i += 1
        x = (base[:2] + str(i))[:3].upper()
    taken.add(x)
    return x

def generate_league(num_teams: int = 16, roster_size: int = 53, seed: int | None = None) -> None:
    assert num_teams % 2 == 0, "num_teams must be even"
    rng = random.Random(seed)
    state.reset()

    used_abbr = set()
    for _ in range(num_teams):
        city = rng.choice(CITIES)
        name = rng.choice(NICKNAMES)
        team = Team(
            id=state.next_team_id(),
            city=city,
            name=name,
            abbrev=_abbr(city, name, used_abbr),
            primary_color=f"#{rng.randrange(0x111111, 0xFFFFFF):06x}",
            secondary_color=f"#{rng.randrange(0x111111, 0xFFFFFF):06x}",
        )
        state.teams[team.id] = team

    for t in state.teams.values():
        created = 0
        while created < roster_size:
            pos = rng.choice([p for p,c in ROSTER_53 for _ in range(c)])
            pot = rng.randint(50, 99)
            ovl_base = pot - rng.randint(0, 25) + rng.randint(-3, 3)
            player = Player(
                id=state.next_player_id(),
                name=_rand_name(rng),
                position=pos,  # type: ignore[arg-type]
                age=rng.randint(21, 34),
                overall=max(20, min(99, ovl_base)),
                speed=rng.randint(50, 99),
                strength=rng.randint(50, 99),
                agility=rng.randint(50, 99),
                awareness=rng.randint(40, 95),
                potential=pot,
                team_id=t.id,
            )
            state.players[player.id] = player
            created += 1

    teams = list(state.teams.keys())
    weeks = max(1, min(17, len(teams) - 1))
    if len(teams) % 2 != 0:
        teams.append(-1)
    n = len(teams)
    for w in range(1, weeks + 1):
        for i in range(n // 2):
            home = teams[i]
            away = teams[n - 1 - i]
            if home == -1 or away == -1:
                continue
            if w % 2 == 0:
                home, away = away, home
            game = Game(
                id=state.next_game_id(),
                week=w,
                home_team_id=home,
                away_team_id=away,
            )
            state.games[game.id] = game
        teams = [teams[0]] + [teams[-1]] + teams[1:-1]
