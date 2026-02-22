internal import AppKit
internal import Combine
import CoreGraphics

struct AppItem: Identifiable {
    let id = UUID()
    let app: NSRunningApplication
    let name: String
    let icon: NSImage
}

class AppStore: ObservableObject {
    @Published var apps: [AppItem] = []
    
    init() { fetchApps() }
    
    func fetchApps() {
        // 1. 直接獲取系統中所有執行中的 App
        let runningApps = NSWorkspace.shared.runningApplications
        
        self.apps = runningApps
            // 規則 1: 只抓取標準的應用程式 (有 Dock 圖示的)，這步很重要，不然會抓到一堆系統背景常駐程式
            .filter { $0.activationPolicy == .regular }
            // 規則 2: 過濾掉當前的 App (AppSwitcher 自己)，避免切換器出現在選單中
            .filter { $0.processIdentifier != NSRunningApplication.current.processIdentifier }
            .compactMap { app in
                guard let name = app.localizedName, let icon = app.icon else { return nil }
                return AppItem(app: app, name: name, icon: icon)
            }
            // 限制最多顯示 12 個
            .prefix(12).map { $0 }
    }
    
    func switchApp(to item: AppItem) {
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: item.app)
//            item.app.activate(options: .activateIgnoringOtherApps)
            item.app.activate()
        } else {
            item.app.activate(options: .activateIgnoringOtherApps)
        }
        
        if let bundleURL = item.app.bundleURL {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true // 確保它被啟動並變成活躍狀態
            
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open app to simulate dock click: \(error.localizedDescription)")
                }
            }
        }
    }
}
