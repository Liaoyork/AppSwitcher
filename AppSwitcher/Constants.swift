import KeyboardShortcuts
internal import AppKit

extension KeyboardShortcuts.Name {
    // 定義快捷鍵名稱，這裡我們叫它 "toggleAppSwitcher"
    static let toggleAppSwitcher = Self("toggleAppSwitcher", default: .init(.space, modifiers: [.option]))
}
