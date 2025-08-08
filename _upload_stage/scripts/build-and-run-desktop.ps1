# Build the desktop app + sidecar backend (Windows)
param(
  [switch]$SkipRustCheck
)

$ErrorActionPreference = 'Stop'

# Ensure Python venv
if (Test-Path .\.venv\Scripts\python.exe) {
  Write-Host "Using existing .venv"
} else {
  if (Get-Command py -ErrorAction SilentlyContinue) {
    py -3.11 -m venv .venv
  } else {
    python -m venv .venv
  }
}
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\pip.exe install -r requirements.txt
# Build sidecar exe
.\.venv\Scripts\pip.exe install pyinstaller
.\.venv\Scripts\pyinstaller.exe --onefile --noconsole backend_runner.py --name backend

# Determine Rust target triple for naming
if (-not $SkipRustCheck) {
  try {
    $hostLine = (& rustc -vV | Select-String 'host:').ToString()
  } catch {
    Write-Warning "Rust toolchain not found. Install Rust (rustup) and VS Build Tools."
    throw
  }
} else {
  $hostLine = 'host: x86_64-pc-windows-msvc'
}

$triple = $hostLine.Split(':')[-1].Trim()
Write-Host "Rust host triple: $triple"

# Copy exe into Tauri sidecar location
New-Item -Force -ItemType Directory -Path .\desktop\src-tauri\binaries | Out-Null
Copy-Item .\dist\backend.exe ".\desktop\src-tauri\binaries\backend-$triple.exe" -Force

# Install desktop dev tooling
Push-Location desktop
if (!(Test-Path package-lock.json)) {
  npm install
} else {
  npm ci
}

# Build the installer
npm run tauri:build
Pop-Location

Write-Host "Build complete. Check desktop\src-tauri\target\release\bundle for the installer."

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
