<h1 align="center">



<img src="AppSwitcher_Icon.png" alt="AppSwitcher" width="150">



AppSwitcher



</h1>

<p align="center">
<img src="https://img.shields.io/badge/Platform-macOS%2026%2B-blue?logo=apple" alt="macOS 26+ Only" />
<img src="https://img.shields.io/badge/SwiftUI-6.0-orange?logo=swift" alt="SwiftUI 6.0" />
<img src="https://img.shields.io/badge/License-MIT-green" alt="License MIT" />
</p>

Say hello to AppSwitcher, the most fluid way to navigate your macOS workspace! Forget about the traditional, static Cmd + Tab—AppSwitcher transforms your window switching into a dynamic, circular liquid glass experience. Featuring a vibrant frosted visualizer and intuitive gesture-like controls, it’s like having a futuristic command center right under your fingertips!

<p align="center">
<img src="AppSwitcher_Demo.gif" alt="AppSwitcher Demo" />
</p>

# 🚀 Installation

System Requirements: - macOS 26 tahoe or later

Apple Silicon (M1/M2/M3) or Intel Mac

### 🍺 Via Homebrew (Recommended)
The fastest way to install and keep AppSwitcher updated. Using the `--no-quarantine` flag allows you to skip the manual security approval steps.

```bash
brew install --cask liaoyork/tap/appswitcher --no-quarantine

```

### 🛠️ Manual Installation

1. Download the latest release from the [Releases](https://www.google.com/search?q=https://github.com/liaoyork/appswitcher/releases) page.
2. Unzip and drag `AppSwitcher.app` into your `/Applications` folder.
3. **Important for first-time launch:** Since the app is not notarized, right-click (or Control-click) the app icon and select **close**, not move to trash
   a. go to **Setting** -> **privacy and security**
   b. scroll down to the "security"

### 💻 System Requirements

* **macOS:** 14 Sonoma or later (Requires SettingsLink support).
* **Architecture:** Apple Silicon (M1/M2/M3) or Intel Mac.

```

---

### 這樣改的好處：
1. **指令優先：** 把最簡單的 `brew` 指令放在最前面，增加專業感。
2. **解決痛點：** 特別強調了 `--no-quarantine` 指令，這對沒有付費開發者帳號的你來說是最佳的解決方案，因為它能幫使用者省去翻找「隱私權與安全性」設定的麻煩。
3. **清晰指引：** 手動安裝的部分也明確告知要用「右鍵 -> 打開」，減少使用者安裝失敗的困惑。

這份更新應該能讓你的專案看起來更像一個成熟的開源工具。

**除了安裝說明，你還需要我幫你在 README 加入其他功能展示（例如截圖提示）或操作教學嗎？**

```


# Usage
Activate: Hold Option + Control to reveal the liquid glass ring.

Switch: Hover over any app icon to see the sector highlight, then release the keys to switch.

Customize: Open the Menu Bar icon and select Settings... to fine-tune your experience.

# 📋 Roadmap
[V] Liquid Glass UI (Vibrant Frosted Effect)

[V] Circular Layout (Up to 12 apps)

[V] Option + Control Global Trigger

[V] Adjustable Ring Radius

[V] Launch at Login (via SMAppService)

[V] Shared Configuration (Non-Sandboxed Data Sync)

[V] Customizable Hotkeys 👆🏻

[ ] App Exclusion List 🚫

[ ] Visualizer Color Themes 🎨

# 🛠 Technical Highlights
Active-State Rendering: We solved the macOS "dirty gray" glass issue by forcing the NSVisualEffectView into an .active state, ensuring the UI stays crystal clear regardless of focus.

Zero-Sandbox Sync: By disabling Sandbox and using a custom UserDefaults suite, the main app and settings app sync data seamlessly without the need for an expensive Developer Program.

Screen-Level Overlay: The switcher window resides at the .screenSaver level to ensure it appears above all full-screen applications.
