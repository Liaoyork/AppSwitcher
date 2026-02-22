internal import AppKit
import Foundation

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    
    private var globalKeyDownMonitor: Any?
    private var localKeyDownMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var localFlagsMonitor: Any?
    
    var onTriggerShow: (() -> Void)?
    var onTriggerExecute: (() -> Void)?
    
    private var currentHotkey: HotkeyData?
    private var isAppSwitcherShowing = false
    
    init() {
        setupMonitors()
        
        // receive the change notification when user updates the hotkey in settings
        DistributedNotificationCenter.default().addObserver(
            forName: SharedConfig.hotkeyChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("received hotkey change notification, updating monitors...")
            self?.setupMonitors()
        }
    }
    
    private func setupMonitors() {
        if let gkd = globalKeyDownMonitor { NSEvent.removeMonitor(gkd) }
        if let lkd = localKeyDownMonitor { NSEvent.removeMonitor(lkd) }
        if let gfm = globalFlagsMonitor { NSEvent.removeMonitor(gfm) }
        if let lfm = localFlagsMonitor { NSEvent.removeMonitor(lfm) }
        
        let hotkey = SharedConfig.getHotkey()
        print("✅ hotkey number: \(hotkey.keyCode), modifiers' number: \(hotkey.modifiers)")
        
        self.currentHotkey = hotkey
        let targetModifiers = NSEvent.ModifierFlags(rawValue: hotkey.modifiers)
        let targetKeyCode = hotkey.keyCode
        
        let keyDownHandler: (NSEvent) -> Void = { [weak self] event in
            let currentModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if event.keyCode == targetKeyCode && currentModifiers == targetModifiers {
                print("🎯 main app: ready to show app switcher")
                self?.isAppSwitcherShowing = true
                DispatchQueue.main.async { self?.onTriggerShow?() }
            }
        }
        
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: keyDownHandler)
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let currentModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if event.keyCode == targetKeyCode && currentModifiers == targetModifiers {
                keyDownHandler(event)
                return nil
            }
            return event
        }
        
        let flagsHandler: (NSEvent) -> Void = { [weak self] event in
            guard let self = self, self.isAppSwitcherShowing else { return }
            let currentModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if targetModifiers.rawValue != 0 && !currentModifiers.contains(targetModifiers) {
                print("🚀 main app: modifier keys released, ready to execute action and hide app switchper")
                self.isAppSwitcherShowing = false
                DispatchQueue.main.async { self.onTriggerExecute?() }
            }
        }
        
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: flagsHandler)
        localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            flagsHandler(event)
            return event
        }
    }
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
