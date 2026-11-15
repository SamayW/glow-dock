
say "Glow Dock installer"
mkdir -p "$T" "$B"/{Work,Social,Media,Devices,Projects} "$HOME/Pictures/Wallpapers"
cp ~/Library/Preferences/com.apple.dock.plist "$T/dock-backup-$(date +%Y%m%d-%H%M%S).plist" 2>/dev/null && say "Backed up your current Dock to $T"

# 1. icon tool (universal binary, embedded below)
print -r -- "$DOCKGLOW_B64" | base64 -D > "$T/dockglow"; chmod +x "$T/dockglow"; xattr -c "$T/dockglow" 2>/dev/null; codesign -s - -f "$T/dockglow" 2>/dev/null

# 2. stacks
app() { for p in "/Applications/$1.app" "/System/Applications/$1.app" "/System/Applications/Utilities/$1.app" "$HOME/Applications/$1.app" "/System/Library/CoreServices/Finder.app/Contents/Applications/$1.app"; do [ -d "$p" ] && { print -r -- "$p"; return; }; done; }
fill() { local dir="$B/$1"; shift; for n in "$@"; do local p=$(app "$n"); [ -n "$p" ] && ln -sfn "$p" "$dir/$n"; done; }
fill Work Terminal Docker Scope "Google Chrome" "Claude Science" Notes Calendar Reminders Freeform "System Settings"
fill Social WhatsApp Messages Mail FaceTime Contacts
fill Media Photos Spotify Music TV Podcasts Preview "Photo Booth" Wallflow Minecraft
fill Devices "iPhone Mirroring" Phone AirDrop Passwords Home Shortcuts
p=$(app FindMy); [ -n "$p" ] && ln -sfn "$p" "$B/Devices/Find My"
say "Stacks filled: Work, Social, Media, Devices"

# 3. Devices shortcuts (signed, embedded below) + launchers
SC=$(mktemp -d)
for n in "AirDrop Clipboard" "AirDrop Screenshot" "Focus Everywhere"; do
  osacompile -o "$B/Devices/$n.app" -e "open location \"shortcuts://run-shortcut?name=${n// /%20}\"" 2>/dev/null
  if ! shortcuts list 2>/dev/null | grep -qx "$n"; then
    case $n in "AirDrop Clipboard") b=$SC_CLIP;; "AirDrop Screenshot") b=$SC_SHOT;; *) b=$SC_FOCUS;; esac
    print -r -- "$b" | base64 -D > "$SC/$n.shortcut"; open "$SC/$n.shortcut"; NEED_ADD=1
  fi
done

# 4. Projects launchers (open in VS Code)
rm -rf "$B/Projects/"*.app
for row in "${PROJECTS[@]}"; do IFS='|' read -r n p s col <<< "$row"
  [ -e "$p" ] && osacompile -o "$B/Projects/$n.app" -e "do shell script \"open -a 'Visual Studio Code' \" & quoted form of \"$p\"" 2>/dev/null
done
[ -d "$DP" ] && ln -sfn "$DP" "$B/Projects/All Projects in Finder"
say "Projects stack: $(ls "$B/Projects" | grep -c '\.app$') projects found on this Mac"

# 5. icon list → draw everything
L="$T/icons.txt"; : > "$L"
for a in "Brave Browser|sat|FB6A3C" "Claude|white|E08B6B" "Visual Studio Code|sat|4AA8FF"; do IFS='|' read -r n m col <<< "$a"; p=$(app "$n"); [ -n "$p" ] && print -r -- "app|$p|$m|$col" >> "$L"; done
print -l -- "sym|$B/Work|command|A78BFA" "sym|$B/Social|bubble.left.and.bubble.right|5EEAD4" "sym|$B/Media|play|FDBA74" \
  "sym|$B/Devices|iphone|E2E8F0" "sym|$B/Projects|square.stack.3d.up|93C5FD" "sym|$DP|square.stack.3d.up|93C5FD" "sym|$HOME/Downloads|arrow.down|F0ABFC" \
  "sym|$B/Devices/AirDrop Clipboard.app|doc.on.clipboard|38BDF8" "sym|$B/Devices/AirDrop Screenshot.app|camera.viewfinder|38BDF8" "sym|$B/Devices/Focus Everywhere.app|moon|818CF8" >> "$L"
