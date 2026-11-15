#!/bin/zsh
# ─────────────────────────────────────────────────────────────
#  Glow Dock — one-file installer
#  Rebuilds the "Glow glass" Dock: icons, stacks, wallpaper,
#  Devices shortcuts and Dock settings. Safe to run again.
#  Double-click it, or run:  zsh "Install Glow Dock.command"
# ─────────────────────────────────────────────────────────────
set -u
B="$HOME/Library/Dock Stacks"; T="$B/.theme"; DP="$HOME/Desktop/Projects"
say() { print -P "%F{147}▸%f $*"; }

# ── EDIT ME: your projects (Name|path|SF Symbol|glow colour). Missing paths are skipped. ──
PROJECTS=(
@@PROJECTS@@
)
# Downloads sub-folders that get icons (folder|symbol|colour); missing ones are skipped
DL_FOLDERS=(
  "Audio|waveform|F0ABFC" "Data Exports|externaldrive|94A3B8" "Design Kits|paintpalette|F9A8D4"
  "Documents|doc.text|93C5FD" "Images|photo|5EEAD4" "Installers & Mods|shippingbox|FCD34D"
  "Photos|camera|FDBA74" "Scripts|chevron.left.forwardslash.chevron.right|A78BFA"
  "Spreadsheets & CSVs|tablecells|86EFAC" "Videos|film|F87171"
@@DLEXTRA@@
)
