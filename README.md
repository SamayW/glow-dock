# Glow Dock

A one-file installer that turns the macOS Dock into a dark **glow-glass** set: matching app icons, themed stacks, a Midnight Glow wallpaper and Continuity shortcuts. Built for the same look as [Lumen](https://github.com/SamayW/lumen).

Designed and developed by **Samay Wadhwani**.

## What it sets up

- **Glow-glass icons** for Brave, Claude and VS Code (drawn from their real logos), plus every stack folder
- **Stacks:** Work · Social · Media · Devices | Projects · Downloads, opening as grids
- **Devices stack:** iPhone Mirroring, Phone, AirDrop, Find My, Passwords, Home, Shortcuts, plus 3 shortcuts (AirDrop Clipboard, AirDrop Screenshot, Focus Everywhere)
- **Projects stack:** one tile per project that opens it in VS Code
- **Downloads:** each sub-folder gets its own glow icon
- **Midnight Glow wallpaper**, rendered at the Mac's own resolution
- **Dock settings:** 56 pt icons, magnification, no recents, always visible
- It backs up the current Dock first and skips anything a Mac doesn't have. Safe to run again.

## Build the installer

Needs the Xcode Command Line Tools.

```sh
cp projects.example.conf projects.conf      # list your projects
cp downloads.example.conf downloads.conf    # optional: extra Downloads folders
./build.sh                                  # → dist/Install Glow Dock.command
```

`projects.conf` and `downloads.conf` stay on your Mac (they're in `.gitignore`).

## Install on a Mac

Double-click `dist/Install Glow Dock.command`. If macOS blocks it, run:

```sh
zsh "Install Glow Dock.command"
```

Two one-time steps the installer will point out:
- **App Management:** to put glow icons on Brave and VS Code, allow Terminal in Privacy & Security → App Management, then run `~/Library/Dock Stacks/Reapply Dock Theme.command`.
- **Shortcuts:** click **Add Shortcut** for each of the 3 shortcuts.

Apps re-apply their own icons when they update. Run `Reapply Dock Theme.command` again afterwards.

## Layout

| Path | What it is |
|---|---|
| `src/dockglow.swift` | Draws the glow-glass icons and the wallpaper (universal binary) |
| `src/installer-head.zsh` | Installer config; the project lists are filled in at build time |
| `src/installer-body.zsh` | Installer steps: stacks, shortcuts, icons, wallpaper, Dock |
| `shortcuts/` | The 3 Shortcuts, unsigned (signed at build time) |
| `build.sh` | Assembles the one-file installer |

## Credits

© 2026 Samay Wadhwani. All rights reserved.
