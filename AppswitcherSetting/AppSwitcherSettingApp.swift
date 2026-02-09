import SwiftUI

@main
struct AppSwitcherSettingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow // (選用) 用於處理喚醒
    var body: some Scene {
        Window ("AppSwitcher 設定", id: "main_settings") {
            SettingsView()
                .frame(minWidth: 700, minHeight: 450)
                // ✨ 增加監聽：當 App 被啟動或點擊圖示變活躍時，強制打開視窗
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    openWindow(id: "main_settings")
                }
        }
        .windowStyle(.hiddenTitleBar) // 保持你想要的現代感外觀
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // ✨ 關鍵：最後一個視窗關閉時，直接結束 App
    }
    
    // (選用保險措施) 如果 App 已經在執行，再次被喚醒時，強制把視窗叫出來
    // 這通常由 SwiftUI WindowGroup 自動處理，但如果失敗，可以靠這個
    func applicationDidBecomeActive(_ notification: Notification) {
        // 如果你需要更強制的視窗喚醒邏輯，可以在這裡寫，但通常上面的 return true 就夠了
    }
}
