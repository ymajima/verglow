import AppKit

final class OverlayManager {
    private var windows: [String: OverlayWindow] = [:]
    private var allSegments: [EdgeSegment] = []
    private var screens: [NSScreen] = []

    func setup(screens: [NSScreen]) {
        windows.values.forEach { $0.hide() }
        windows = [:]
        self.screens = screens

        for screen in screens {
            let id = EdgeAnalyzer.screenID(for: screen)
            windows[id] = OverlayWindow(screen: screen)
        }

        allSegments = EdgeAnalyzer.computeEdgeSegments(screens: screens)
    }

    func update(cursorPosition: CGPoint) {
        let active = EdgeAnalyzer.activeSegments(at: cursorPosition, screens: screens, from: allSegments)

        guard !active.isEmpty else {
            windows.values.forEach { $0.hide() }
            return
        }

        // from / to 両方のウィンドウに描画し、境界線が両サイドで確実に表示されるようにする
        var segmentsByScreen: [String: [EdgeSegment]] = [:]
        for segment in active {
            segmentsByScreen[segment.fromScreenID, default: []].append(segment)
            if !segment.toScreenID.isEmpty {
                segmentsByScreen[segment.toScreenID, default: []].append(segment)
            }
        }

        for (screenID, window) in windows {
            if let segments = segmentsByScreen[screenID] {
                window.show(segments: segments)
            } else {
                window.hide()
            }
        }
    }
}
