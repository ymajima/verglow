# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**CursorEdgeGuide** is a macOS menu bar utility that shows subtle visual indicators when the cursor approaches the boundary between displays in a multi-monitor setup. It runs as an accessory app (hidden from Dock and App Switcher), visible only as a menu bar icon.

- **Language:** Swift, macOS 26.0+ (Tahoe)
- **Bundle ID:** `net.cyberplatoon.CursorEdgeGuide`
- **No external dependencies** — AppKit, SwiftUI (entry point only), CoreGraphics

## Build & Run

```bash
cd CursorEdgeGuide/

# Build (Debug)
xcodebuild build -scheme CursorEdgeGuide -configuration Debug

# Build (Release)
xcodebuild build -configuration Release

# Run tests
xcodebuild test -scheme CursorEdgeGuide
```

Open `CursorEdgeGuide.xcodeproj` in Xcode for normal development. The built `.app` appears in `build/Release/` or `build/Debug/`.

## Architecture

Data flows in one direction through five layers:

```
CursorMonitor (60 FPS polling)
    → AppController (orchestrator)
    → EdgeAnalyzer (pure logic: adjacency & proximity)
    → OverlayManager (one NSWindow per display)
    → OverlayWindow / OverlayView (Core Graphics rendering)
```

**Key behaviors:**
- Cursor proximity threshold: **8 px** from any display edge
- When triggered, **all** boundary segments across the entire display configuration appear simultaneously (not just the nearest one)
- Overlay shows on **both** adjacent screens for each boundary
- Fade-in: 150 ms timer-based (avoids `NSAnimationContext` layout recursion); hide is immediate
- Window level: `.screenSaver` — renders above the menu bar

**`EdgeAnalyzer.swift`** is the core logic layer. It is intentionally AppKit-independent (only uses `CGRect`/`CGPoint` geometry). It computes which screen pairs are adjacent (touch within 2 px tolerance) and which boundary segments are within the proximity threshold of the cursor.

**`OverlayWindow.swift`** uses `screen.frame` (full display area including menu bar) as the window frame. `OverlayView` converts screen-coordinate segment rects to window-local coordinates by subtracting `frame.origin`.

**`AppController.swift`** listens for `NSApplication.didChangeScreenParametersNotification` to recompute edge segments whenever displays are connected/disconnected/rearranged.

## Source Layout

```
CursorEdgeGuide/CursorEdgeGuide/
├── App/
│   ├── CursorEdgeGuideApp.swift   # @main SwiftUI entry; delegates to AppController
│   └── AppController.swift        # NSApplicationDelegate; wires all components
├── Core/
│   └── EdgeAnalyzer.swift         # Screen adjacency + cursor proximity logic
├── Model/
│   └── EdgeSegment.swift          # EdgeSegment { rect, fromScreenID, toScreenID }
├── Monitoring/
│   └── CursorMonitor.swift        # NSEvent.mouseLocation polled at 60 FPS
└── Overlay/
    ├── OverlayManager.swift        # One OverlayWindow per NSScreen; show/hide routing
    └── OverlayWindow.swift         # Borderless transparent window + OverlayView (CG drawing)
```

## Design Notes

- **Phase A (MVP):** Core edge detection and overlay rendering only. No settings UI, no customization.
- **Phase B (planned):** Settings UI, color/threshold customization, display number overlays, auto-hide timeout.
- `ARCHITECTURE.md` at the repo root contains detailed design documentation (written in Japanese).
