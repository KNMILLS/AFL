# Run the desktop app in dev mode (Windows)
$ErrorActionPreference = 'Stop'

# Build sidecar backend exe first so Tauri can spawn it
if (!(Test-Path .\.venv\Scripts\python.exe)) {
  if (Get-Command py -ErrorAction SilentlyContinue) {
    py -3.11 -m venv .venv
  } else {
    python -m venv .venv
  }
}
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\pip.exe install -r requirements.txt
.\.venv\Scripts\pip.exe install pyinstaller
.\.venv\Scripts\pyinstaller.exe --onefile --noconsole backend_runner.py --name backend

# Detect Rust triple for naming
try {
  $hostLine = (& rustc -vV | Select-String 'host:').ToString()
} catch {
  Write-Warning "Rust toolchain not found. Install Rust (rustup) and VS Build Tools)."
  throw
}
$triple = $hostLine.Split(':')[-1].Trim()

New-Item -Force -ItemType Directory -Path .\desktop\src-tauri\binaries | Out-Null
Copy-Item .\dist\backend.exe ".\desktop\src-tauri\binaries\backend-$triple.exe" -Force

Push-Location desktop
if (!(Test-Path package-lock.json)) {
  npm install
} else {
  npm ci
}
npm run tauri:dev
Pop-Location
