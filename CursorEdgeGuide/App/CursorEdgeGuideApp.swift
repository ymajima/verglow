import SwiftUI

@main
struct CursorEdgeGuideApp: App {
    @NSApplicationDelegateAdaptor(AppController.self) var appController

    var body: some Scene {
        // ウィンドウは表示しない。メニューバーと設定シーンのみ。
        Settings { EmptyView() }
    }
}
