import SwiftUI
internal import AppKit

// 包裝 AppKit 底層視圖以強制 "Active" 狀態
struct AlwaysActiveLiquidGlass: NSViewRepresentable {
    // 雖然是 macOS 26，但 .hudWindow 材質依然是最接近 "Liquid Glass" 高亮水珠感的選項
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // 🔥 核心魔法：告訴 macOS「這個視窗現在是用戶焦點」，
        // 即使其實用戶正在操作別的 App。
        view.state = .active
        
        view.material = material
        view.blendingMode = blendingMode
        view.isEmphasized = true // 增加一點對比度，讓液態感更明顯
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        // 確保在重繪時狀態不跑掉
        if nsView.state != .active { nsView.state = .active }
    }
}

extension View {
    /// 強制活躍的液態玻璃效果 (解決失焦變暗問題)
    func alwaysActiveGlass(material: NSVisualEffectView.Material = .hudWindow) -> some View {
        self.background(
            AlwaysActiveLiquidGlass(material: material, blendingMode: .withinWindow)
        )
    }
}
