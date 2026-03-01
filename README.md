# Verglow

A macOS menu bar utility that illuminates display boundaries when your cursor nears the edge.

When you move the cursor within 8 px of any side of a display, Verglow draws a subtle glowing line along the shared boundary with the adjacent screen. The line fades in instantly and disappears the moment you move away — no configuration required.

---

## Features

- Draws a boundary line across the full shared edge between adjacent displays
- Triggers on any side of any display (left, right, top, bottom)
- Renders above the menu bar — visible even in stacked display arrangements
- Appears on both screens simultaneously for clear spatial reference
- Fade-in animation (150 ms); instant hide on departure
- Runs silently as a menu bar icon — no Dock icon, no App Switcher entry
- Zero configuration, no external dependencies

## Requirements

- macOS Tahoe (26.0) or later

## Build

Open `CursorEdgeGuide.xcodeproj` in Xcode and run, or build from the command line:

```bash
xcodebuild build -scheme CursorEdgeGuide -configuration Release
```

The built app appears in `build/Release/CursorEdgeGuide.app`.

## How it works

Verglow polls the cursor position at 60 fps. When the cursor comes within 8 px of any screen edge, it looks up the pre-computed boundary segments for adjacent display pairs and draws a translucent white line (8 px wide, 30 % opacity) along the overlapping portion of the shared edge — on both screens. The overlay window sits at `.screenSaver` level so it renders above the menu bar.

Display changes (connecting, disconnecting, rearranging) are detected automatically and boundary segments are recomputed on the fly.

## Roadmap

Phase B plans include display number overlays, colour and opacity customisation, adjustable proximity threshold, and a settings UI.
