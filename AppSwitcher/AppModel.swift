internal import AppKit
import SwiftUI
internal import Combine
import CoreGraphics
internal import UniformTypeIdentifiers

struct AppItem: Identifiable {
    let id = UUID()
    let bundleID: String?
    let url: URL?
    let name: String
    let icon: NSImage
    let runningApp: NSRunningApplication?
}
class AppStore: ObservableObject {
    @Published var apps: [AppItem] = []
    @AppStorage("isUserSet", store: SharedConfig.defaults) var isUserSet: Bool = true
    private var customBundleIDs: [String] {
        get { SharedConfig.defaults.stringArray(forKey: "customAppList") ?? ["com.apple.Safari", "com.apple.Terminal"] }
        set { SharedConfig.defaults.set(newValue, forKey: "customAppList") }
    }
    
    init() { fetchApps() }

    func fetchApps() {
        if isUserSet {
            fetchCustomApps()
        } else {
            fetchRunningApps()
        }
    }
    
    // ➕ 新增 App (支援批量多選)
    func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application] // 只允許選 .app
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            // 先把目前的清單讀出來
            var list = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? [
                "com.apple.Safari", "com.apple.Terminal", "com.apple.systempreferences"
            ]
            
            var hasChanges = false // 用來標記這次有沒有真的加到新東西
            
            // 👇 關鍵修改 2：使用 panel.urls 迴圈處理每一個選中的 App
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier {
                    // 檢查是否已經在清單內，避免重複加入
                    if !list.contains(bid) {
                        list.append(bid)
                        hasChanges = true
                    }
                }
            }
            
            // 如果清單有變動，就存入 UserDefaults 並刷新畫面
            if hasChanges {
                SharedConfig.defaults.set(list, forKey: "customAppList")
                fetchCustomApps()
            }
        }
    }

    func removeApp(bundleID: String) {
        var list = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? []
        // 把符合這個 bundleID 的項目剔除
        list.removeAll { $0 == bundleID }
        
        SharedConfig.defaults.set(list, forKey: "customAppList")
        // 刪除後，立刻重新讀取並更新畫面
        fetchCustomApps()
    }
    
    private func fetchRunningApps() {
        let runningApps = NSWorkspace.shared.runningApplications
        
        self.apps = runningApps
            .filter { $0.activationPolicy == .regular }
            .filter { $0.processIdentifier != NSRunningApplication.current.processIdentifier }
            .compactMap { app in
                guard let name = app.localizedName, let icon = app.icon else { return nil }
                return AppItem(
                    bundleID: app.bundleIdentifier,
                    url: app.bundleURL,
                    name: name,
                    icon: icon,
                    runningApp: app
                )
            }
            .prefix(12).map { $0 }
    }
    
    private func fetchCustomApps() {
        // 這裡暫時先寫死幾個預設 App 讓你測試，
        // 之後你可以改成從 SharedConfig.defaults 讀取使用者存入的陣列
        let savedBundleIDs = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? [
            "com.apple.Safari",
            "com.apple.MobileSMS",
            "com.apple.mail",
            "com.apple.Terminal",
            "com.apple.systempreferences",
            "com.apple.Notes"
        ]
        var loadedApps: [AppItem] = []
        
        for bundleID in savedBundleIDs {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                let name = FileManager.default.displayName(atPath: url.path)
                let cleanName = (name as NSString).deletingPathExtension
                
                loadedApps.append(AppItem(
                    bundleID: bundleID,
                    url: url,
                    name: cleanName,
                    icon: icon,
                    runningApp: nil // 因為不一定有在執行，所以設為 nil
                ))
            }
        }
        self.apps = loadedApps
    }
    
    // ↕️ 原生拖曳排序
    func moveApp(from source: IndexSet, to destination: Int) {
        var list = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? []
        list.move(fromOffsets: source, toOffset: destination)
        SharedConfig.defaults.set(list, forKey: "customAppList")
        fetchCustomApps() // 存檔並刷新
    }
    
    // ⬆️ 上移 App
    func moveAppUp(at index: Int) {
        guard index > 0 else { return } // 已經是第一個就不能再上移
        var list = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? []
        list.swapAt(index, index - 1) // 將它與前一個元素交換位置
        SharedConfig.defaults.set(list, forKey: "customAppList")
        fetchCustomApps() // 存檔並刷新
    }

    // ⬇️ 下移 App
    func moveAppDown(at index: Int) {
        var list = SharedConfig.defaults.stringArray(forKey: "customAppList") ?? []
        guard index < list.count - 1 else { return } // 已經是最後一個就不能再下移
        list.swapAt(index, index + 1) // 將它與後一個元素交換位置
        SharedConfig.defaults.set(list, forKey: "customAppList")
        fetchCustomApps() // 存檔並刷新
    }
    
    func switchApp(to item: AppItem) {
        if let runningApp = item.runningApp {
            if #available(macOS 14.0, *) {
                NSApp.yieldActivation(to: runningApp)
                runningApp.activate()
            } else {
                runningApp.activate(options: .activateIgnoringOtherApps)
            }
        }
        
        if let url = item.url {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open app \(item.name): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getNextAppId(after currentId: UUID?) -> UUID? {
        guard !apps.isEmpty else { return nil }
                    
        guard let currentId = currentId, let currentIndex = apps.firstIndex(where: { $0.id == currentId }) else {
            return apps[0].id
        }
        // 順時針切換到下一個 (並處理循環)
        let nextIndex = (currentIndex + 1) % apps.count
        return apps[nextIndex].id
    }
        
    /// 取得上一個 (逆時針) App 的 ID
    func getPreviousAppId(before currentId: UUID?) -> UUID? {
        guard !apps.isEmpty else { return nil }
        
        guard let currentId = currentId, let currentIndex = apps.firstIndex(where: { $0.id == currentId }) else {
            return apps.last?.id
        }
        
        let previousIndex = (currentIndex - 1 + apps.count) % apps.count
        return apps[previousIndex].id
    }
}
