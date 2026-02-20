import SwiftUI

@main
struct AppSwitcherSettingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow // (選用) 用於處理喚醒
    var body: some Scene {
        Window ("AppSwitcher Setting", id: "main_settings") {
            SettingsView()
                // ✨ 增加監聽：當 App 被啟動或點擊圖示變活躍時，強制打開視窗
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    openWindow(id: "main_settings")
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    // ✨ 修改 1：視窗關閉後，App 保持在後台，不結束程式
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return false
        }
        
        // ✨ 修改 2：只有當 App 真的要結束時（Cmd + Q），才去殺主程式
        func applicationWillTerminate(_ notification: Notification) {
            // 取得主程式 Bundle ID
            let mainAppID = "york.AppSwitcher"
            
            // 檢查結束的原因
            // 如果是因為 Cmd + Q 或使用者點選 Quit 產生的終止
            let runningMainApps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == mainAppID
            }
            
            for app in runningMainApps {
                app.terminate()
            }
        
        // 給系統一點點時間處理訊號（可選）
        Thread.sleep(forTimeInterval: 0.05)
    }
}
