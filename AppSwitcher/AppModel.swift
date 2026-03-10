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
    
    func addApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        panel.allowsMultipleSelection = true
        
        if panel.runModal() == .OK {
            var list = customBundleIDs
            
            var hasChanges = false
            
            for url in panel.urls {
                if let bundle = Bundle(url: url), let bid = bundle.bundleIdentifier {
                    if !list.contains(bid) {
                        list.append(bid)
                        hasChanges = true
                    }
                }
            }
            
            if hasChanges {
                customBundleIDs = list
                fetchCustomApps()
            }
        }
    }

    func removeApp(bundleID: String) {
        var list = customBundleIDs
        list.removeAll { $0 == bundleID }
        
        if list.isEmpty {
            list = [
                "com.apple.Safari",
                "com.apple.MobileSMS",
                "com.apple.mail",
                "com.apple.Terminal",
                "com.apple.systempreferences",
                "com.apple.Notes"
            ]
        }
        customBundleIDs = list
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
        let savedBundleIDs = customBundleIDs
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
                    runningApp: nil
                ))
            }
        }
        self.apps = loadedApps
    }
    

    func moveApp(from source: IndexSet, to destination: Int) {
        var list = customBundleIDs
        list.move(fromOffsets: source, toOffset: destination)
        customBundleIDs = list
        fetchCustomApps()
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
        let nextIndex = (currentIndex + 1) % apps.count
        return apps[nextIndex].id
    }
        
    func getPreviousAppId(before currentId: UUID?) -> UUID? {
        guard !apps.isEmpty else { return nil }
        
        guard let currentId = currentId, let currentIndex = apps.firstIndex(where: { $0.id == currentId }) else {
            return apps.last?.id
        }
        
        let previousIndex = (currentIndex - 1 + apps.count) % apps.count
        return apps[previousIndex].id
    }
}

