
# dev-web.ps1 - Run backend at 8000 and Vite client at 5173 for browser dev
param(
  [int]$Port = 8000
)
$ErrorActionPreference = "Stop"

Write-Host "Starting backend (uvicorn) on port $Port..."
$backend = Start-Process -PassThru -NoNewWindow powershell -ArgumentList @("-NoProfile","-Command","python -m uvicorn app.main:app --app-dir backend --host 127.0.0.1 --port $Port --reload")

try {
  Push-Location client
  $env:VITE_API_BASE = "http://127.0.0.1:$Port/api"
  Write-Host "Starting Vite (VITE_API_BASE=$env:VITE_API_BASE) ..."
  npm run dev
} finally {
  if ($backend -and !$backend.HasExited) { Stop-Process -Id $backend.Id -Force }
  Pop-Location
}
