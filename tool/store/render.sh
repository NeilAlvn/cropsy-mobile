#!/usr/bin/env bash
# Renders every store screenshot in frame.html to tool/store/out/ at 1320x2868
# (App Store 6.9" — also accepted by Play Store).
set -euo pipefail
cd "$(dirname "$0")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
COUNT=$(grep -c "^  { id: '" frame.html)
mkdir -p out

for ((i = 0; i < COUNT; i++)); do
  id=$(sed -n "s/^  { id: '\([^']*\)'.*/\1/p" frame.html | sed -n "$((i + 1))p")
  "$CHROME" --headless --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --window-size=1320,2868 \
    --virtual-time-budget=4000 \
    --screenshot="out/$id.png" "file://$PWD/frame.html?i=$i" 2>/dev/null
  echo "out/$id.png"
done
