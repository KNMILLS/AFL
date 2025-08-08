# Requires PowerShell 5+; run from project root: .\scripts\reset-rebuild-dev.ps1
# This script fully resets the workspace, rebuilds backend + desktop, and launches `tauri dev`.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Info($m){ Write-Host "==> $m" -ForegroundColor Cyan }
function Warn($m){ Write-Warning $m }
function Die($m){ Write-Error $m; exit 1 }

# --- Resolve key paths (relative to this script location) ---
$root      = Resolve-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) | ForEach-Object { Split-Path $_ -Parent }
$client    = Join-Path $root 'client'
$desktop   = Join-Path $root 'desktop'
$srcTauri  = Join-Path $desktop 'src-tauri'
$srcBin    = Join-Path $srcTauri 'bin'
$iconsDir  = Join-Path $srcTauri 'icons'
$venv      = Join-Path $root '.venv'
$distDir   = Join-Path $root 'dist'

if (-not (Test-Path $client))  { Die "Missing folder: $client" }
if (-not (Test-Path $desktop)) { Die "Missing folder: $desktop" }
if (-not (Test-Path $srcTauri)){ Die "Missing folder: $srcTauri" }
if (-not (Test-Path (Join-Path $root 'requirements.txt'))) { Die "Missing requirements.txt in $root" }
if (-not (Test-Path (Join-Path $root 'backend_runner.py'))) { Die "Missing backend_runner.py in $root" }

