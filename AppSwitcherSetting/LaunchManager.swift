import ServiceManagement

class LaunchManager {
    static let shared = LaunchManager()
    
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                // 註冊開機啟動
                try SMAppService.mainApp.register()
            } else {
                // 取消註冊
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login status: \(error)")
        }
    }
}
