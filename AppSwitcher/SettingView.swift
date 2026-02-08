import SwiftUI
internal import AppKit
import ServiceManagement
import KeyboardShortcuts

// ... Enum 定義保持不變 ...
enum SettingsPane: String, CaseIterable, Identifiable {
    case general = "一般"
    case launcher = "轉盤啟動器"
    case about = "關於"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .launcher: return "circle.dashed"
        case .about: return "info.circle"
        }
    }
}

struct SettingsView: View {
    @State private var selectedPane: SettingsPane? = .general
    
    var body: some View {
        NavigationSplitView {
            // --- 左側：側邊欄 ---
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                NavigationLink(value: pane) {
                    Label(pane.rawValue, systemImage: pane.icon)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 6) // 稍微增加高度讓點擊區更舒適
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200) // 鎖定側邊欄寬度
            
        } detail: {
            // --- 右側：內容區 ---
            // 移除外層 VStack，直接放 View 或 Group，讓 Form 填滿
            Group {
                switch selectedPane {
                case .general: GeneralSettingsView()
                case .launcher: LauncherSettingsView()
                case .about: AboutSettingsView()
                case .none: Text("Select a setting")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // ✨ 關鍵修改 1: 鎖定整個設定視窗的大小，避免使用者拉成奇怪的比例
        .frame(width: 700, height: 450)
        // ✨ 關鍵修改 2: 透過 WindowAccessor 直接修改底層視窗樣式
        .background(WindowAccessor { window in
            guard let window = window else { return }
            
            // 1. 隱藏標題列，讓內容衝到頂部 (解決上方白條)
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            
            // 2. 讓內容延伸到整個視窗 (包含紅綠燈區域)
            window.styleMask.insert(.fullSizeContentView)
            
            // 3. (選用) 如果你想要完全自定義圓角，要把背景變透明
            // window.isOpaque = false
            // window.backgroundColor = .clear
            
            // 4. 讓 Toolbar (紅綠燈) 變得像原生 Settings 一樣乾淨
            window.toolbarStyle = .unified
        })
    }
}

// ... GeneralSettingsView, LauncherSettingsView, KeyCap 保持不變 ...
// (為了版面整潔，我省略了中間內容不變的部分，請保留你原本的代碼)

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("hideOtherApps") var hideOtherApps = false
    @AppStorage("doublePress") var doublePress = false

    var body: some View {
        Form {
            Section {
                Toggle("登入時啟動", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
            } header: { Text("啟動") }
            
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("啟動快捷鍵")
                        Text("目前僅支援 option + control")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        KeyCap(text: "^")
                        KeyCap(text: "⌥")
                    }
                }
            } header: { Text("觸發快捷鍵") }
        }
        .formStyle(.grouped)
        // ✨ 確保 Form 不會有額外的 padding 導致對齊問題
        .scrollContentBackground(.hidden)
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        LaunchManager.shared.toggleLaunchAtLogin(enabled: enabled)
    }
}

// ... LauncherSettingsView, KeyCap 保持不變 ...
// (請保留你原本的 LauncherSettingsView, KeyCap 程式碼)

struct LauncherSettingsView: View {
    @AppStorage("ringRadius") var ringRadius: Double = 280
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("圓環半徑")
                        Spacer()
                        Text("\(Int(ringRadius)) px").foregroundColor(.secondary)
                    }
                    Slider(value: $ringRadius, in: 200...400)
                }
            } header: { Text("外觀") }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.grid.2x2.fill")
                .resizable().frame(width: 64, height: 64).foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.4), radius: 10, y: 5)
            VStack(spacing: 5) {
                Text("AppSwitcher").font(.title2.bold())
                Text("Version 1.0.0").font(.subheadline).foregroundColor(.secondary)
            }
            Text("Designed for macOS liquid flow experience.").font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}

struct KeyCap: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 6)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color(nsColor: .controlBackgroundColor)).shadow(color: .black.opacity(0.1), radius: 1, y: 1))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(nsColor: .separatorColor), lineWidth: 1))
    }
}

// ✨ 這是最重要的魔法工具：放在檔案最下方


#Preview {
    SettingsView()
}
