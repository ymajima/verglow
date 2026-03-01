import AppKit

struct EdgeAnalyzer {
    static let proximityThreshold: CGFloat = 8.0
    private static let edgeTolerance: CGFloat = 2.0

    static func screenID(for screen: NSScreen) -> String {
        if let displayID = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            return String(displayID)
        }
        return screen.localizedName
    }

    // 各ディスプレイペアの隣接境界（隣接部分のみ）を EdgeSegment として生成する
    static func computeEdgeSegments(screens: [NSScreen]) -> [EdgeSegment] {
        var segments: [EdgeSegment] = []

        for i in 0..<screens.count {
            for j in (i + 1)..<screens.count {
                let a = screens[i]
                let b = screens[j]
                if let segment = adjacentSegment(
                    frameA: a.frame, idA: screenID(for: a),
                    frameB: b.frame, idB: screenID(for: b)
                ) {
                    segments.append(segment)
                }
            }
        }

        return segments
    }

    // トリガー：カーソルがいずれかのディスプレイの任意の辺に 8px 以内に近接したとき、
    // 全隣接セグメントを返す（どの辺がトリガーになったかは問わない）。
    static func activeSegments(
        at point: CGPoint,
        screens: [NSScreen],
        from segments: [EdgeSegment]
    ) -> [EdgeSegment] {
        let t = proximityThreshold
        let triggered = screens.contains { screen in
            let f = screen.frame
            let nearLeft   = abs(point.x - f.minX) <= t && point.y >= f.minY && point.y <= f.maxY
            let nearRight  = abs(point.x - f.maxX) <= t && point.y >= f.minY && point.y <= f.maxY
            let nearBottom = abs(point.y - f.minY) <= t && point.x >= f.minX && point.x <= f.maxX
            let nearTop    = abs(point.y - f.maxY) <= t && point.x >= f.minX && point.x <= f.maxX
            return nearLeft || nearRight || nearBottom || nearTop
        }
        return triggered ? segments : []
    }

    // MARK: - Private

    private static func adjacentSegment(
        frameA: CGRect, idA: String,
        frameB: CGRect, idB: String
    ) -> EdgeSegment? {
        // A が B の左側
        if abs(frameA.maxX - frameB.minX) < edgeTolerance,
           let (minY, maxY) = verticalOverlap(frameA, frameB) {
            let rect = CGRect(x: frameA.maxX - 1, y: minY, width: 2, height: maxY - minY)
            return EdgeSegment(rect: rect, fromScreenID: idA, toScreenID: idB)
        }
        // A が B の右側
        if abs(frameB.maxX - frameA.minX) < edgeTolerance,
           let (minY, maxY) = verticalOverlap(frameA, frameB) {
            let rect = CGRect(x: frameB.maxX - 1, y: minY, width: 2, height: maxY - minY)
            return EdgeSegment(rect: rect, fromScreenID: idB, toScreenID: idA)
        }
        // A の上に B （A.maxY ≈ B.minY）
        if abs(frameA.maxY - frameB.minY) < edgeTolerance,
           let (minX, maxX) = horizontalOverlap(frameA, frameB) {
            let rect = CGRect(x: minX, y: frameA.maxY - 1, width: maxX - minX, height: 2)
            return EdgeSegment(rect: rect, fromScreenID: idA, toScreenID: idB)
        }
        // A の下に B （B.maxY ≈ A.minY）
        if abs(frameB.maxY - frameA.minY) < edgeTolerance,
           let (minX, maxX) = horizontalOverlap(frameA, frameB) {
            let rect = CGRect(x: minX, y: frameB.maxY - 1, width: maxX - minX, height: 2)
            return EdgeSegment(rect: rect, fromScreenID: idB, toScreenID: idA)
        }
        return nil
    }

    private static func verticalOverlap(_ a: CGRect, _ b: CGRect) -> (CGFloat, CGFloat)? {
        let minY = max(a.minY, b.minY)
        let maxY = min(a.maxY, b.maxY)
        return minY < maxY ? (minY, maxY) : nil
    }

    private static func horizontalOverlap(_ a: CGRect, _ b: CGRect) -> (CGFloat, CGFloat)? {
        let minX = max(a.minX, b.minX)
        let maxX = min(a.maxX, b.maxX)
        return minX < maxX ? (minX, maxX) : nil
    }
}
