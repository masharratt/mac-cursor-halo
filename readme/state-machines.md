# State Machines

**Last Updated:** 2026-10-15 (removed master switch; hotkey toggles highlight only)

## 1. Highlight Circle

**Source:** Sources/CursorHaloCore/EffectsState.swift:17, Settings.highlightEnabled

### States

| State | Meaning |
|-------|---------|
| Hidden | highlightEnabled is false. The circle is not drawn. The click ripple is unaffected. |
| Shown | highlightEnabled is true. The circle follows the cursor on its screen. |

### Transitions

| From | To | Trigger | Guard |
|------|----|---------|-------|
| Hidden | Shown | Menu "Highlight Circle" or hotkey | None |
| Shown | Hidden | Menu "Highlight Circle" or hotkey | None |

### Diagram

```mermaid
stateDiagram-v2
  Hidden --> Shown: toggle
  Shown --> Hidden: toggle
```

## 2. Shortcut Recorder

**Source:** Sources/CursorHalo/ShortcutRecorderWindow.swift, Sources/CursorHaloCore/HotKey.swift (ShortcutRecorder)

### States

| State | Meaning |
|-------|---------|
| Idle | No recorder window. The saved shortcut is registered. |
| Recording | Window open, current shortcut unregistered, waiting for a key press. |
| Rejected | Last press was invalid or already owned by another app. Message shown, still recording. |
| Saved | New shortcut registered and stored. Window closes, returns to Idle. |
| Cancelled | Esc or window closed. Old shortcut re-registered, returns to Idle. |

### Transitions

| From | To | Trigger | Guard |
|------|----|---------|-------|
| Idle | Recording | Menu "Change Shortcut…" | None |
| Recording | Saved | Key press | Passes validation and RegisterEventHotKey succeeds |
| Recording | Rejected | Key press | Fails validation or RegisterEventHotKey fails |
| Rejected | Recording | Next key press | None |
| Recording | Cancelled | Esc or close button | None |
| Rejected | Cancelled | Esc or close button | None |

### Diagram

```mermaid
stateDiagram-v2
  Idle --> Recording: Change Shortcut
  Recording --> Saved: valid and registered
  Recording --> Rejected: invalid or taken
  Rejected --> Recording: next key
  Recording --> Cancelled: Esc or close
  Rejected --> Cancelled: Esc or close
  Saved --> Idle
  Cancelled --> Idle
```