for row in "${PROJECTS[@]}"; do IFS='|' read -r n p s col <<< "$row"; print -r -- "sym|$B/Projects/$n.app|$s|$col" >> "$L"; done
for row in "${DL_FOLDERS[@]}"; do IFS='|' read -r n s col <<< "$row"; print -r -- "sym|$HOME/Downloads/$n|$s|$col" >> "$L"; done
mkdir -p ~/.config/git; touch ~/.config/git/ignore; grep -q 'Icon\[' ~/.config/git/ignore || printf 'Icon[\r]\n' >> ~/.config/git/ignore
cat > "$B/Reapply Dock Theme.command" <<'RE'
#!/bin/zsh
"$HOME/Library/Dock Stacks/.theme/dockglow" batch < "$HOME/Library/Dock Stacks/.theme/icons.txt"
rm -f "$(getconf DARWIN_USER_CACHE_DIR)com.apple.dock.iconcache"; killall Dock
RE
chmod +x "$B/Reapply Dock Theme.command"
say "Drawing icons…"
BLOCKED=$("$T/dockglow" batch < "$L" | grep BLOCKED)

# 6. wallpaper
"$T/dockglow" wallpaper "$HOME/Pictures/Wallpapers/Midnight Glow.png" >/dev/null && \
  osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$HOME/Pictures/Wallpapers/Midnight Glow.png\"" 2>/dev/null && say "Wallpaper set"

# 7. Dock layout + settings
u() { local p=${1// /%20}; print -r -- "file://$p/"; }
tile() { print -r -- "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$(u "$1")</string><key>_CFURLStringType</key><integer>15</integer></dict></dict><key>tile-type</key><string>file-tile</string></dict>"; }
stack() { print -r -- "<dict><key>tile-data</key><dict><key>arrangement</key><integer>$3</integer><key>displayas</key><integer>1</integer><key>showas</key><integer>2</integer><key>file-data</key><dict><key>_CFURLString</key><string>$(u "$1")</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>$2</string></dict><key>tile-type</key><string>directory-tile</string></dict>"; }
APPS=(); for n in "Brave Browser" Claude "Visual Studio Code"; do p=$(app "$n"); [ -n "$p" ] && APPS+=("$(tile "$p")"); done
defaults write com.apple.dock persistent-apps -array "${APPS[@]}"
defaults write com.apple.dock persistent-others -array "$(stack "$B/Work" Work 1)" "$(stack "$B/Social" Social 1)" "$(stack "$B/Media" Media 1)" "$(stack "$B/Devices" Devices 1)" \
  '<dict><key>tile-data</key><dict/><key>tile-type</key><string>small-spacer-tile</string></dict>' "$(stack "$B/Projects" Projects 1)" "$(stack "$HOME/Downloads" Downloads 2)"
defaults write com.apple.dock tilesize -int 56; defaults write com.apple.dock magnification -bool true; defaults write com.apple.dock largesize -int 92
defaults write com.apple.dock show-recents -bool false; defaults write com.apple.dock minimize-to-application -bool true; defaults write com.apple.dock mineffect -string scale
defaults write com.apple.dock autohide -bool false; defaults write com.apple.dock show-process-indicators -bool true
rm -f "$(getconf DARWIN_USER_CACHE_DIR)com.apple.dock.iconcache"; killall Dock
say "Dock rebuilt ✓"

# 8. anything you need to do
if [ -n "$BLOCKED" ]; then
  print -P "\n%F{214}! macOS blocked icons for:%f"; print -r -- "$BLOCKED" | sed 's/^BLOCKED /    /'
  print "  → Switch ON Terminal in the window that just opened (App Management),"
  print "    then double-click:  ~/Library/Dock Stacks/Reapply Dock Theme.command"
  open "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AppBundles"
fi
[ -n "${NEED_ADD:-}" ] && print -P "\n%F{214}!%f Click %BAdd Shortcut%b in each Shortcuts window that opened."
print -P "\n%F{147}Done.%f Your old Dock is saved in ~/Library/Dock Stacks/.theme/ if you want it back."
exit 0
