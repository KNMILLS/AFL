param(
  [string]$ProjectRoot = (Resolve-Path ".").Path,
  [int]$MaxSizeMB = 10
)

$ErrorActionPreference = "Stop"

function New-Dir($p) {
  if (!(Test-Path $p)) { New-Item -ItemType Directory -Path $p -Force | Out-Null }
}

function Copy-IfExists($srcPath, $dstPath) {
  if (Test-Path $srcPath) {
    New-Dir (Split-Path $dstPath -Parent)
    Copy-Item $srcPath $dstPath -Recurse -Force
  }
}

function Copy-Robo($src, $dest, $files=@('*.*'), $excludeDirs=@(), $excludeFiles=@()) {
  if (!(Test-Path $src)) { return }
  New-Dir $dest
  $args = @($src, $dest)
  if ($files -and $files.Count -gt 0) { $args += $files } else { $args += '*.*' }
  $args += '/E','/R:1','/W:1','/NFL','/NDL','/NJH','/NJS','/NP','/XO'
  if ($excludeDirs.Count -gt 0) { $args += '/XD'; $args += $excludeDirs }
  if ($excludeFiles.Count -gt 0) { $args += '/XF'; $args += $excludeFiles }
  $p = Start-Process -FilePath robocopy -ArgumentList $args -NoNewWindow -PassThru -Wait
  # robocopy returns 0–7 as success
  if ($p.ExitCode -gt 7) { throw "robocopy failed ($($p.ExitCode)): $src -> $dest" }
}

$root   = (Resolve-Path $ProjectRoot).Path
$stage  = Join-Path $root "_upload_stage"
$outDir = Join-Path $root "upload"
$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$zip    = Join-Path $outDir "gridiron-upload-$stamp.zip"

Write-Host "Root: $root"
Write-Host "Staging: $stage"
Write-Host "Output: $zip"
Write-Host ""

# Clean staging/output
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Dir $stage
New-Dir $outDir

############################
# ROOT-LEVEL FILES
############################
Copy-IfExists (Join-Path $root "README.md")                 (Join-Path $stage "README.md")
Copy-IfExists (Join-Path $root ".gitignore")                (Join-Path $stage ".gitignore")
Copy-IfExists (Join-Path $root "requirements.txt")          (Join-Path $stage "requirements.txt")
Copy-IfExists (Join-Path $root "backend_runner.py")         (Join-Path $stage "backend_runner.py")

############################
# SCRIPTS
############################
if (Test-Path (Join-Path $root "scripts")) {
  Copy-Robo (Join-Path $root "scripts") (Join-Path $stage "scripts") @("*.ps1") @() @()
}

############################
# BACKEND (FastAPI) - app/
############################
if (Test-Path (Join-Path $root "app")) {
  Copy-Robo (Join-Path $root "app") (Join-Path $stage "app") @("*.*") @("__pycache__", ".pytest_cache", ".mypy_cache") @("*.pyc","*.pyo",".DS_Store","Thumbs.db")
}

############################
# CLIENT (Vite/React) - client/
############################
$client = Join-Path $root "client"
$stageClient = Join-Path $stage "client"
if (Test-Path $client) {
  New-Dir $stageClient
  # small config files
  @(
    "package.json","package-lock.json",
    "tsconfig.json","tsconfig.node.json",
    "vite.config.ts","vite.config.js",
    "index.html",".eslintrc.*",".prettierrc.*","README.md"
  ) | ForEach-Object {
    Get-ChildItem -Path (Join-Path $client $_) -ErrorAction SilentlyContinue | ForEach-Object {
      Copy-IfExists $_.FullName (Join-Path $stageClient $_.Name)
    }
  }
  # source folders ONLY (no node_modules / dist)
  if (Test-Path (Join-Path $client "src"))    { Copy-Robo (Join-Path $client "src")    (Join-Path $stageClient "src")    @("*.*") @() @() }
  if (Test-Path (Join-Path $client "public")) { Copy-Robo (Join-Path $client "public") (Join-Path $stageClient "public") @("*.*") @() @() }
}

############################
# DESKTOP (Tauri) - desktop/src-tauri
############################
$desktop = Join-Path $root "desktop"
$stageDesktop = Join-Path $stage "desktop"
if (Test-Path $desktop) {
  New-Dir $stageDesktop
  @("package.json","package-lock.json","README.md") | ForEach-Object {
    $p = Join-Path $desktop $_
    if (Test-Path $p) { Copy-IfExists $p (Join-Path $stageDesktop $_) }
  }
  $srcTauri = Join-Path $desktop "src-tauri"
  if (Test-Path $srcTauri) {
    # Copy all code/config but exclude build outputs
    Copy-Robo $srcTauri (Join-Path $stageDesktop "src-tauri") @("*.*") @("target",".tauri","binaries") @("*.pdb","*.dll","*.exe")
  }
}

############################
# .github workflows (optional but useful)
############################
$gh = Join-Path $root ".github"
if (Test-Path (Join-Path $gh "workflows")) {
  Copy-Robo (Join-Path $gh "workflows") (Join-Path $stage ".github\workflows") @("*.yml","*.yaml") @() @()
}

############################
# ZIP IT
############################
if (Test-Path $zip) { Remove-Item $zip -Force }
Write-Host "`nCompressing…"
Compress-Archive -Path (Join-Path $stage "*") -DestinationPath $zip -CompressionLevel Optimal

# Size check
$sizeBytes = (Get-Item $zip).Length
$sizeMB = [Math]::Round($sizeBytes / 1MB, 2)
Write-Host ("Created: {0}  ({1} MB)" -f $zip, $sizeMB)

if ($sizeMB -gt $MaxSizeMB) {
  Write-Warning "ZIP exceeds ${MaxSizeMB}MB (currently ${sizeMB}MB). Listing largest staged items:"
  Get-ChildItem $stage -Recurse -File | Sort-Object Length -Descending | Select-Object FullName, @{n='MB';e={[Math]::Round($_.Length/1MB,2)}} -First 15 | Format-Table -AutoSize
  Write-Host "`nYou can re-run after deleting large extras from _upload_stage, or add more excludes above."
} else {
  Write-Host "ZIP is under ${MaxSizeMB}MB. Ready to upload."
}

# Optional: open the folder
if (Test-Path $zip) {
  Write-Host "`nOpening upload folder…"
  Start-Process (Split-Path $zip -Parent)
}
