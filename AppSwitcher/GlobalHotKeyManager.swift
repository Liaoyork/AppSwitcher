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
        
        // ✨ 改用閉包監聽，指定在主執行緒執行
        DistributedNotificationCenter.default().addObserver(
            forName: SharedConfig.hotkeyChangedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("收到更改")
            self?.setupMonitors()
        }
    }
    
    private func setupMonitors() {
        if let gkd = globalKeyDownMonitor { NSEvent.removeMonitor(gkd) }
        if let lkd = localKeyDownMonitor { NSEvent.removeMonitor(lkd) }
        if let gfm = globalFlagsMonitor { NSEvent.removeMonitor(gfm) }
        if let lfm = localFlagsMonitor { NSEvent.removeMonitor(lfm) }
        
        let hotkey = SharedConfig.getHotkey()
        print("✅ 主程式綁定熱鍵 -> 鍵碼: \(hotkey.keyCode), 修飾鍵: \(hotkey.modifiers)")
        
        self.currentHotkey = hotkey
        let targetModifiers = NSEvent.ModifierFlags(rawValue: hotkey.modifiers)
        let targetKeyCode = hotkey.keyCode
        
        let keyDownHandler: (NSEvent) -> Void = { [weak self] event in
            let currentModifiers = event.modifierFlags.intersection([.command, .control, .option, .shift])
            if event.keyCode == targetKeyCode && currentModifiers == targetModifiers {
                print("🎯 主程式：偵測到熱鍵按下！準備顯示轉盤")
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
                print("🚀 主程式：修飾鍵放開，執行切換")
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
    /// 檢查目前 App 是否已被授予輔助使用權限
    /// - Parameter prompt: 若為 true，系統在沒權限時會自動彈出提示視窗
    static func checkAccessibility(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    /// 引導使用者手動開啟系統設定頁面
    static func openSystemSettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
