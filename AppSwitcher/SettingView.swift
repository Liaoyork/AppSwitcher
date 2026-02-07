import SwiftUI

// 設定頁面選項枚舉
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
            // 左側側邊欄
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                NavigationLink(value: pane) {
                    Label(pane.rawValue, systemImage: pane.icon)
                        .padding(.vertical, 4) // 增加一點高度讓它看起來更像原生
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            // 右側詳細內容
            VStack {
                switch selectedPane {
                case .general:
                    GeneralSettingsView()
                case .launcher:
                    LauncherSettingsView()
                case .about:
                    AboutSettingsView()
                case .none:
                    Text("Select a setting")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 650, height: 400) // 設定視窗的標準大小
    }
}

// --- 1. 一般設定 ---
struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("hideMenuBarIcon") var hideMenuBarIcon = false
    @AppStorage("hideOtherApps") var hideOtherApps = false
    @AppStorage("doublePress") var doublePress = false

    var body: some View {
        Form {
            Section {
                Toggle("登入時啟動", isOn: $launchAtLogin)
            } header: {
                Text("啟動")
            }
            
            Section {
                Toggle("隱藏選單列圖示", isOn: $hideMenuBarIcon)
                
                Toggle(isOn: $hideOtherApps) {
                    VStack(alignment: .leading) {
                        Text("隱藏所有其他應用程式")
                        Text("切換應用程式時，僅顯示最前方的應用程式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("一般")
            }
            
            Section {
                HStack {
                    Text("啟動快捷鍵")
                    Spacer()
                    // 這裡做一個假的快捷鍵顯示 UI，看起來很像原生的錄製器
                    HStack(spacing: 4) {
                        KeyCap(text: "⌃")
                        KeyCap(text: "⌥")
                    }
                }
                
                Toggle("連按兩下以顯示", isOn: $doublePress)
                    .disabled(true) // 暫時未實作
                    .help("此功能尚在開發中")
                
            } header: {
                Text("觸發快捷鍵")
            }
        }
        .formStyle(.grouped) // 這是讓它看起來像 macOS 系統設定的關鍵！
    }
}

// 輔助 UI：鍵盤按鍵樣式
struct KeyCap: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
    }
}

// --- 2. 轉盤啟動器設定 ---
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
            } header: {
                Text("外觀")
            }
        }
        .formStyle(.grouped)
    }
}

// --- 3. 關於頁面 ---
struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.grid.2x2.fill")
                .resizable()
                .frame(width: 64, height: 64)
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.4), radius: 10, y: 5)
            
            VStack(spacing: 5) {
                Text("AppSwitcher")
                    .font(.title2.bold())
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("Designed for macOS liquid flow experience.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 40)
    }
}

#Preview {
    SettingsView()
}
