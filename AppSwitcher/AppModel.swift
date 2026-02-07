import AppKit
internal import Combine

import AppKit

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
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let name = app.localizedName, let icon = app.icon else { return nil }
                return AppItem(app: app, name: name, icon: icon)
            }
            .prefix(12).map { $0 }
    }
    
    func switchApp(to item: AppItem) {
        if #available(macOS 14.0, *) {
            NSApp.yieldActivation(to: item.app)
        } else {
            item.app.activate(options: .activateIgnoringOtherApps)
        }
    }
}
