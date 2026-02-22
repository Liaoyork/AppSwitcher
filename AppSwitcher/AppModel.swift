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
        let runningApps = NSWorkspace.shared.runningApplications
        
        self.apps = runningApps
            // only include regular apps (those that appear in the Dock)
            .filter { $0.activationPolicy == .regular }
            // fliter out the current app to avoid showing itself in the list
            .filter { $0.processIdentifier != NSRunningApplication.current.processIdentifier }
            .compactMap { app in
                guard let name = app.localizedName, let icon = app.icon else { return nil }
                return AppItem(app: app, name: name, icon: icon)
            }
            // restrict to 12 items for better performance and UI clarity
            .prefix(12).map { $0 }
    }
    
    func switchApp(to item: AppItem) {
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: item.app)
            item.app.activate()
        } else {
            item.app.activate(options: .activateIgnoringOtherApps)
        }
        
        if let bundleURL = item.app.bundleURL {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
                if let error = error {
                    print("Failed to open app to simulate dock click: \(error.localizedDescription)")
                }
            }
        }
    }
}
