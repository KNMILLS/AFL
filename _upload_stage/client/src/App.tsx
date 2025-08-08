import { useEffect, useMemo, useState } from "react";
import { API_BASE, apiGet, apiPost } from "./api";

type Owner = { id: number; name: string };
type Team = { id: number; name: string; owner_id?: number | null };
type Player = { id: number; name: string; position: string; team_id?: number | null };

export default function App() {
  const [health, setHealth] = useState<string>("...");
  const [version, setVersion] = useState<string>("...");
  const [owners, setOwners] = useState<Owner[]>([]);
  const [teams, setTeams] = useState<Team[]>([]);
  const [players, setPlayers] = useState<Player[]>([]);

  const [newTeamName, setNewTeamName] = useState("");
  const [newPlayerName, setNewPlayerName] = useState("");
  const [newPlayerPos, setNewPlayerPos] = useState("QB");
  const [newPlayerTeamId, setNewPlayerTeamId] = useState<number | "">("");

  const [simResult, setSimResult] = useState<string>("");

  async function refreshAll() {
    try {
      const h = await apiGet<{ status: string }>("/health");
      setHealth(h.status);
      const v = await apiGet<{ version: string }>("/version");
      setVersion(v.version);
      setOwners(await apiGet<Owner[]>("/owners"));
      setTeams(await apiGet<Team[]>("/teams"));
      setPlayers(await apiGet<Player[]>("/players"));
    } catch (err) {
      console.error(err);
    }
  }

  useEffect(() => {
    refreshAll();
  }, []);

  async function addTeam() {
    if (!newTeamName.trim()) return;
    await apiPost<Team>("/teams", { name: newTeamName.trim() });
    setNewTeamName("");
    refreshAll();
  }

  async function addPlayer() {
    if (!newPlayerName.trim()) return;
    const team_id = newPlayerTeamId === "" ? undefined : Number(newPlayerTeamId);
    await apiPost<Player>("/players", {
      name: newPlayerName.trim(),
      position: newPlayerPos.trim() || "QB",
      team_id,
    });
    setNewPlayerName("");
    setNewPlayerPos("QB");
    setNewPlayerTeamId("");
    refreshAll();
  }

  async function simGame() {
    const r = await apiPost<{ game_id: number; home: number; away: number; winner: string }>(
      "/simulate-game/1"
    );
    setSimResult(`${r.home} - ${r.away} (winner: ${r.winner})`);
  }

  const teamsById = useMemo(() => Object.fromEntries(teams.map(t => [t.id, t])), [teams]);

  return (
    <div style={{ padding: 16, fontFamily: "system-ui, sans-serif" }}>
      <h1>Gridiron GM (Desktop)</h1>

      <p>
        API base: <code>{API_BASE}</code>
      </p>
      <p>
        API health: <strong>{health}</strong>
      </p>
      <p>API version: {version}</p>

      <hr />

      <section>
        <h2>Teams</h2>
        <div style={{ display: "flex", gap: 8, marginBottom: 8 }}>
          <input
            placeholder="New team name"
            value={newTeamName}
            onChange={(e) => setNewTeamName(e.target.value)}
          />
          <button onClick={addTeam}>Add Team</button>
        </div>
        <table cellPadding={4}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
            </tr>
          </thead>
          <tbody>
            {teams.map((t) => (
              <tr key={t.id}>
                <td>{t.id}</td>
                <td>{t.name}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <hr />

      <section>
        <h2>Players</h2>
        <div style={{ display: "flex", gap: 8, marginBottom: 8, flexWrap: "wrap" }}>
          <input
            placeholder="Player name"
            value={newPlayerName}
            onChange={(e) => setNewPlayerName(e.target.value)}
          />
          <input
            placeholder="Pos"
            style={{ width: 60 }}
            value={newPlayerPos}
            onChange={(e) => setNewPlayerPos(e.target.value)}
          />
          <select
            value={newPlayerTeamId}
            onChange={(e) => setNewPlayerTeamId(e.target.value as any)}
          >
            <option value="">(no team)</option>
            {teams.map((t) => (
              <option key={t.id} value={t.id}>{t.name}</option>
            ))}
          </select>
          <button onClick={addPlayer}>Add Player</button>
        </div>
        <table cellPadding={4}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Pos</th>
              <th>Team</th>
            </tr>
          </thead>
          <tbody>
            {players.map((p) => (
              <tr key={p.id}>
                <td>{p.id}</td>
                <td>{p.name}</td>
                <td>{p.position}</td>
                <td>{p.team_id ? teamsById[p.team_id]?.name ?? p.team_id : "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <hr />

      <section>
        <h2>Sim a Game</h2>
        <button onClick={simGame}>Simulate Game #1</button>
        {simResult && <p style={{ marginTop: 8 }}>Result: {simResult}</p>}
      </section>
    </div>
  );
}
