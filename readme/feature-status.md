# Feature Status

**Last Updated:** 2026-10-15 (removed master switch; hotkey toggles highlight only)

## Status Legend

| Token | Meaning |
|-------|---------|
| `prod` | Live, verified, monitored. Real users. |
| `beta` | Feature-complete, under verification. Usable but not trusted. |
| `dev` | In development. Not verifiable end-to-end. |
| `stub` | Scaffold only. Returns placeholder. Not real. |
| `deprecated` | Still present, scheduled for removal. Do not build on. |

## Features

| Feature | Status | Description | Dependencies | Known Limitations | Location |
|---------|--------|-------------|--------------|-------------------|----------|
| Highlight circle | dev | Soft filled circle with a stronger ring edge follows the cursor on every screen and never intercepts clicks. | AppKit, Core Animation | Hidden on screens without the cursor. | Sources/CursorHalo/OverlayController.swift |
| Click ripple | dev | Ring expands and fades over 0.4s on left or right mouse down; right click uses the inverted color. | AppKit, Core Animation | Clicks are seen via event monitors, so none appear while secure input is active. | Sources/CursorHalo/OverlayController.swift |
| Hotkey toggle | dev | Global shortcut toggles the highlight circle only (default Control-Option-Command-H) via Carbon RegisterEventHotKey; no permission prompt. | Carbon | Combos already owned by another app's global hotkey are refused. | Sources/CursorHalo/HotKeyRegistration.swift |
| Change Shortcut | dev | Menu item opens a recorder window; accepts combos with Command, Control or Option, or any F1 to F20 key. Esc cancels; Reset restores the default. | AppKit, Carbon | Mouse button must send a key combo; bare keys are rejected. | Sources/CursorHalo/ShortcutRecorderWindow.swift |
| Menu bar controls | dev | Status item with highlight toggle (shows shortcut), ripple toggle, size, color, shortcut change/reset, launch at login, quit. | AppKit | Launch at login works only from the bundled app. | Sources/CursorHalo/MenuController.swift |
| Persistent settings | dev | Settings (including the toggle shortcut) saved to UserDefaults; older data without the shortcut loads the default and the removed master flag is ignored; unreadable data falls back to defaults. | Foundation | None known. | Sources/CursorHaloCore/Settings.swift |
| App bundling | dev | scripts/bundle.sh builds an ad-hoc signed CursorHalo.app (LSUIElement). | codesign | Ad-hoc signature only. | scripts/bundle.sh |
