import AppKit

final class AppController: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var cursorMonitor: CursorMonitor?
    private var overlayManager: OverlayManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Dock・App Switcher から非表示
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupMonitoring()
    }

    // MARK: - Private

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.image = NSImage(
            systemSymbolName: "display.2",
            accessibilityDescription: "CursorEdgeGuide"
        )

        let menu = NSMenu()
        menu.addItem(
            withTitle: "CursorEdgeGuide を終了",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        statusItem?.menu = menu
    }

    private func setupMonitoring() {
        let manager = OverlayManager()
        manager.setup(screens: NSScreen.screens)
        overlayManager = manager

        let monitor = CursorMonitor()
        monitor.onCursorMoved = { [weak self] position in
            self?.overlayManager?.update(cursorPosition: position)
        }
        monitor.start()
        cursorMonitor = monitor

        // スクリーン構成変更を検知してオーバーレイを再構築
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    @objc private func screensDidChange() {
        overlayManager?.setup(screens: NSScreen.screens)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
