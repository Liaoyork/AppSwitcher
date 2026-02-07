import SwiftUI
import AppKit

@main
struct AppSwitcherApp: App {
    @State private var isShowing = false
    @State private var overlayWindow: NSWindow?

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isShowing {
                    ContentView(isShowing: $isShowing)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // 使用 VisualEffectView 確保背景透明且不干擾渲染
            .background(VisualEffectView().ignoresSafeArea())
            .onAppear {
                setupWindow()
                setupMonitors()
            }
        }
        .windowStyle(.hiddenTitleBar)
    }

    func setupWindow() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let window = NSApplication.shared.windows.first {
                self.overlayWindow = window
                window.styleMask = [.borderless]
                window.backgroundColor = .clear
                window.isOpaque = false
                window.hasShadow = false
                window.level = .mainMenu
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
                window.alphaValue = 0
                window.ignoresMouseEvents = true
            }
        }
    }

    func setupMonitors() {
        let handler: (NSEvent) -> Void = { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let requiredFlags: NSEvent.ModifierFlags = [.control, .option]
            
            DispatchQueue.main.async {
                if flags.contains(requiredFlags) {
                    if !self.isShowing {
                        self.isShowing = true
                        activateWindow()
                    }
                } else {
                    if self.isShowing {
                        NotificationCenter.default.post(name: NSNotification.Name("KeyReleased"), object: nil)
                        self.isShowing = false
                        deactivateWindow()
                    }
                }
            }
        }

        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: handler)
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            handler(event)
            return event
        }
    }

    func activateWindow() {
        guard let window = overlayWindow else { return }
        
        // 抓取滑鼠位置並設定視窗中心
        let mouseLoc = NSEvent.mouseLocation
        let windowSize = window.frame.size
        
        let newOrigin = NSPoint(
            x: mouseLoc.x - (windowSize.width / 2),
            y: mouseLoc.y - (windowSize.height / 2)
        )
        
        window.setFrameOrigin(newOrigin)
        window.alphaValue = 1
        window.ignoresMouseEvents = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func deactivateWindow() {
        guard let window = overlayWindow else { return }
        window.alphaValue = 0
        window.ignoresMouseEvents = true
        NSApp.hide(nil)
    }
}

// 修正關鍵：定義遺失的 VisualEffectView
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
