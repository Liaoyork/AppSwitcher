import Foundation

struct SharedConfig {
    // 這裡填入你剛剛在 Xcode 裡設定的 App Group ID
    static let appGroupIdentifier = "group.com.York.AppSwitcher"
    
    // 建立一個共用的 UserDefaults 實體
    static var defaults: UserDefaults {
        return UserDefaults(suiteName: appGroupIdentifier) ?? .standard
    }
}
