# Feature Status

**Last Updated:** 2026-10-15 (initial v1 implementation, not yet hand-checked)

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
| Hotkey toggle | dev | Global Control-Option-Command-H turns all effects on or off via Carbon RegisterEventHotKey. | Carbon | Key combination is fixed. | Sources/CursorHalo/HotKeyRegistration.swift |
| Menu bar controls | dev | Status item with master toggle, per-effect toggles, size, color, launch at login, quit. | AppKit | Launch at login works only from the bundled app. | Sources/CursorHalo/MenuController.swift |
| Persistent settings | dev | Settings saved to UserDefaults; unreadable data falls back to defaults. | Foundation | None known. | Sources/CursorHaloCore/Settings.swift |
| App bundling | dev | scripts/bundle.sh builds an ad-hoc signed CursorHalo.app (LSUIElement). | codesign | Ad-hoc signature only. | scripts/bundle.sh |
