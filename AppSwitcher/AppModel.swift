import AppKit
internal import Combine

struct AppItem: Identifiable {
    let id = UUID()
    let app: NSRunningApplication
    let name: String
    let icon: NSImage
}

class AppStore: ObservableObject {
    @Published var apps: [AppItem] = []
    
    init() {
        fetchApps()
    }
    
    func fetchApps() {
        // 獲取所有正在運行的 App
        let runningApps = NSWorkspace.shared.runningApplications
        
        self.apps = runningApps
            .filter { $0.activationPolicy == .regular } // 只保留一般應用程式 (排除系統後台)
            .compactMap { app in
                // 確保有圖示和名稱
                guard let name = app.localizedName,
                      let icon = app.icon else { return nil }
                return AppItem(app: app, name: name, icon: icon)
            }
            // 限制數量以免圓圈太擠 (例如最多顯示 12 個)
            .prefix(12).map { $0 }
    }
    
    func switchApp(to item: AppItem) {
        // 檢查系統版本是否為 macOS 14.0 (Sonoma) 或更新
        if #available(macOS 14.0, *) {
            // 新式寫法：告訴系統「我現在要把焦點讓給這個 App」
            NSApp.yieldActivation(to: item.app)
        } else {
            // 舊式寫法：適用於 macOS 13 或更舊的版本
            item.app.activate(options: .activateIgnoringOtherApps)
        }
    }
}