# --- 1) Kill processes that could hold locks ---
Info "Killing node/vite/tauri/backend/cargo processes..."
$names = @('tauri','vite','node','esbuild','backend','cargo','rustc')
foreach ($n in $names) {
  Get-Process -Name $n -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
# backend sidecar might be a child; try taskkill as well
Start-Process -FilePath "taskkill" -ArgumentList "/IM backend.exe /F /T" -NoNewWindow -Wait -ErrorAction SilentlyContinue | Out-Null

# --- 2) Remove attributes and delete build artifacts ---
Info "Cleaning build artifacts and caches..."
$pathsToClean = @(
  (Join-Path $client   'node_modules'),
  (Join-Path $desktop  'node_modules'),
  (Join-Path $srcTauri 'target'),
  (Join-Path $srcTauri 'binaries'),
  (Join-Path $srcTauri 'bin'),
  $iconsDir,
  $distDir,
  (Join-Path $root 'build'),
  (Join-Path $root 'backend.spec'),
  $venv
)

foreach ($p in $pathsToClean) {
  if (Test-Path $p) {
    try {
      attrib -R -S -H /S /D $p 2>$null
    } catch { }
    try {
      Remove-Item $p -Recurse -Force -ErrorAction Stop
    } catch {
      Warn "Direct removal failed for $p, trying rimraf..."
      try { npx --yes rimraf $p | Out-Null } catch { Warn "rimraf also failed on $p ($($_.Exception.Message))" }
    }
  }
}

# optional: clean npm cache
try { npm cache clean --force | Out-Null } catch { }

# --- 3) Recreate venv (Python 3.11) and install backend deps ---
Info "Creating Python 3.11 virtualenv..."
$pyExe = $null
if (Get-Command py -ErrorAction SilentlyContinue) {
  try { & py -3.11 -V *> $null; $pyExe = "py" } catch { }
}
if (-not $pyExe) {
  if (Get-Command python -ErrorAction SilentlyContinue) { $pyExe = "python" }
  else { Die "Python 3.11 launcher not found. Please install Python 3.11 first." }
}
if ($pyExe -eq "py") {
  & py -3.11 -m venv $venv
} else {
  & python -m venv $venv
}

$activate = Join-Path $venv 'Scripts\Activate.ps1'
. $activate

Info "Upgrading pip and installing backend requirements..."
python -m pip install -U pip
pip install -r (Join-Path $root 'requirements.txt') pyinstaller

# --- 4) Build backend sidecar with PyInstaller ---
Info "Building backend sidecar (PyInstaller)..."
pyinstaller --noconsole --onefile --name backend (Join-Path $root 'backend_runner.py')
if (-not (Test-Path (Join-Path $distDir 'backend.exe'))) { Die "PyInstaller did not produce dist\backend.exe" }

# Put sidecar in the canonical Tauri location for dev & bundling
New-Item -ItemType Directory -Force -Path $srcBin | Out-Null
Copy-Item (Join-Path $distDir 'backend.exe') (Join-Path $srcBin 'backend.exe') -Force

# --- 5) Ensure icons/icon.ico exists (create placeholder if missing) ---
Info "Ensuring Tauri icon exists..."
New-Item -ItemType Directory -Force -Path $iconsDir | Out-Null
$iconPath = Join-Path $iconsDir 'icon.ico'
if (-not (Test-Path $iconPath)) {
  Add-Type -AssemblyName System.Drawing
  $bmp = New-Object System.Drawing.Bitmap 64,64
  $gfx = [System.Drawing.Graphics]::FromImage($bmp)
  $gfx.Clear([System.Drawing.Color]::FromArgb(255,30,136,229))
  $h   = $bmp.GetHicon()
  $ico = [System.Drawing.Icon]::FromHandle($h)
  $fs  = [System.IO.File]::Open($iconPath, [System.IO.FileMode]::Create)
  $ico.Save($fs); $fs.Close(); $gfx.Dispose(); $bmp.Dispose()
}

# --- 6) Write a known-good Tauri v1 config (tauri.conf.json) ---
Info "Writing tauri.conf.json (Tauri v1)..."
$tauriConfPath = Join-Path $srcTauri 'tauri.conf.json'
$tauriJson = @'
{
  "$schema": "https://schema.tauri.app/config/1",
  "build": {
    "beforeDevCommand": "npm install --prefix ../client && npm run dev --prefix ../client",
    "beforeBuildCommand": "npm install --prefix ../client && npm run build --prefix ../client",
    "devPath": "http://localhost:5173",
    "distDir": "../client/dist"
  },
  "package": {
    "productName": "Gridiron Desktop",
    "version": "0.1.0"
  },
  "tauri": {
    "allowlist": {
      "all": true,
      "shell": {
        "all": false,
        "sidecar": true
      }
    },
    "bundle": {
      "active": true,
      "identifier": "com.gridiron.desktop",
      "targets": ["msi"],
      "icon": ["icons/icon.ico"],
      "externalBin": ["bin/backend.exe"]
    },
    "windows": [
      {
        "title": "Gridiron Desktop",
        "width": 1200,
        "height": 800,
        "resizable": true
      }
    ]
  }
}
'@
Set-Content -Path $tauriConfPath -Value $tauriJson -Encoding UTF8

# --- 7) Ensure build.rs exists (needed by Tauri) ---
Info "Ensuring build.rs exists..."
$buildRs = @'
fn main() {
  tauri_build::build();
}
'@
Set-Content -Path (Join-Path $srcTauri 'build.rs') -Value $buildRs -Encoding UTF8

# --- 8) Write main.rs that starts the sidecar (safe to overwrite) ---
Info "Writing src-tauri/src/main.rs ..."
$srcDir = Join-Path $srcTauri 'src'
New-Item -ItemType Directory -Force -Path $srcDir | Out-Null
$mainRs = @'
#![cfg_attr(all(not(debug_assertions), target_os = "windows"), windows_subsystem = "windows")]

use std::collections::HashMap;
use tauri::api::process::{Command, CommandEvent};

#[tauri::command]
async fn start_backend(app: tauri::AppHandle) -> Result<(), String> {
    let mut envs = HashMap::new();
    envs.insert("BACKEND_PORT".to_string(), "8787".to_string());

    let (mut rx, _child) = Command::new_sidecar("backend")
        .map_err(|e| e.to_string())?
        .envs(envs)
        .spawn()
        .map_err(|e| e.to_string())?;

    tauri::async_runtime::spawn(async move {
        while let Some(event) = rx.recv().await {
            match event {
                CommandEvent::Stdout(line) => println!("[backend] {line}"),
                CommandEvent::Stderr(line) => eprintln!("[backend] {line}"),
                CommandEvent::Terminated(_code) => println!("[backend] terminated"),
                _ => {}
            }
        }
    });

    Ok(())
}

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let handle = app.handle();
            tauri::async_runtime::spawn(async move {
                let _ = start_backend(handle).await;
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![start_backend])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
'@
Set-Content -Path (Join-Path $srcDir 'main.rs') -Value $mainRs -Encoding UTF8

# --- 9) Reinstall frontend & desktop deps, then launch tauri dev ---
Info "Installing client dependencies (npm ci)..."
npm ci --prefix $client

Info "Installing desktop dependencies (npm ci)..."
npm ci --prefix $desktop

Info "Starting Tauri dev (this will also start Vite)..."
Push-Location $desktop
try {
  npm run tauri:dev
} finally {
  Pop-Location
}
