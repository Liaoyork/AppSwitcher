這是一個為你的專案量身打造的 README.md，結合了你最自豪的「液態玻璃 (Liquid Glass)」視覺風格與技術細節。

🍎 AppSwitcher: The Liquid Glass Experience
Elevate your macOS workflow with a touch of fluid aesthetics.

Developed by York, AppSwitcher is not just a utility; it's a visual upgrade for your Mac. It reimagines the classic Cmd + Tab by introducing a stunning, circular, and frosted glass interface that feels like a native part of the "Liquid" design language.

✨ Key Features
Liquid Glass UI: Utilizing custom NSVisualEffectView configurations to ensure a crystal-clear, frosted glass effect that stays vibrant even when out of focus.

Intuitive Circular Navigation: Quickly scan and switch between your 12 most recent applications arranged in a beautiful ring.

Precision Trigger: Perfectly mapped to Option + Control for a conflict-free, high-speed switching experience.

Native-Feel Settings: A dedicated, non-sandboxed configuration app that manages everything from ring radius to "Launch at Login" status.

Performance First: Built with SwiftUI and AppKit to ensure near-zero CPU impact and smooth 60FPS animations.

🚀 Getting Started
Installation (For Personal Use)
Since this app is crafted for the ultimate personalized experience, simply archive and export the .app file.

Move AppSwitcher.app and AppSwitcherSetting.app to your Applications folder.

Bypass Gatekeeper: Right-click the app and select Open for the first run.

Grant Permissions:

System Settings > Privacy & Security > Accessibility (Required for the shortcut).

System Settings > Privacy & Security > Screen Recording (Required to list active windows).

[!TIP]
If you are sharing this with a friend, they may need to run xattr -cr /Applications/AppSwitcher.app in the Terminal to clear the quarantine flag.

🛠 Technical Highlights
Active State Blurring: Solved the common macOS "dirty gray" glass issue by forcing the NSVisualEffectView state to .active regardless of window focus.

SMAppService Integration: Modern, robust "Launch at Login" implementation without the need for deprecated legacy helpers.

Zero-Sandbox Sharing: Seamless data synchronization between the main tool and the settings app using a shared UserDefaults suite.

🎨 Visual Identity
The AppSwitcher icon represents the four-core fluidity of the macOS workspace, using a gradient blue palette that mirrors the "Liquid" theme.
