# 0) From the repo root
Set-Location 'C:\Users\KenGM\Downloads\gridiron-desktop-v1'

# 1) Ensure Git identity (only needed once)
git config --global user.name  "Ken Mills"
git config --global user.email "17663922+KNMILLS@users.noreply.github.com"

# 2) Create/overwrite a proper .gitignore so junk won't be tracked again
$gitIgnore = @"
# Node / Vite
client/node_modules/
desktop/node_modules/
client/dist/
.vite/
npm-debug.log*
yarn-error.log*

# Rust / Tauri
desktop/src-tauri/target/
desktop/src-tauri/binaries/
desktop/src-tauri/gen/
*.pdb

# Python
.venv/
venv/
__pycache__/
*.pyc
dist/
build/
*.spec

# OS / editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Executables
*.exe
"@
Set-Content -Path .gitignore -Value $gitIgnore -Encoding utf8

# 3) Untrack anything that was previously staged (but keep files on disk)
git rm -r --cached client/node_modules desktop/node_modules desktop/src-tauri/target dist build .venv 2>$null
git rm -r --cached desktop/src-tauri/binaries 2>$null
git rm -r --cached client/dist 2>$null

# (Optional) if a nested package got into node_modules previously:
git rm -r --cached 'client/node_modules/gridiron-desktop' 2>$null

# 4) Start a brand-new orphan branch (no history), commit the cleaned working tree
git checkout --orphan clean-main
git add -A
git commit -m "chore: clean initial commit (source only, no build artifacts)"

# 5) Replace your local main with this clean history
git branch -D main 2>$null
git branch -m main

# 6) Make sure the remote exists (shows 'origin' pointing at your GitHub repo)
git remote -v
# If you see nothing, add it (adjust URL if needed):
# git remote add origin https://github.com/KNMILLS/AFL.git

# 7) Force-push this clean main to GitHub
git push -u --force origin main
