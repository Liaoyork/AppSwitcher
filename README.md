<h1 align="center">



<img src="AppSwitcher_Icon.png" alt="AppSwitcher" width="150">



AppSwitcher



</h1>

<p align="center">
<img src="https://img.shields.io/badge/Platform-macOS%2026%2B-blue?logo=apple" alt="macOS 26+ Only" />
<img src="https://img.shields.io/badge/SwiftUI-6.0-orange?logo=swift" alt="SwiftUI 6.0" />
</p>

Say hello to AppSwitcher, the most fluid way to navigate your macOS workspace! Forget about the traditional, static Cmd + Tab—AppSwitcher transforms your window switching into a dynamic, circular liquid glass experience. Featuring a vibrant frosted visualizer and intuitive gesture-like controls, it’s like having a futuristic command center right under your fingertips!

<p align="center">
<img src="AppSwitcher_Demo.gif" alt="AppSwitcher Demo" />
</p>

# Installation
System Requirements: - macOS 26 tahoe or later

Apple Silicon (M1/M2/M3) or Intel Mac


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
