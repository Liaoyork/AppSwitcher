import SwiftUI
internal import AppKit
//import KeyboardShortcuts

@main
struct AppSwitcherApp: App {
    // 連動設定：是否隱藏 MenuBar 圖示
    @AppStorage("hideMenuBarIcon", store: SharedConfig.defaults) var hideMenuBarIcon = false
//    @AppStorage("launchAtLogin", store: SharedConfig.defaults) var launchAtLogin = false
    @State private var showLaunchError = false
    var body: some Scene {
        WindowGroup {
            // 使用我們之前拆分好的 OverlayContainer
            OverlayContainer()
        }
//        .windowStyle(.hiddenTitleBar)

//        Settings {
//            SettingsView()
//        }
//        
        // 選單列邏輯
        menuBar
    } 
    @SceneBuilder
    var menuBar: some Scene {
        MenuBarExtra("AppSwitcher", systemImage: "circle.grid.2x2.fill") {
            // ✨ macOS 14+ 推薦寫法：使用 SettingsLink
            Button("設定...") {
                let settingAppID = "york.AppswitcherSetting" //
                
                // 嘗試用 Bundle ID 啟動
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: settingAppID) {
                    let config = NSWorkspace.OpenConfiguration()
                    config.activates = true // 強制跳到最前面
                    
                    NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
                        if let error = error {
                            print("❌ 啟動失敗: \(error.localizedDescription)")
                        }
                    }
                } else {
                    print("找不到設定 App，請確認是否有編譯過 AppSwitcherSetting Target")
                }
            }
            
            Divider()
            
            Button("結束 AppSwitcher") {
                let mainAppID = "york.AppswitcherSetting" // 確保這跟你的主程式 Bundle ID 一致
                
                let runningMainApps = NSWorkspace.shared.runningApplications.filter {
                    $0.bundleIdentifier == mainAppID
                }
                
                for app in runningMainApps {
                    app.terminate()
                }
                
                // 2. 稍微延遲後，殺掉自己 (設定程式)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
    }

}

struct OverlayContainer: View {
    @State private var isShowing = false
    @State private var overlayWindow: NSWindow? // 儲存這個視窗的參考
    var body: some View {
        ZStack {
            if isShowing {
                ContentView(isShowing: $isShowing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // ✨ 關鍵修改：利用 WindowAccessor 直接抓到這個視窗並設定
        .background(WindowAccessor { window in
            self.overlayWindow = window
            setupOverlayWindow(window ?? NSWindow()) // 呼叫設定函式
        })
//        .background(VisualEffectView().ignoresSafeArea())
        .onAppear {
            // setupWindow() <-- 舊的迴圈函式刪掉，不用了
            setupMonitors()
            
//            KeyboardShortcuts.onKeyUp(for: .toggleAppSwitcher) {
//                isShowing.toggle()
//            }
        }
        .onChange(of: isShowing) { _, newValue in
            if newValue {
                activateWindow()
            } else {
                deactivateWindow()
            }
        }
    }
    
    // ✨ 新的設定函式：直接對傳進來的 window 操作，不用再去猜是哪一個
    func setupOverlayWindow(_ window: NSWindow) {
        window.styleMask = [.borderless]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        
        // 設定為最高層級 (全螢幕覆蓋)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        
        // 初始狀態：隱藏 + 點擊穿透
        window.alphaValue = 0
        window.ignoresMouseEvents = true
    }
    
    // ... setupMonitors, activateWindow, deactivateWindow 保持不變 ...
    func setupMonitors() {
        let handler: (NSEvent) -> Void = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let requiredFlags: NSEvent.ModifierFlags = [.control, .option]
            DispatchQueue.main.async {
                if flags.contains(requiredFlags) {
                    if !self.isShowing { self.isShowing = true }
                } else {
                    if self.isShowing {
                        NotificationCenter.default.post(name: NSNotification.Name("ExecuteSwitch"), object: nil)
                        self.isShowing = false
                    }
                }
            }
        }
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in handler(event); return event }
    }

    func activateWindow() {
        guard let window = overlayWindow else { return }
        // 每次顯示時重新校正位置到滑鼠旁
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

// 輔助視圖
//struct VisualEffectView: NSViewRepresentable {
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        view.wantsLayer = true
//        view.layer?.backgroundColor = NSColor.clear.cgColor
//        return view
//    }
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}

// 將原本的 VisualEffectView 替換成這個
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        
        // 1. 設定混合模式：讓它成為視窗的背景
        view.blendingMode = .behindWindow
        
        // 2. ✨ 關鍵修正：強制狀態為「永遠活躍」
        // 這樣即使設定視窗打開，圓環也不會變灰、變髒
        view.state = .active
        
        // 3. 設定材質：你可以選 .hudWindow (較亮/通透) 或 .underWindowBackground (標準)
        // 配合你的液態玻璃感，.hudWindow 通常效果最好
        view.material = .hudWindow
        
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        // 不需要更新
    }
}

//struct WindowAccessor: NSViewRepresentable {
//    var callback: (NSWindow) -> Void
//
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//        DispatchQueue.main.async {
//            if let window = view.window {
//                self.callback(window)
//            }
//        }
//        return view
//    }
//
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}

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
