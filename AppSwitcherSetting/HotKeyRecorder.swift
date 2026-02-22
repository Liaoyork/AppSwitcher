import SwiftUI
internal import AppKit

struct HotkeyRecorderView: View {
    @State private var isRecording = false
    @State private var monitor: Any?
    @State private var currentHotkey: HotkeyData? = SharedConfig.getHotkey()

    var body: some View {
        Button(action: { isRecording.toggle() }) {
            HStack(spacing: 4) {
                if isRecording {
                    Text("Press a key..")
                        .foregroundColor(.accentColor)
                        .font(.system(size: 12, weight: .medium))
                } else if let hotkey = currentHotkey {
                    // display the recorded modifiers
                    let modStr = modifierString(for: hotkey.modifiers)
                    if !modStr.isEmpty {
                        KeyCap(text: modStr)
                    }
                    // display the recorded main key
                    KeyCap(text: keyString(for: hotkey.keyCode))
                } else {
                    Text("Press to record...")
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .onChange(of: isRecording) { _, newValue in
            if newValue { startRecording() }
            else { stopRecording() }
        }
    }

    // --- Core Logic ---
    private func startRecording() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // get the modifiers (Cmd, Opt, Ctrl, Shift)
            let modifiers = event.modifierFlags.intersection([.command, .option, .control, .shift]).rawValue
            let keyCode = event.keyCode
            
            let newHotkey = HotkeyData(keyCode: keyCode, modifiers: modifiers)
            saveHotkey(newHotkey)
            
            self.currentHotkey = newHotkey
            self.isRecording = false
            return nil
        }
    }

    private func stopRecording() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    private func saveHotkey(_ hotkey: HotkeyData) {
        if let encoded = try? JSONEncoder().encode(hotkey) {
            SharedConfig.defaults.set(encoded, forKey: "custom_hotkey")
            // send a notification to the main app to update the hotkey monitors immediately
            DistributedNotificationCenter.default().postNotificationName(
                SharedConfig.hotkeyChangedNotification,
                object: nil,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }

    private static func loadInitialHotkey() -> HotkeyData? {
        guard let data = SharedConfig.defaults.data(forKey: "custom_hotkey") else { return nil }
        return try? JSONDecoder().decode(HotkeyData.self, from: data)
    }

    // --- Helper functions to convert key codes and modifiers to display strings ---
    private func modifierString(for rawValue: UInt) -> String {
        let flags = NSEvent.ModifierFlags(rawValue: rawValue)
        var str = ""
        if flags.contains(.control) { str += "⌃" }
        if flags.contains(.option) { str += "⌥" }
        if flags.contains(.shift) { str += "⇧" }
        if flags.contains(.command) { str += "⌘" }
        return str
    }

    private func keyString(for keyCode: UInt16) -> String {
        switch keyCode {
            
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 31: return "O"
        case 32: return "U"
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 40: return "K"
        case 45: return "N"
        case 46: return "M"
            
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 23: return "5"
        case 22: return "6"
        case 26: return "7"
        case 28: return "8"
        case 25: return "9"
        case 29: return "0"
            
        case 24: return "="
        case 27: return "-"
        case 30: return "]"
        case 33: return "["
        case 39: return "'"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 47: return "."
        case 50: return "`"
            
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Esc"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
            
        default: return "K-\(keyCode)"
        }
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
    }
}
