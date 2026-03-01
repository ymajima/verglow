import XCTest
@testable import CursorEdgeGuide

// MARK: - computeEdgeSegments

final class ComputeEdgeSegmentsTests: XCTestCase {

    // MARK: Degenerate inputs

    func testNoFrames_returnsEmpty() {
        XCTAssertTrue(EdgeAnalyzer.computeEdgeSegments(frames: []).isEmpty)
    }

    func testSingleFrame_returnsEmpty() {
        let frames = [(rect: CGRect(x: 0, y: 0, width: 1920, height: 1080), id: "A")]
        XCTAssertTrue(EdgeAnalyzer.computeEdgeSegments(frames: frames).isEmpty)
    }

    // MARK: Side-by-side layout

    func testSideBySide_ALeftOfB_producesOneSegment() {
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let segments = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ])
        XCTAssertEqual(segments.count, 1)
    }

    func testSideBySide_segmentIsVertical() {
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        // Vertical segment: height > width
        XCTAssertGreaterThan(seg.rect.height, seg.rect.width)
    }

    func testSideBySide_segmentRect() {
        // A: x 0–1920, B: x 1920–3840, both y 0–1080
        // Expected: x=1919, y=0, w=2, h=1080
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        XCTAssertEqual(seg.rect, CGRect(x: 1919, y: 0, width: 2, height: 1080))
    }

    func testSideBySide_orderIndependent() {
        // Passing B before A should yield the same geometry
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let seg1 = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        let seg2 = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: b, id: "B"), (rect: a, id: "A")
        ]).first!
        XCTAssertEqual(seg1.rect, seg2.rect)
    }

    // MARK: Stacked layout

    func testStacked_BAboveA_producesOneSegment() {
        // A at bottom (y 0–1080), B directly above (y 1080–2160)
        let a = CGRect(x: 0, y:    0, width: 1920, height: 1080)
        let b = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let segments = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ])
        XCTAssertEqual(segments.count, 1)
    }

    func testStacked_segmentIsHorizontal() {
        let a = CGRect(x: 0, y:    0, width: 1920, height: 1080)
        let b = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        XCTAssertGreaterThan(seg.rect.width, seg.rect.height)
    }

    func testStacked_segmentRect() {
        // Expected: x=0, y=1079, w=1920, h=2
        let a = CGRect(x: 0, y:    0, width: 1920, height: 1080)
        let b = CGRect(x: 0, y: 1080, width: 1920, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        XCTAssertEqual(seg.rect, CGRect(x: 0, y: 1079, width: 1920, height: 2))
    }

    // MARK: Partial overlap

    func testPartialVerticalOverlap_segmentClippedToOverlap() {
        // A: full-height 0–1080, B: offset vertically, overlapping y 200–880
        let a = CGRect(x: 0,    y:   0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 200, width: 1920, height:  680)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        XCTAssertEqual(seg.rect.minY, 200)
        XCTAssertEqual(seg.rect.maxY, 880)
    }

    func testPartialHorizontalOverlap_segmentClippedToOverlap() {
        // A: full-width 0–1920, B: offset horizontally, overlapping x 300–1620
        let a = CGRect(x:   0, y:    0, width: 1920, height: 1080)
        let b = CGRect(x: 300, y: 1080, width: 1320, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).first!
        XCTAssertEqual(seg.rect.minX, 300)
        XCTAssertEqual(seg.rect.maxX, 1620)
    }

    func testNoOverlap_adjacentButMisaligned_returnsEmpty() {
        // A and B touch at the right edge but have no vertical overlap
        let a = CGRect(x: 0,    y:    0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 1200, width: 1920, height: 1080)
        let segments = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ])
        XCTAssertTrue(segments.isEmpty)
    }

    // MARK: Gap / tolerance

    func testGapBeyondTolerance_returnsEmpty() {
        // 3 px gap — exceeds the 2 px edgeTolerance
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1923, y: 0, width: 1920, height: 1080)
        XCTAssertTrue(EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).isEmpty)
    }

    func testGapWithinTolerance_producesSegment() {
        // 1 px gap — within tolerance
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1921, y: 0, width: 1920, height: 1080)
        XCTAssertEqual(EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).count, 1)
    }

    func testGapAtExactTolerance_returnsEmpty() {
        // Exactly 2 px gap — edgeTolerance uses strict <, so this should not match
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1922, y: 0, width: 1920, height: 1080)
        XCTAssertTrue(EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B")
        ]).isEmpty)
    }

    // MARK: Three displays

    func testThreeScreensSideBySide_producesTwoSegments() {
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let c = CGRect(x: 3840, y: 0, width: 1920, height: 1080)
        let segments = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B"), (rect: c, id: "C")
        ])
        XCTAssertEqual(segments.count, 2)
    }

    func testThreeScreens_nonAdjacentPairProducesNoExtraSegment() {
        // A and C are not adjacent; only A-B and B-C boundaries should appear
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let c = CGRect(x: 3840, y: 0, width: 1920, height: 1080)
        let segments = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "A"), (rect: b, id: "B"), (rect: c, id: "C")
        ])
        // A-C boundary does not exist (they don't touch)
        let hasAC = segments.contains { ($0.fromScreenID == "A" && $0.toScreenID == "C") ||
                                        ($0.fromScreenID == "C" && $0.toScreenID == "A") }
        XCTAssertFalse(hasAC)
    }

    // MARK: Screen IDs

    func testScreenIDs_correctlyAssigned() {
        let a = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let b = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        let seg = EdgeAnalyzer.computeEdgeSegments(frames: [
            (rect: a, id: "LEFT"), (rect: b, id: "RIGHT")
        ]).first!
        let ids = Set([seg.fromScreenID, seg.toScreenID])
        XCTAssertEqual(ids, ["LEFT", "RIGHT"])
    }
}

