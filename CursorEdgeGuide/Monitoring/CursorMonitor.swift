import AppKit

final class CursorMonitor {
    var onCursorMoved: ((CGPoint) -> Void)?

    private var timer: Timer?

    func start() {
        let t = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.onCursorMoved?(NSEvent.mouseLocation)
        }
        // .common モードで追加することで、modal ループやドラッグ中でも動作する
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stop()
    }
}
