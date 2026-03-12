import SwiftUI
internal import AppKit
import ServiceManagement
import Foundation

enum SettingsPane: String, CaseIterable, Identifiable {
    case general = "tab_General"
    case launcher = "tab_Launcher"
    case about = "tab_About"
    
    var localizedName: LocalizedStringKey {
        return LocalizedStringKey(self.rawValue)
    }
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .launcher: return "circle.dashed"
        case .about: return "info.circle"
        }
    }
}

extension Bundle {
    static var appVersion: String {
        return main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

struct SettingsView: View {
    @State private var selectedPane: SettingsPane? = .general
    
    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    
    var body: some View {
        NavigationSplitView {
            // sidebar
            List(SettingsPane.allCases, selection: $selectedPane) { pane in
                NavigationLink(value: pane) {
                    Label(pane.localizedName, systemImage: pane.icon)
                        .font(.system(size: 13, weight: .medium))
                        .padding(.vertical, 6)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 200)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 10)
            }
            .environment(\.locale, appLanguage.locale)
            
        } detail: {
            // content
            Group {
                switch selectedPane {
                case .general: GeneralSettingsView()
                case .launcher: LauncherSettingsView()
                case .about: AboutSettingsView()
                case .none: Text("Select a setting")
                }
            }
            
            
            .padding()
        }
        .environment(\.locale, appLanguage.locale)
        .frame(minWidth: 0, maxWidth: .infinity)
        .navigationTitle("App Switcher")
        .background(WindowAccessor_S { window in
            guard let window = window else { return }
            window.titlebarAppearsTransparent = true
            window.styleMask.insert(.fullSizeContentView)
            window.toolbarStyle = .unified
        })
    }
}


struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin", store: SharedConfig.defaults) var launchAtLogin = false
    @AppStorage("hideOtherApps", store: SharedConfig.defaults) var hideOtherApps = false
    @AppStorage("doublePress", store: SharedConfig.defaults) var doublePress = false

    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        updateLaunchAtLogin(enabled: newValue)
                    }
            } header: { Text("Launch") }
            
            Section {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Change Hot Key")
                    }
                    Spacer()
                    HotkeyRecorderView()
                }
            } header: { Text("Hot Key") }
            Section {
                HStack {
                    Picker("Language", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                }
            } header: { Text("Language") }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .environment(\.locale, appLanguage.locale)
        .padding(.top, -20)
    }
    
    private func updateLaunchAtLogin(enabled: Bool) {
        LaunchManager.shared.toggleLaunchAtLogin(enabled: enabled)
    }
}