// MARK: - activeSegments

final class ActiveSegmentsTests: XCTestCase {

    private let screen = CGRect(x: 0, y: 0, width: 1920, height: 1080)
    private let dummySegments = [EdgeSegment(rect: .zero, fromScreenID: "A", toScreenID: "B")]

    // MARK: Not triggered

    func testCursorAtCenter_notTriggered() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 960, y: 540),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testCursorNearLeftEdge_butOutsideYRange_notTriggered() {
        // x=4 is within threshold, but y=1090 is above the screen
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 4, y: 1090),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testCursorNearTopEdge_butOutsideXRange_notTriggered() {
        // y=1072 is within threshold, but x=1930 is beyond the screen
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 1930, y: 1072),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testCursorJustOutsideThreshold_notTriggered() {
        // x=9 → distance from left edge = 9 > 8
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 9, y: 540),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: Triggered — each edge

    func testCursorNearLeftEdge_triggered() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 4, y: 540),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }

    func testCursorNearRightEdge_triggered() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 1916, y: 540),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }

    func testCursorNearTopEdge_triggered() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 960, y: 1072),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }

    func testCursorNearBottomEdge_triggered() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 960, y: 4),
            frames: [screen],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }

    // MARK: Threshold boundary

    func testCursorAtExactThreshold_triggered() {
        // Distance exactly == proximityThreshold (<=), should trigger
        let t = EdgeAnalyzer.proximityThreshold
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: t, y: 540),          // distance from left = t
            frames: [screen],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }

    func testCursorOnePointBeyondThreshold_notTriggered() {
        let t = EdgeAnalyzer.proximityThreshold
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: t + 1, y: 540),      // distance from left = t+1
            frames: [screen],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: Return value

    func testTriggered_returnsAllPassedSegments() {
        let segs = [
            EdgeSegment(rect: CGRect(x: 1919, y: 0, width: 2, height: 1080), fromScreenID: "A", toScreenID: "B"),
            EdgeSegment(rect: CGRect(x: 3839, y: 0, width: 2, height: 1080), fromScreenID: "B", toScreenID: "C"),
        ]
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 4, y: 540),
            frames: [screen],
            from: segs
        )
        XCTAssertEqual(result.count, 2)
    }

    func testTriggered_butNoSegments_returnsEmpty() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 4, y: 540),
            frames: [screen],
            from: []
        )
        XCTAssertTrue(result.isEmpty)
    }

    func testNotTriggered_withNoScreens_returnsEmpty() {
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 0, y: 0),
            frames: [],
            from: dummySegments
        )
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: Multi-display: triggered by any screen

    func testCursorNearSecondScreen_triggered() {
        // Two side-by-side screens; cursor near the right edge of the second screen
        let screenA = CGRect(x: 0,    y: 0, width: 1920, height: 1080)
        let screenB = CGRect(x: 1920, y: 0, width: 1920, height: 1080)
        // Right edge of B is at x=3840; cursor at x=3835 → distance 5 < 8
        let result = EdgeAnalyzer.activeSegments(
            at: CGPoint(x: 3835, y: 540),
            frames: [screenA, screenB],
            from: dummySegments
        )
        XCTAssertFalse(result.isEmpty)
    }
}
