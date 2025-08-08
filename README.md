# Gridiron Desktop (Tauri) – v1

This package contains:
- FastAPI backend (Python 3.11), with `/api/*` endpoints and health checks
- React + Vite frontend
- Tauri desktop project that launches the backend as a **sidecar** (127.0.0.1:8787)
- PowerShell scripts:
  - `scripts/dev-desktop.ps1` – build sidecar exe and run `tauri dev`
  - `scripts/build-desktop.ps1` – build sidecar exe and produce a signed installer (unsigned on your machine)

## Prerequisites (Windows)
1. **Python 3.11** (your project already uses this)
2. **Rust** toolchain (`rustup`) + **Visual Studio Build Tools** (Desktop C++ and Windows SDK)
3. **Node.js LTS**

## Dev run
```powershell
# from repo root
.\scripts\dev-desktop.ps1
```
This will:
- create/refresh `.venv`
- build `backend.exe` (FastAPI runner) via PyInstaller
- copy it to `desktop\src-tauri\binaries\backend-<triple>.exe`
- start `tauri dev`, which starts Vite and opens the desktop window

## Build installer
```powershell
# from repo root
.\scriptsuild-desktop.ps1
```
Your installer will appear under:
`desktop\src-tauri\target\release\bundle\`

## Frontend API base
The UI auto-detects Tauri and calls `http://127.0.0.1:8787/api/...`.
When not in Tauri (browser dev), it uses the Vite proxy to `127.0.0.1:8000` for `/api`.

## Backend health
- `GET /api/health` and `/health` return `{"status":"ok"}`
- Docs available at `http://127.0.0.1:8787/docs` when the sidecar is running
