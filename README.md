# Cursor Halo

A tiny menu bar app for macOS that makes your mouse pointer easy to see. Handy for screen sharing, recordings, presentations, or just finding the cursor on a big display.

## Features

- **Highlight circle:** a soft colored circle that follows the pointer on every screen
- **Click ripple:** a ring expands from each click, with different colors for left and right clicks
- **Keyboard shortcut** to show or hide the highlight circle. The default is **Control+Option+Command+H**. You can record any other shortcut, including a key combo sent by a programmable mouse button
- **Size:** small, medium or large
- **Color:** yellow, red, blue, green or pink
- **Launch at login**
- Never gets in the way: the overlay ignores all clicks
- **No special permissions** needed: no Accessibility or Input Monitoring prompts

macOS already has a pointer size and color setting, and shake to locate, under **System Settings > Accessibility > Display > Pointer**. Cursor Halo adds the always-on highlight and click effects that macOS doesn't have.

## Requirements

- macOS 14 or later (developed on macOS 26, Apple Silicon)
- Xcode or the Xcode command line tools (Swift 6)

## Build and install

```sh
git clone https://github.com/masharratt/mac-cursor-halo.git
cd mac-cursor-halo
scripts/bundle.sh --install
```

`--install` copies the app to `/Applications/CursorHalo.app` and opens it. Without the flag, the app is left in `build/CursorHalo.app`.

Look for the dashed-circle icon in the menu bar.

## Change the shortcut

1. Click the menu bar icon and choose **Change Shortcut...**
2. Press the new key combination, or press your mouse button
3. The shortcut needs Command, Control or Option, or must be a function key (F1 to F20), so it can't steal plain typing

Cursor Halo takes the shortcut over system wide, so the same combination stops working in other apps. **Reset Shortcut** brings back Control+Option+Command+H.

## Run the tests

```sh
swift test
```
