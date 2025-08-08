from __future__ import annotations
from pydantic import BaseModel, Field
from typing import Optional, Literal

Position = Literal["QB","RB","WR","TE","OT","IOL","EDGE","IDL","LB","CB","S","K","P"]

class Player(BaseModel):
    id: int
    name: str
    position: Position
    age: int = Field(ge=18, le=40)
    overall: int = Field(ge=20, le=99)
    speed: int = Field(ge=20, le=99)
    strength: int = Field(ge=20, le=99)
    agility: int = Field(ge=20, le=99)
    awareness: int = Field(ge=20, le=99)
    potential: int = Field(ge=20, le=99)
    team_id: Optional[int] = None

class Team(BaseModel):
    id: int
    city: str
    name: str
    abbrev: str
    primary_color: str = "#1f2937"
    secondary_color: str = "#9ca3af"
    wins: int = 0
    losses: int = 0

class Game(BaseModel):
    id: int
    week: int
    home_team_id: int
    away_team_id: int
    home_score: int = 0
    away_score: int = 0
    played: bool = False
