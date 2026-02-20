import Foundation
internal import AppKit

struct SharedConfig {
    // 這裡填入你剛剛在 Xcode 裡設定的 App Group ID
//    static let appGroupIdentifier = "group.com.York.AppSwitcher"
    static let appGroupIdentifier = "com.York.AppSwitcher.Shared"
    
    // 建立一個共用的 UserDefaults 實體
    static var defaults: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    static let hotkeyChangedNotification = NSNotification.Name("com.York.AppSwitcher.HotkeyChanged")
    static let defaultHotkey = HotkeyData(keyCode: 48, modifiers: NSEvent.ModifierFlags.option.rawValue)
        
        // ✨ 統一讀取邏輯：如果有存過的就用存過的，沒有就回傳預設值
    static func getHotkey() -> HotkeyData {
        defaults.synchronize()
        guard let data = defaults.data(forKey: "custom_hotkey"),
              let hotkey = try? JSONDecoder().decode(HotkeyData.self, from: data) else {
            return defaultHotkey
        }
        return hotkey
    }
}

struct HotkeyData: Codable {
    let keyCode: UInt16
    let modifiers: UInt
}
