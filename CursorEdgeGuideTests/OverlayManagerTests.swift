import XCTest
@testable import CursorEdgeGuide

// Integration tests for OverlayManager.
//
// Tests are split into two groups:
//   - Always-run: work with any number of connected displays.
//   - Multi-screen: automatically skipped unless NSScreen.screens.count >= 2.
//     Connect a second display (or insert an HDMI dummy plug) to enable them.

final class OverlayManagerTests: XCTestCase {

    private var manager: OverlayManager!

    override func setUp() {
        super.setUp()
        manager = OverlayManager()
        manager.setup(screens: NSScreen.screens)
    }

    override func tearDown() {
        manager.setup(screens: [])   // hide & release all windows
        manager = nil
        super.tearDown()
    }

    // MARK: - Always-run tests

    func testSetup_windowCountMatchesScreenCount() {
        XCTAssertEqual(manager.windows.count, NSScreen.screens.count)
    }

    func testSetup_windowKeysMatchScreenIDs() {
        let expected = Set(NSScreen.screens.map { EdgeAnalyzer.screenID(for: $0) })
        XCTAssertEqual(Set(manager.windows.keys), expected)
    }

    func testSetup_calledTwice_createsNewWindowInstances() {
        let first = manager.windows
        manager.setup(screens: NSScreen.screens)
        for (id, window) in manager.windows {
            XCTAssertFalse(first[id] === window,
                           "Window for screen '\(id)' should be a new instance after re-setup")
        }
    }

    func testSetup_emptyScreenList_clearsWindowsAndSegments() {
        manager.setup(screens: [])
        XCTAssertTrue(manager.windows.isEmpty)
        XCTAssertTrue(manager.allSegments.isEmpty)
    }

    func testUpdate_cursorAtScreenCenter_allWindowsHidden() {
        guard let screen = NSScreen.screens.first else { return }
        manager.update(cursorPosition: CGPoint(x: screen.frame.midX, y: screen.frame.midY))
        XCTAssertTrue(manager.windows.values.allSatisfy { !$0.isVisible })
    }

    // Single-screen: no adjacent pairs, so no segments.
    func testSetup_singleScreen_producesNoSegments() throws {
        try XCTSkipUnless(NSScreen.screens.count == 1,
                          "This test is only relevant on single-screen machines")
        XCTAssertTrue(manager.allSegments.isEmpty)
    }

    // MARK: - Multi-screen tests (skip without a second display / dummy plug)

    func testSetup_multiScreen_producesAtLeastOneSegment() throws {
        try XCTSkipUnless(NSScreen.screens.count >= 2,
                          "Requires a second display (HDMI dummy plug)")
        XCTAssertFalse(manager.allSegments.isEmpty)
    }

    func testUpdate_cursorAtBoundary_showsWindowsOnBothAdjacentScreens() throws {
        try XCTSkipUnless(NSScreen.screens.count >= 2,
                          "Requires a second display (HDMI dummy plug)")

        let segment = try XCTUnwrap(manager.allSegments.first)
        // The segment midpoint sits exactly on the screen boundary (distance 0 from edge).
        let cursor = CGPoint(x: segment.rect.midX, y: segment.rect.midY)
        manager.update(cursorPosition: cursor)

        XCTAssertTrue(manager.windows[segment.fromScreenID]?.isVisible == true,
                      "Window for fromScreen '\(segment.fromScreenID)' should be visible")
        XCTAssertTrue(manager.windows[segment.toScreenID]?.isVisible == true,
                      "Window for toScreen '\(segment.toScreenID)' should be visible")
    }

    func testUpdate_cursorMovedAway_hidesAllWindowsAfterShowing() throws {
        try XCTSkipUnless(NSScreen.screens.count >= 2,
                          "Requires a second display (HDMI dummy plug)")

        // Show windows by placing cursor on the boundary.
        let segment = try XCTUnwrap(manager.allSegments.first)
        manager.update(cursorPosition: CGPoint(x: segment.rect.midX, y: segment.rect.midY))
        let anyShown = manager.windows.values.contains { $0.isVisible }
        XCTAssertTrue(anyShown, "Pre-condition: at least one window must be visible near boundary")

        // Move cursor to centre of first screen (well away from all edges).
        let screen = NSScreen.screens[0]
        manager.update(cursorPosition: CGPoint(x: screen.frame.midX, y: screen.frame.midY))
        XCTAssertTrue(manager.windows.values.allSatisfy { !$0.isVisible },
                      "All windows should be hidden when cursor is far from every edge")
    }

    func testSetup_calledAgain_hidesWindowsThatWereShowing() throws {
        try XCTSkipUnless(NSScreen.screens.count >= 2,
                          "Requires a second display (HDMI dummy plug)")

        // Show windows first.
        let segment = try XCTUnwrap(manager.allSegments.first)
        manager.update(cursorPosition: CGPoint(x: segment.rect.midX, y: segment.rect.midY))

        // Re-setup (simulates a display reconfiguration event).
        manager.setup(screens: NSScreen.screens)

        // Newly created windows must all start hidden.
        XCTAssertTrue(manager.windows.values.allSatisfy { !$0.isVisible },
                      "All windows should be hidden after re-setup")
    }

    func testSetup_calledAgain_recomputesSameSegmentCount() throws {
        try XCTSkipUnless(NSScreen.screens.count >= 2,
                          "Requires a second display (HDMI dummy plug)")

        let countBefore = manager.allSegments.count
        manager.setup(screens: NSScreen.screens)
        XCTAssertEqual(manager.allSegments.count, countBefore)
    }
}
