import SwiftUI
internal import AppKit

@main
struct AppSwitcherApp: App {
    @AppStorage("hideMenuBarIcon", store: SharedConfig.defaults) var hideMenuBarIcon = false
    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    @State private var showLaunchError = false
    
    var body: some Scene {
        WindowGroup {
            OverlayContainer()
                .environment(\.locale, appLanguage.locale)
                // if
        }
        menuBar
    }
    
    @SceneBuilder
    var menuBar: some Scene {
        MenuBarExtra("AppSwitcher", image: "MyCustomIcon") {
            Button("Setting...") {
                // construct to the newest helper app's URL
                let helperURL = Bundle.main.bundleURL
                    .appendingPathComponent("Contents")
                    .appendingPathComponent("Helpers")
                    .appendingPathComponent("AppswitcherSetting.app")
                
                // 2. check the helper app exists or not (to avoid crash if user forget to add Copy Files Phase in Xcode)
                guard FileManager.default.fileExists(atPath: helperURL.path) else {
                    print("❌ can't helper appe helper ：\(helperURL.path)")
                    return
                }
                
                // directly open the helper app
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                
                NSWorkspace.shared.openApplication(at: helperURL, configuration: config) { app, error in
                    if let error = error {
                        print("❌ active failed: \(error.localizedDescription)")
                    } else {
                        print("✅ successfully opened helper app")
                    }
                }
            }
            
            Divider()
            
            Button("Shut down") {
                let mainAppID = "york.AppswitcherSetting"
                
                let runningMainApps = NSWorkspace.shared.runningApplications.filter {
                    $0.bundleIdentifier == mainAppID
                }
                
                for app in runningMainApps {
                    app.terminate()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .environment(\.locale, appLanguage.locale)
    }
}

struct OverlayContainer: View {
    @State private var isShowing = false
    @State private var overlayWindow: NSWindow?
    @State private var hasPromptedThisSession = false
    
    var body: some View {
        ZStack {
            if isShowing {
                ContentView(isShowing: $isShowing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)

        .background(WindowAccessor { window in
            self.overlayWindow = window
            setupOverlayWindow(window ?? NSWindow())
        })
        .onAppear{
            if !hasPromptedThisSession {
                checkAndPromptAccessibility()
                hasPromptedThisSession = true // 標記為已提示
            }
        }
        .onAppear {
            GlobalHotkeyManager.shared.onTriggerShow = {
                if !self.isShowing { self.isShowing = true }
                NotificationCenter.default.post(name: NSNotification.Name("MoveToNextApp"), object: nil)	
            }
            
            GlobalHotkeyManager.shared.onTriggerExecute = {
                if self.isShowing {
                    NotificationCenter.default.post(name: NSNotification.Name("ExecuteSwitch"), object: nil)
                    self.isShowing = false
                }
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                activateWindow()
            } else {
                deactivateWindow()
            }
        }
    }
    
    private func checkAndPromptAccessibility() {
        if !AccessibilityManager.checkAccessibility(prompt: false) {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Tip_Ap", comment: "提示標題")
            alert.informativeText = NSLocalizedString("_tipKey", comment: "提示描述")
            
            alert.addButton(withTitle: NSLocalizedString("Tip_GS", comment: "前往設定按鈕"))
            alert.addButton(withTitle: NSLocalizedString("Tip_later", comment: "稍後按鈕"))
            
            if alert.runModal() == .alertFirstButtonReturn {
                AccessibilityManager.openSystemSettings()
            }
        }
    }
    
    func setupOverlayWindow(_ window: NSWindow) {
        window.styleMask = [.borderless]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        window.alphaValue = 0
        window.ignoresMouseEvents = true
    }

    func activateWindow() {
        guard let window = overlayWindow else { return }
        
        // recenter the window at mouse location each time it's activated
        let mouseLoc = NSEvent.mouseLocation
        let windowSize = window.frame.size
        let newOrigin = NSPoint(x: mouseLoc.x - (windowSize.width / 2), y: mouseLoc.y - (windowSize.height / 2))
        window.setFrameOrigin(newOrigin)
        window.alphaValue = 1
        window.ignoresMouseEvents = false
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func deactivateWindow() {
        guard let window = overlayWindow else { return }
        window.alphaValue = 0
        window.ignoresMouseEvents = true
    }
}

struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

struct AccessibilityManager {
    /// check the accessibility permission, if not granted, optionally prompt the user to open the permission dialog
    /// - Parameter prompt: If true, the system will automatically show a prompt if accessibility permission is not granted
    static func checkAccessibility(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// guide the user to open the system settings for granting accessibility permission
    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
