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
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                NavigationLink(value: pane) {
                    Label(pane.rawValue, systemImage: pane.icon)
                        .padding(.vertical, 4)
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            VStack {
                switch selectedPane {
                case .general: GeneralSettingsView()
                case .launcher: LauncherSettingsView()
                case .about: AboutSettingsView()
                case .none: Text("Select a setting")
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(width: 650, height: 400)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("hideOtherApps") var hideOtherApps = false
    @AppStorage("doublePress") var doublePress = false

    var body: some View {
        Form {
            Section {
                Toggle("登入時啟動", isOn: $launchAtLogin)
                    // 修正：新版 onChange
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
//                    KeyboardShortcuts.Recorder(for: .toggleAppSwitcher)
                    HStack(spacing: 4) {
                        KeyCap(text: "^")
                        KeyCap(text: "⌥")
                    }
                }
            } header: { Text("觸發快捷鍵") }
        }
        .formStyle(.grouped)
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        LaunchManager.shared.toggleLaunchAtLogin(enabled: enabled)
    }
}

// ... KeyCap, LauncherSettingsView, AboutSettingsView 保持不變 ...
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
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(.top, 40)
    }
}

#Preview {
    SettingsView()
}
