import Foundation
internal import AppKit
import SwiftUI

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

extension Color {
    func toHex() -> String {
        // 🌟 關鍵：強制轉換到 sRGB 顏色空間，避免 P3 或其他面板導致的偏差
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components, components.count >= 3 else {
            return "#007AFF"
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        let a = Float(components.count >= 4 ? components[3] : 1.0)
        
        // 轉換為 8 碼 Hex (RRGGBBAA)，確保透明度也被存進去
        return String(format: "#%02lX%02lX%02lX%02lX",
                      lroundf(r * 255),
                      lroundf(g * 255),
                      lroundf(b * 255),
                      lroundf(a * 255))
    }

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        case 8: // RGBA (支援透明度)
            (r, g, b, a) = ((int >> 24) & 0xff, (int >> 16) & 0xff, (int >> 8) & 0xff, int & 0xff)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

