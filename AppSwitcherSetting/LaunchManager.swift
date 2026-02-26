import ServiceManagement

class LaunchManager {
    static let shared = LaunchManager()
    
    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }
    
    func toggleLaunchAtLogin(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login status: \(error)")
        }
    }
}
