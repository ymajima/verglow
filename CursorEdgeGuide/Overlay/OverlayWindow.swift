import AppKit

// MARK: - OverlayWindow

final class OverlayWindow: NSWindow {
    private var overlayView: OverlayView!
    private var fadeTimer: Timer?

    init(screen: NSScreen) {
        // defer: true で初期化時の layout 競合を回避
        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: true
        )

        let view = OverlayView(frame: .zero)
        view.autoresizingMask = [.width, .height]
        overlayView = view

        isOpaque = false
        backgroundColor = .clear
        ignoresMouseEvents = true
        level = .screenSaver
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        hasShadow = false
        isReleasedWhenClosed = false

        contentView = view
    }

    func show(segments: [EdgeSegment]) {
        overlayView.update(segments: segments, windowOrigin: frame.origin)
        guard !isVisible else { return }
        alphaValue = 0
        orderFrontRegardless()
        startFadeIn()
    }

    func hide() {
        fadeTimer?.invalidate()
        fadeTimer = nil
        guard isVisible else { return }
        orderOut(nil)
    }

    // MARK: - Private

    // NSAnimationContext の代わりにタイマーで alphaValue を操作し layout 再帰を回避
    private func startFadeIn() {
        fadeTimer?.invalidate()
        var progress: CGFloat = 0
        let step: CGFloat = 1.0 / (0.15 * 60.0)
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] t in
            guard let self else { t.invalidate(); return }
            progress = min(progress + step, 1.0)
            self.alphaValue = progress
            if progress >= 1.0 {
                t.invalidate()
                self.fadeTimer = nil
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        fadeTimer = timer
    }
}

// MARK: - OverlayView

private final class OverlayView: NSView {
    private var segments: [EdgeSegment] = []
    private var windowOrigin: CGPoint = .zero

    func update(segments: [EdgeSegment], windowOrigin: CGPoint) {
        self.segments = segments
        self.windowOrigin = windowOrigin
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        context.setStrokeColor(NSColor.white.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(8)

        for segment in segments {
            // スクリーン座標 → ウィンドウローカル座標
            let localMinX = segment.rect.minX - windowOrigin.x
            let localMaxX = segment.rect.maxX - windowOrigin.x
            let localMinY = segment.rect.minY - windowOrigin.y
            let localMaxY = segment.rect.maxY - windowOrigin.y
            let isVertical = segment.rect.height > segment.rect.width

            context.beginPath()
            if isVertical {
                let x = (localMinX + localMaxX) / 2
                context.move(to: CGPoint(x: x, y: localMinY))
                context.addLine(to: CGPoint(x: x, y: localMaxY))
            } else {
                let y = (localMinY + localMaxY) / 2
                context.move(to: CGPoint(x: localMinX, y: y))
                context.addLine(to: CGPoint(x: localMaxX, y: y))
            }
            context.strokePath()
        }
    }
}