struct LauncherSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var store = AppStore()
    @State private var showListPopover = false
    
    @AppStorage("ringRadius", store: SharedConfig.defaults) var ringRadius: Double = 300
    @AppStorage("iconSize", store: SharedConfig.defaults) var iconSize: Double = 60
    @AppStorage("ringInnerRatio", store: SharedConfig.defaults) var ringInnerRatio: Double = 0.6
    @AppStorage("hepaticFeedback", store: SharedConfig.defaults) var hepaticFeedback: Bool = true
    
    @AppStorage("appLanguage", store: SharedConfig.defaults) var appLanguage: AppLanguage = .system
    @AppStorage("isUserSet", store: SharedConfig.defaults) var isUserSet: Bool = false
    
    @AppStorage("sectorColor", store: SharedConfig.defaults) var sectorColor: String = "#007AFF"
    @State private var tempColor: Color = .blue
    
    let presets = ["#007AFF", "#5856D6", "#AF52DE", "#FF2D55", "#FF9500", "#34C759", "#8E8E93"]
    var body: some View {
        let ratioProxy = Binding<Double>(
            get: { 0.6 - ringInnerRatio },
            set: { ringInnerRatio = 0.6 - $0 }
        )
        Form {
            Section() {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        // 左邊：Custom
                        Button(action: { isUserSet = true }) {
                            Text("Custom")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .foregroundColor(
                                    colorScheme == .dark
                                    ? (isUserSet ? .black : .white)
                                    : (!isUserSet ? .black : .white)
                                )
                                .background(isUserSet ? Color.accentColor : Color.gray.opacity(0.15))
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                        Divider().frame(height: 16)
                    
                        Button(action: { isUserSet = false }) {
                            Text("Active Window")
                                .font(.system(size: 13, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                                .background(!isUserSet ? Color.accentColor : Color.gray.opacity(0.15))
                                .foregroundColor(
                                    colorScheme == .dark
                                    ? (isUserSet ? .white : .black)
                                    : (!isUserSet ? .white : .black)
                                )
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .cornerRadius(6)
                    
                    Divider()
                    VStack {
                        ZStack {
                            ContentView(
                                isShowing: .constant(true),
                                isPreview: true,
                            )
                        }
                        .frame(width: 350, height: 350)
                        .scaleEffect(0.75)
                        .background(.clear)
                        .cornerRadius(12)
                        .id("\(isUserSet)-\(store.apps.map { $0.name }.joined())")
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    if isUserSet {
                        Divider().padding(.vertical, 4)
                        HStack {
                            Text("App List").font(.headline)
                            Spacer()
                            Button(action: { showListPopover.toggle() }) {
                                Label("Manage List", systemImage: "list.bullet.rectangle")
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $showListPopover, arrowEdge: .trailing) {
                                VStack(alignment: .leading, spacing: 0) {
                                    List {
                                        ForEach(store.apps) { app in
                                            HStack {
                                                Image(nsImage: app.icon).resizable().frame(width: 18, height: 18)
                                                Text(app.name).font(.system(size: 14))
                                                Spacer()
                                                Button(action: { if let bid = app.bundleID { store.removeApp(bundleID: bid) } }) {
                                                    Image(systemName: "minus.circle.fill").foregroundColor(.red)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .onMove { source, destination in
                                            store.moveApp(from: source, to: destination)
                                        }
                                        
                                    }
                                    .scrollContentBackground(.hidden)
                                    Divider()
                                    
                                    Button(action: { store.addApp() }) {
                                        Label("Add Application...", systemImage: "plus")
                                            .padding(8)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .frame(width: 280, height: 350)
                            }
                        }
                    }
                    Text(isUserSet
                         ? "Show your custom app list in the switcher. You can add any app you want, and rearrange their order by dragging."
                         : "Only show the active window and its associated app in the switcher.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(.vertical, 4)
                .frame(maxWidth: .infinity)
            }
            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Radius")
                        Spacer()
                        Text("\(Int(ringRadius)) px").foregroundColor(.secondary)
                    }
                    Slider(value: $ringRadius, in: 200...400)
                        .tint(.accentColor)
                    HStack {
                        Text("Icon Size")
                        Spacer()
                        Text("\(Int(iconSize)) px").foregroundColor(.secondary)
                    }
                    Slider(value: $iconSize, in: 40...80)
                    HStack {
                        Text("Thickness")
                        Spacer()
                        Text(String(format: "%.2f", ratioProxy.wrappedValue / 0.6 )).foregroundColor(.secondary)
                    }
                    Slider(value: ratioProxy, in: 0.0...0.6)
                    HStack {
                        Text("Sector Color")
                        Spacer()
                        HStack() {
                            ForEach(presets, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.8), lineWidth: sectorColor == hex ? 2 : 0)
                                    )
                                    .shadow(color: .black.opacity(0.1), radius: 1)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            sectorColor = hex
                                        }
                                    }
                            }
                            ColorPicker("", selection: Binding(
                                get: { Color(hex: sectorColor) },
                                set: { sectorColor = $0.toHex() }
                            ))
                            .labelsHidden()
                            .fixedSize()
                            .padding(.leading, 4)
                        }
                    }
                    .onAppear {
                        tempColor = Color(hex: sectorColor)
                    }
                    .padding(.top, 8)
                    HStack {
                        Spacer()
                        Button("Use Default") {
                            ringRadius = 300
                            iconSize = 60
                            ringInnerRatio = 0.6
                            sectorColor = "#007AFF"
                        }
                        
                        .tint(colorScheme == .dark ? Color.white : Color.black)
                    }
                }
            } header: { Text("Appearance") }
            Section {
                VStack (alignment: .leading){
                    HStack{
                        Toggle("Hepatic Feedback", isOn: $hepaticFeedback)
                    }
                }
            } header: { Text("Others") }
        }
        .formStyle(.grouped)
        .padding(.top, -40)
        .scrollContentBackground(.hidden)
        .environment(\.locale, appLanguage.locale)
    }
}

struct AboutSettingsView: View {
    var body: some View {
        Section{
            VStack(spacing: 20) {
                Image("AppIcon_S")
                    .resizable().frame(width: 128, height: 128).foregroundColor(.accentColor)
                    .shadow(color: .accentColor.opacity(0.4), radius: 10, y: 5)
                VStack() {
                    Text("AppSwitcher").font(.title2.bold())
                    Text("Version \(Bundle.appVersion)").font(.subheadline).foregroundColor(.secondary)
                }
                Button {
                    if let url = URL(string: "https://github.com/Liaoyork/AppSwitcher.git") {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image("github-logo")
                            .resizable()
                            .frame(width: 18, height: 18)
                        Text("View on GitHub")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("View AppSwitcher on GitHub")
                Text("Designed for macOS").font(.caption).foregroundColor(.secondary)
            }
        }
    }
}

struct WindowAccessor_S: NSViewRepresentable {
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

struct KeyCap: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .frame(minWidth: 20, minHeight: 20)
            .padding(.horizontal, 6)
            .foregroundColor(.black)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(colorScheme == .dark ? Color.accentColor : Color.gray.opacity(0.15))
                    .shadow(color: .black.opacity(0.1), radius: 1, y: 1)
            )
    }
}

struct PreviewRingView: View {
    @Binding var isShowing: Bool
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 8, dash: [6]))
                .foregroundStyle(.secondary.opacity(0.4))
            Text(isShowing ? "Preview" : "")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .background(Color.clear)
        .clipShape(Rectangle())
    }
}

#Preview {
    SettingsView()
}
