# 🍎 AppSwitcher: The Liquid Glass Experience
> **Elevate your macOS workflow with a touch of fluid aesthetics.**

Developed by **York**, AppSwitcher is a high-performance window management utility for macOS. It reimagines application switching with a stunning, circular frosted glass interface designed to feel like a native part of the modern macOS "Liquid" design language.

---

## ✨ Key Features

* **Liquid Glass UI**: Utilizes custom `NSVisualEffectView` configurations to maintain a vibrant, frosted glass effect that never turns "dirty gray," even when focus is lost.
* **Circular Navigation**: Arranges your 12 most recently used applications in a beautiful, interactive ring for rapid scanning.
* **Precision Trigger**: Hard-coded to `Option + Control` to ensure zero conflicts with system shortcuts while providing instant accessibility.
* **Shared Configuration**: A dual-app architecture (Main App + Settings App) that synchronizes data seamlessly without requiring complex App Group permissions.
* **Modern Launch Logic**: Employs `SMAppService` for reliable "Launch at Login" functionality, built for macOS 13 and beyond.

---

## 🚀 Getting Started

### Installation (Personal Build)
Since this app is distributed as a custom build, follow these steps to ensure a smooth setup:

1.  **Deploy**: Move `AppSwitcher.app` and `AppSwitcherSetting.app` to your `/Applications` folder.
2.  **Clear Quarantine**: If the app fails to open, run the following command in Terminal:
    `xattr -cr /Applications/AppSwitcher.app`
3.  **Permissions**:
    * **Accessibility**: Required to detect the `Option + Control` shortcut.
    * **Screen Recording**: Required for `CGWindowList` to identify active window titles.

---

## 🛠 Technical Details

* **Non-Sandboxed Sharing**: By disabling App Sandbox and using a custom `UserDefaults` suite, the app achieves cross-process data sharing without the need for a paid developer account.
* **Active-State Rendering**: Forces the glass background to an `.active` state, ensuring the UI remains aesthetically pleasing regardless of window layering.

---

# 🍎 AppSwitcher：液態玻璃流動體驗
> **用流動的美學，重新定義你的 macOS 工作流。**

由 **York** 開發的 AppSwitcher 是一款專為 macOS 打造的高性能視窗管理工具。它透過令人驚艷的圓形磨砂玻璃界面重新詮釋了程式切換，並完美融入 macOS 的「液態 (Liquid)」設計語言。

---

## ✨ 核心特色

* **液態玻璃 UI**：透過自定義 `NSVisualEffectView`，確保磨砂效果即使在失去焦點時也能保持晶瑩剔透，告別傳統視窗變灰變暗的通病。
* **圓環導航**：將最近使用的 12 個應用程式排列成互動式圓環，讓你一目了然。
* **精準觸發**：固定使用 `Option + Control` 快捷鍵，避開系統衝突並提供極速反應。
* **共享設定**：採用主程式與設定程式的分離架構，無需 App Group 權限即可實現無縫數據同步。
* **現代化啟動邏輯**：整合 `SMAppService`，為 macOS 13+ 提供最穩定、不依賴舊版 Helper 的登入啟動功能。

---

## 🚀 開始使用

### 安裝與設定
身為開發者自用版本，請依照以下步驟完成部署：

1.  **部署**：將 `AppSwitcher.app` 與 `AppSwitcherSetting.app` 移至「應用程式」資料夾。
2.  **解除隔離**：若無法開啟，請在終端機執行：
    `xattr -cr /Applications/AppSwitcher.app`
3.  **權限設定**：
    * **輔助使用**：用於監聽快捷鍵觸發。
    * **螢幕錄製**：用於透過 `CGWindowList` 獲取活動視窗列表。

---

## 🛠 技術特點

* **去沙盒共享 (Non-Sandboxed)**：透過關閉沙盒並使用自定義 `UserDefaults` 套件，在無需付費帳號的情況下實現跨進程數據共享。
* **強制活躍渲染**：強制玻璃背景維持在 `.active` 狀態，確保 UI 在任何視窗層級下都保持最美觀的效果。
