import SwiftUI

@main
struct AppSwitcherSettingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) private var openWindow
    var body: some Scene {
        Window ("AppSwitcher Setting", id: "main_settings") {
            SettingsView()
                // improve UX: whenever the app becomes active
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    openWindow(id: "main_settings")
                }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
        func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
            return false
        }
        
        func applicationWillTerminate(_ notification: Notification) {
        
            let mainAppID = "york.AppSwitcher"
            
            let runningMainApps = NSWorkspace.shared.runningApplications.filter {
                $0.bundleIdentifier == mainAppID
            }
            
            for app in runningMainApps {
                app.terminate()
            }
        
        Thread.sleep(forTimeInterval: 0.05)
    }
}
