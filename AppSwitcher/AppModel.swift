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
            // 1. 抓取所有視窗 (包含全螢幕)
            let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
            guard let windowListInfo = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
                self.apps = []
                return
            }
            
            // 2. 建立 PID 過濾清單
            let visiblePIDs = Set(windowListInfo.compactMap { info -> pid_t? in
                guard
                    let pid = info[kCGWindowOwnerPID as String] as? Int32,
                    pid != NSRunningApplication.current.processIdentifier,
                    
                    // 規則 1: 必須是標準視窗層級 (Layer 0)
                    let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                    
                    // 規則 2: 透明度必須大於 0
                    let alpha = info[kCGWindowAlpha as String] as? Double, alpha > 0,
                    
                    // 規則 3: 檢查是否有「視窗擁有者名稱」
                    // (這個不需要權限通常也能抓到，用來過濾一些系統幽靈視窗)
                    let ownerName = info[kCGWindowOwnerName as String] as? String, !ownerName.isEmpty,

                    // 規則 4: 尺寸檢查 (過濾掉背景小工具)
                    let bounds = info[kCGWindowBounds as String] as? [String: Any],
                    let width = bounds["Width"] as? CGFloat,
                    let height = bounds["Height"] as? CGFloat,
                    width > 50 && height > 50
                else { return nil }
                
                return pid
            })
            
            // 3. 獲取執行中的 App
            let runningApps = NSWorkspace.shared.runningApplications
            
            self.apps = runningApps
                .filter { $0.activationPolicy == .regular }
                .filter { visiblePIDs.contains($0.processIdentifier) }
                .compactMap { app in
                    guard let name = app.localizedName, let icon = app.icon else { return nil }
                    return AppItem(app: app, name: name, icon: icon)
                }
                .prefix(12).map { $0 }
        }
    
    func switchApp(to item: AppItem) {
        if #available(macOS 14.0, *) {
//            NSApp.yieldActivation(to: item.app)
            item.app.activate(options: .activateIgnoringOtherApps)
        } else {
            item.app.activate(options: .activateIgnoringOtherApps)
        }
    }
}
