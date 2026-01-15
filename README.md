# Mac Space Astro

Mac Space Astro is a native macOS technical companion designed with truth, restraint, and transparency at its core. It provides deep insights into your Mac's performance without misleading "boost" claims or placebo optimizations.

## 🚀 Vision
Built for the power user who wants to understand *why* their Mac behaves the way it does. We focus on education over hype, providing real data from macOS system APIs.

## 🛠 Tech Stack
- **Language:** Swift 6.0
- **UI Framework:** SwiftUI + AppKit bridging for glassmorphism.
- **Architecture:** Modular architecture (SPM) with separation between System Monitoring, Cleanup logic, and AI services.
- **System Access:** Low-level `mach` APIs for accurate memory and CPU reporting.

## 🧩 Architecture (Modules)
- **CoreSystemKit:** Low-level monitoring (CPU, RAM, Disk). No UI dependencies.
- **CleanupEngine:** Safe, rule-based file analysis. Dry-run by default.
- **AstroAI:** Local intent routing and technical explanation engine.
- **AstroUI:** Premium macOS aesthetic using SF Symbols and glassmorphism.

## 🛡 Privacy & Principles
- **Local Only:** No cloud AI, no telemetry, no background network calls.
- **No Placebos:** No "RAM Cleaners" or fake optimization buttons.
- **Transparent:** Every metric is explained. Every cleanup item is previewable.

## 🧪 Development
This project is organized as a Swift Package. 
To build the app:
```bash
swift build
```

## 🧠 Astro's Philosophy
If a user asks why their RAM is full, Astro explains: *"Free RAM is wasted RAM. macOS uses inactive memory for file caching to speed up your experience."* 
We prioritize honest system behavior over artificial dashboards.
