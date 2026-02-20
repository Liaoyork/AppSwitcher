import Foundation
internal import AppKit

struct SharedConfig {
    static let appGroupIdentifier = "com.York.AppSwitcher.Shared"
    
    // 建立一個共用的 UserDefaults 實體
    static var defaults: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    static let hotkeyChangedNotification = NSNotification.Name("com.York.AppSwitcher.HotkeyChanged")
    static let defaultHotkey = HotkeyData(
        keyCode: 48,
        modifiers: NSEvent.ModifierFlags([.option, .command]).rawValue
    )
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

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "System"
    case english = "en"
    case chinese = "zh-Hant"
    
    var id: String { self.rawValue }
    
    // 選單上顯示的名稱
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("System", comment: "Use system language")
        case .english: return "English"
        case .chinese: return "繁體中文"
        }
    }
    
    // 轉換成 SwiftUI 需要的 Locale 格式
    var locale: Locale {
        if self == .system {
            return Locale.current
        } else {
            return Locale(identifier: self.rawValue)
        }
    }
}
