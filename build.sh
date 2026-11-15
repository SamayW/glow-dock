#!/bin/zsh
# Assembles the one-file "Install Glow Dock.command" into dist/.
# Needs the Xcode Command Line Tools (swiftc) and the Shortcuts CLI.
set -e
cd "${0:A:h}"
mkdir -p build dist
CONF=projects.conf; [ -f $CONF ] || CONF=projects.example.conf
DL=downloads.conf; [ -f $DL ] || DL=downloads.example.conf
# 1. universal icon tool
for arch in arm64 x86_64; do swiftc -O -target $arch-apple-macos13 src/dockglow.swift -o build/dg-$arch; done
lipo -create build/dg-arm64 build/dg-x86_64 -output build/dockglow
codesign -s - -f build/dockglow
# 2. sign the shortcuts so they import on any Mac
for f in shortcuts/*.shortcut; do shortcuts sign --mode anyone --input "$PWD/$f" --output "$PWD/build/${f:t}"; done
# 3. assemble
OUT="dist/Install Glow Dock.command"
{
  awk -v conf="$CONF" -v dl="$DL" '/^@@PROJECTS@@$/{while((getline l < conf)>0) if (l !~ /^#/) print l; next} /^@@DLEXTRA@@$/{while((getline l < dl)>0) if (l !~ /^#/) print l; next} {print}' src/installer-head.zsh
  print -r -- ""
  print -r -- "# ── embedded payloads (don't edit) ──"
  print -r -- "DOCKGLOW_B64='$(base64 -i build/dockglow)'"
  print -r -- "SC_CLIP='$(base64 -i "build/AirDrop Clipboard.shortcut")'"
  print -r -- "SC_SHOT='$(base64 -i "build/AirDrop Screenshot.shortcut")'"
  print -r -- "SC_FOCUS='$(base64 -i "build/Focus Everywhere.shortcut")'"
  cat src/installer-body.zsh
} > "$OUT"
chmod +x "$OUT"; zsh -n "$OUT"
echo "built $OUT (projects from $CONF)"
