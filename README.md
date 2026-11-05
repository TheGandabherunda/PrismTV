# PrismTV (ದರ್ಶನ · Prism)

<div align="center">

```
  ██████╗ ██████╗ ██╗███████╗███╗   ███╗████████╗██╗   ██╗
  ██╔══██╗██╔══██╗██║██╔════╝████╗ ████║╚══██╔══╝██║   ██║
  ██████╔╝██████╔╝██║███████╗██╔████╔██║   ██║   ██║   ██║
  ██╔═══╝ ██╔══██╗██║╚════██║██║╚██╔╝██║   ██║   ╚██╗ ██╔╝
  ██║     ██║  ██║██║███████║██║ ╚═╝ ██║   ██║    ╚████╔╝ 
  ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝╚═╝     ╚═╝   ╚═╝     ╚═══╝  
```

### *Cinematic, Self-Contained Smart TV, Mobile & Web Live Broadcast Streaming Platform*
**Crafted with passion by [The Gandabherunda](https://github.com/TheGandabherunda)**

[![Flutter](https://img.shields.io/badge/Flutter-3.13+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platforms](https://img.shields.io/badge/Platforms-Android%20TV%20%7C%20Fire%20TV%20%7C%20Mobile%20%7C%20Web%20%7C%20Windows%20%7C%20macOS-8A2BE2)](https://github.com/TheGandabherunda/PrismTV)
[![GitHub Releases](https://img.shields.io/github/v/release/TheGandabherunda/PrismTV?color=A839C7&logo=github)](https://github.com/TheGandabherunda/PrismTV/releases)

</div>

---

## 🌟 Overview

**PrismTV** is a high-performance, universal live streaming platform engineered from the ground up for both the **10-foot television experience** (Android TV, Google TV, Fire TV, webOS) and **touch mobile devices** (Android phones, tablets, mobile web, and desktop).

Unlike fragmented community setups that force users to configure Termux, run command-line daemon scripts, and bridge into generic 3rd-party IPTV players, **PrismTV unifies the entire live broadcast experience into one standalone, self-updating application**:

* 💎 **Pure Optical Progressive Blur**: Apple-inspired multi-slice optical diffusion header with zero color tint or scrim artifacts.
* 📺 **Universal 1080p Full HD DASH Streaming**: Direct MPD manifest parsing, native multi-track audio switching, and smooth adaptive bitrate resolution choices (1080p, 720p, 540p, 360p, 180p, Auto).
* 🔄 **In-App GitHub OTA Self-Updates**: Built-in Over-The-Air updater detects new GitHub releases on startup and via Settings. Downloads and installs in-place without losing user credentials, favorites, or settings!
* 🎮 **100% Remote D-Pad & Keyboard Accessible**: Fluid navigation designed specifically for TV remotes, standard keyboards, and touchscreens.
* 📱 **Adaptive Touch Mobile UI**: Automatically adapts on mobile screens (< 800px) with full-width shelves, expanding search bar, and frosted modal filter bottom sheet.
* ⚡ **Zero Daemons / Zero Termux Required**: Direct on-device HTTPS authentication, token renewal, and encrypted Hive local persistence.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| **Cinejoy Glassmorphism** | Luxurious obsidian cards with dynamic ambient glow matching channel brand logos. |
| **Progressive Optical Diffusion** | Smooth 115px top header blur that gently fades into the background canvas. |
| **In-Place OTA Updates** | Automatic background GitHub releases check + in-app direct APK installer without uninstalling. |
| **Multi-Audio Selector** | Choose between original regional broadcast audio tracks (Kannada, Hindi, English, Tamil, Telugu, etc.) with real-time sync. |
| **Resolution Picker** | Instant switching between 1080p Full HD, 720p HD, 540p, 360p, 180p, and Auto. |
| **Channel Carousel Tray** | Sliding bottom drawer organized by categories synced with home screen filters. |
| **Floating Miniplayer** | YouTube-style Picture-in-Picture miniplayer pinned to the bottom-right corner during navigation. |
| **Universal TV Remote Guide** | Integrated in Settings for instant D-pad and keyboard shortcut reference. |

---

## 🎮 Universal Controls (Remote & Keyboard)

PrismTV is built from the ground up with full D-Pad focus traversal and keyboard hotkeys:

### Fullscreen Live Player
| Key / Remote Button | Action |
| :--- | :--- |
| **Down Arrow (▼) / Key C** | Open Categorized Channel Tray (browse while watching) |
| **Up Arrow (▲)** | Show Program Info & Player Header |
| **Left / Right (◀ / ▶) / CH +/-** | Previous / Next Channel (with live feedback toast) |
| **OK / Enter / Space** | Toggle Play / Pause & Show Controls |
| **0 – 9 Keypad** | Direct Channel Number Dialing (e.g. `1 0 4`) |
| **Key Q** | Open Stream Quality Dialog (1080p, 720p, etc.) |
| **Key A** | Open Multi-Audio Language Selector |
| **Key M** | Toggle Mute / Unmute Audio |
| **Key F** | Toggle Fullscreen Mode |
| **Back / Escape** | Close Menus / Channel Tray or Exit to Home Screen |

### Home Screen & Guide
| Key / Remote Button | Action |
| :--- | :--- |
| **D-Pad / Arrow Keys** | Navigate Channel Cards & Category Shelves |
| **OK / Enter / Space** | Play Selected Channel |
| **Key / or Tab** | Focus Instant Search Bar |
| **Key S** | Open App Settings Modal |
| **Key P** | Open Account & Profile Modal |
| **Key F** | Toggle Favorite Channel |
| **Escape** | Clear Search Query / Reset Active Filter |

---

## 🏛️ Project Architecture

PrismTV adheres to strict **MVVM (Model-View-ViewModel)** separation with GetX state management:

```
lib/
├── core/
│   ├── constants/             # AppColors (Obsidian, Prism Gradient, Glows), AppDimens
│   ├── services/              # AmbientColorService, AppUpdateService, QualityBridge
│   ├── storage/               # HiveService (Auth, Settings, Custom Proxy URL)
│   └── widgets/               # PrismTriangleLogo, ShimmerLoading
│
├── data/
│   ├── models/                # ChannelModel, EpgProgramModel, QualityOption, AudioTrackOption
│   ├── providers/             # JioLiveSource (m3u8/mpd manifest generator & auth)
│   └── repositories/          # AuthRepository, ChannelRepository
│
├── routes/                    # AppPages, AppRoutes
│
└── views/
    ├── splash/                # Animated branded startup screen
    ├── auth/                  # Responsive phone number entry & OTP verification
    ├── home/                  # Dynamic shelves, progressive blur header, preview column
    │   └── widgets/           # ChannelCard, SettingsDialog, AccountDialog
    └── player/                # Hardware-accelerated player with OSD & ChannelCarouselTray
        └── widgets/           # OsdOverlay, ChannelCarouselTray, FloatingMiniplayer
```

---

## 🔄 In-App GitHub OTA Self-Updates

PrismTV includes a built-in Over-The-Air updater that integrates directly with GitHub Releases:

1. **Automated Detection**: On app boot, PrismTV queries `https://api.github.com/repos/TheGandabherunda/PrismTV/releases/latest`.
2. **Notification Banner**: If a newer version tag exists on GitHub, a floating notification appears on the Home screen.
3. **Settings Dialog**: The **Updates** tab allows users to manually click **"Check for Updates"**, read the changelog, and view the release date.
4. **Direct In-Place Install**: On Android, clicking **"Download & Install Update"** streams the APK to local cache with a live progress bar, then launches Android's native package installer.
   > **Note**: Because the APK package name (`org.thegandabherunda.prismtv`) and keystore signature match, Android upgrades the app in-place without losing any saved user data!

---

## 🚀 Building & Running

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.13` or later
* Android SDK (API 34+ / Android TV Leanback support)
* Node.js 18+ (for local web proxy server)

### 1. Install Dependencies & Run Tests
```bash
# Clone the repository
git clone https://github.com/TheGandabherunda/PrismTV.git
cd PrismTV

# Fetch Flutter dependencies
flutter pub get

# Run test suite
flutter test

# Verify analyzer
flutter analyze
```

### 2. Run Locally on Android / Desktop / Web
```bash
# Run on connected Android TV or Phone
flutter run

# Run on Windows Desktop
flutter run -d windows

# Run on Web (Chrome)
flutter run -d chrome
```

### 3. Build Production Releases
```bash
# Android Universal APK (TV & Mobile)
flutter build apk --release

# Split Per-ABI APKs (smaller file size for arm64-v8a / armeabi-v7a)
flutter build apk --split-per-abi --release

# Web Production Bundle
flutter build web --release
```

---

## 🔒 Privacy & Open Architecture

* **Decoupled Architecture:** Clean abstract providers allow connecting custom IPTV sources or local servers without altering UI or player logic.
* **On-Device Storage:** All authentication tokens, credentials, and favorites remain strictly within local encrypted Hive storage on the user's device.
* **Zero Telemetry:** No user analytics, telemetry, or tracking.

---

## 📜 License

Distributed under the **MIT License**. See [LICENSE](LICENSE) for details.

---

<div align="center">
  <b>Crafted with ❤️ by <a href="https://github.com/TheGandabherunda">The Gandabherunda</a></b><br>
  <i>Empowering digital freedom through elegant, open software.</i>
</div>
