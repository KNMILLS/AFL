# 0) From the repo root
Set-Location 'C:\Users\KenGM\Downloads\gridiron-desktop-v1'

# 1) Make sure Git knows who you are (do once on this machine)
git config --global user.name  "Ken Mills"
git config --global user.email "17663922+KNMILLS@users.noreply.github.com"

# 2) Stage and commit your changes
git add -A
git commit -m "new changes"

# 3) Push to GitHub (origin should already be set)
git push -u origin main
