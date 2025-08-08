from __future__ import annotations

import random
from typing import Optional, List
from fastapi import FastAPI, APIRouter, Body, Path
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

# ---------- Models ----------

class Owner(BaseModel):
    id: int
    name: str

class OwnerCreate(BaseModel):
    name: str

class Team(BaseModel):
    id: int
    name: str
    owner_id: Optional[int] = None

class TeamCreate(BaseModel):
    name: str
    owner_id: Optional[int] = None

class Player(BaseModel):
    id: int
    name: str
    position: str
    team_id: Optional[int] = None

class PlayerCreate(BaseModel):
    name: str
    position: str
    team_id: Optional[int] = None

# ---------- In-memory "DB" ----------

STATE = {
    "owners": [],   # type: List[Owner]
    "teams": [],    # type: List[Team]
    "players": [],  # type: List[Player]
}
COUNTERS = {"owner": 1, "team": 1, "player": 1}

def next_id(key: str) -> int:
    COUNTERS[key] += 1
    return COUNTERS[key] - 1

# ---------- App ----------

app = FastAPI(title="Gridiron API", version="0.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
        "tauri://localhost",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Meta
@app.get("/api/health", tags=["meta"])
def api_health():
    return {"status": "ok"}

@app.get("/api/version", tags=["meta"])
def version():
    return {"version": app.version}

# Router with /api prefix
api = APIRouter(prefix="/api")

# ----- Owners -----

@api.get("/owners", response_model=List[Owner], tags=["owners"])
def list_owners():
    return STATE["owners"]

@api.post("/owners", response_model=Owner, tags=["owners"])
def create_owner(payload: OwnerCreate = Body(...)):
    new = Owner(id=next_id("owner"), name=payload.name)
    STATE["owners"].append(new)
    return new

# ----- Teams -----

@api.get("/teams", response_model=List[Team], tags=["teams"])
def list_teams():
    return STATE["teams"]

@api.post("/teams", response_model=Team, tags=["teams"])
def create_team(payload: TeamCreate = Body(...)):
    new = Team(id=next_id("team"), name=payload.name, owner_id=payload.owner_id)
    STATE["teams"].append(new)
    return new

# ----- Players -----

@api.get("/players", response_model=List[Player], tags=["players"])
def list_players():
    return STATE["players"]

@api.post("/players", response_model=Player, tags=["players"])
def create_player(payload: PlayerCreate = Body(...)):
    new = Player(id=next_id("player"), name=payload.name, position=payload.position, team_id=payload.team_id)
    STATE["players"].append(new)
    return new

# ----- Simulation -----

@api.post("/simulate-game/{game_id}", tags=["simulation"])
def simulate_game(game_id: int = Path(..., ge=1)):
    home = random.randint(10, 40)
    away = random.randint(10, 40)
    # Prevent ties to make it obvious something happened
    if home == away:
        away += 1
    return {"game_id": game_id, "home": home, "away": away, "winner": "home" if home > away else "away"}

app.include_router(api)
