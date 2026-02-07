import SwiftUI

@main
struct AppSwitcherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                // 確保最底層有一個完全透明的視圖來「撐開」視窗空間
                .background(VisualEffectView().ignoresSafeArea())
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didFinishLaunchingNotification)) { _ in
                    if let window = NSApplication.shared.windows.first {
                        // 1. 去除所有標題列與邊框
                        window.styleMask = [.borderless]
                        
                        // 2. 核心：設定背景為完全透明
                        window.backgroundColor = .clear
                        window.isOpaque = false
                        
                        // 3. 解決鋸齒：關閉系統預設陰影（我們在 SwiftUI 裡自己畫了）
                        window.hasShadow = false
                        
                        // 4. 置頂與居中
                        window.level = .floating
                        window.center()
                        window.makeKeyAndOrderFront(nil)
                        
                        // 5. 確保內容可以穿透點擊（如果需要的話）
                        window.isMovableByWindowBackground = true
                        
                        window.contentView?.layer?.backgroundColor = .clear
                        window.contentView?.superview?.layer?.backgroundColor = .clear
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
    }
}
// 小工具：用來清除 SwiftUI 預設背景的 View
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        // 確保 NSView 本身不渲染任何背景
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
