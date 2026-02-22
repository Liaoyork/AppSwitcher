import Foundation
internal import AppKit

struct SharedConfig {
    static let appGroupIdentifier = "com.York.AppSwitcher.Shared"
    
    static var defaults: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
    static let hotkeyChangedNotification = NSNotification.Name("com.York.AppSwitcher.HotkeyChanged")
    static let defaultHotkey = HotkeyData(
        keyCode: 48,
        modifiers: NSEvent.ModifierFlags([.option, .command]).rawValue
    )
    
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
    
    var displayName: String {
        switch self {
        case .system: return NSLocalizedString("System", comment: "Use system language")
        case .english: return "English"
        case .chinese: return "繁體中文"
        }
    }
    
    var locale: Locale {
        if self == .system {
            return Locale.current
        } else {
            return Locale(identifier: self.rawValue)
        }
    }
}
