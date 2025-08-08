# "Hello data" MVP patch

This zip contains only the **changed/new files** you need to drop into your existing
`gridiron-desktop-v1` repo. It assumes your backend FastAPI lives at `app/main.py`
and the frontend is the Vite + React app under `client/`.

## What's included

- `app/__init__.py` (package marker)
- `app/main.py` — FastAPI app with `/api` prefix, in‑memory stores, CRUD for owners/teams/players,
  `GET /api/health`, `GET /api/version`, and `POST /api/simulate-game/{game_id}`.
- `client/src/api.ts` — tiny API helper that points to `http://127.0.0.1:8787/api` in Tauri,
  or `http://127.0.0.1:8000/api` when running just the API.
- `client/src/App.tsx` — minimal UI to list/add a **team** and a **player**, and a **Simulate Game**
  button that calls `/api/simulate-game/1` and shows a random score.

Nothing else in your repo is touched.

## How to integrate

1. **Unzip** this archive into the root of your project (`gridiron-desktop-v1`),
   allowing it to **overwrite** existing files with the same paths.

2. (Optional) If you want to run the API by itself first:
   ```powershell
   # from repo root
   python -m uvicorn app.main:app --reload --port 8000
   # test:
   irm http://127.0.0.1:8000/api/health
   ```

3. **Run the desktop app (Tauri + sidecar)** the way you've been doing:
   ```powershell
   .\scripts\dev-desktop.ps1
   ```
   - Vite dev server will start at `http://localhost:5173/`.
   - The Python sidecar will listen on `http://127.0.0.1:8787`.
   - The Tauri window should open. You’ll see *Teams*, *Players*, and *Sim a Game* sections.

4. **Verify endpoints** (desktop mode):
   ```powershell
   irm http://127.0.0.1:8787/api/health
   irm http://127.0.0.1:8787/api/version
   irm http://127.0.0.1:8787/api/teams
   irm http://127.0.0.1:8787/api/players
   ```

5. If the frontend ever points to the wrong API base, open `client/src/api.ts` and adjust the URLs.

> Note: This is an **in-memory** store; data resets when the sidecar/API restarts.
