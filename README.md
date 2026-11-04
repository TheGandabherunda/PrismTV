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

### *A Clean, Self-Contained Smart TV Broadcast & Live Streaming Platform*
**Brought to you by [TheGandabherunda](https://github.com/TheGandabherunda)**

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Build & Test](https://github.com/TheGandabherunda/PrismTV/actions/workflows/ci.yml/badge.svg)](https://github.com/TheGandabherunda/PrismTV/actions/workflows/ci.yml)
[![Android TV](https://img.shields.io/badge/Platform-Android%20TV%20%7C%20Fire%20TV-3DDC84?logo=android&logoColor=white)](https://developer.android.com/tv)

</div>

---

## 🌟 Overview

**PrismTV** is a high-performance, single-repository Smart TV platform engineered from the ground up for the **10-foot television experience**. 

Unlike fragmented community setups that force users to configure **Termux**, run command-line daemon scripts, set up local port forwards (`localhost:5001`), and bridge into generic 3rd-party IPTV players, **PrismTV unifies everything into one standalone, installable Smart TV app**:

* ✅ **Zero Termux / Background Daemons**: Direct on-device HTTPS authentication and token renewal.
* ✅ **Zero 3rd-Party Players Required**: Built-in hardware-accelerated video player with native HLS/DASH header injection.
* ✅ **10-Foot D-Pad Remote Experience**: Fluid navigation designed specifically for Android TV, Google TV, and Fire TV remotes.
* ✅ **Extensible Multi-Source Architecture**: Ready for Live TV today, and modularly architected to ingest Movies, Series, and custom VOD catalogs tomorrow.

---

## 🏛️ Architecture

PrismTV adheres to strict **MVVM (Model-View-ViewModel)** separation and dependency injection:

```
lib/
├── core/
│   ├── constants/             # API endpoints, Prism dark palette, TV dimensions
│   └── storage/               # Hive persistence (Auth, Cache, Settings)
│
├── data/
│   ├── models/                # Pure domain models (Channel, EPG Program, AuthSession)
│   ├── providers/             # Source interfaces (ILiveTvSource, IVodSource, JioLiveSource)
│   └── repositories/          # Repository layer (AuthRepository, ChannelRepository)
│
├── routes/                    # GetX routing & page bindings
│
└── views/
    ├── splash/                # Branded animated bootloader
    ├── auth/                  # TV remote-friendly number pad & OTP verification
    ├── home/                  # 10-foot TV guide, category shelf & live EPG preview
    └── player/                # Fullscreen hardware video player with OSD & quick drawer
```

---

## 🎮 TV Remote Navigation Controls

| Remote Key | Action in Home Screen | Action in Fullscreen Player |
| :--- | :--- | :--- |
| **D-Pad Up (▲)** | Move to upper channel row / categories | **Next Channel** |
| **D-Pad Down (▼)** | Move to lower channel row / EPG bar | **Previous Channel** |
| **D-Pad Left (◀)** | Navigate to sidebar navigation | **Open Quick Channel Drawer** |
| **D-Pad Right (▶)** | Navigate across channel cards | Dismiss Quick Channel Drawer |
| **D-Pad Center / OK** | Watch focused channel | **Toggle On-Screen Display (OSD)** |
| **Back / Escape** | Exit category / return to sidebar | Return to TV Guide |

---

## 🚀 Building & Running

### Prerequisites
* Flutter SDK `^3.47` or later
* Android SDK with Android TV (Leanback) target
* Java 17

### 1. Run on Connected Device / Windows Desktop
```bash
# Get dependencies
flutter pub get

# Run unit tests
flutter test

# Run directly on Windows or connected Android TV via ADB
flutter run
```

### 2. Build Release Android TV APK
```bash
flutter build apk --release
```
The compiled APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Install it to any FireStick, Chromecast with Google TV, or Android TV box via ADB:
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔒 Privacy & Open Architecture

* **Decoupled Sources:** The app uses clean abstract interfaces (`ILiveTvSource`, `IVodSource`). Third-party media sources can be connected without altering UI or playback engines.
* **On-Device Storage:** All authentication tokens and user favorites remain exclusively within the local encrypted Hive storage on the user's TV device.
* **Zero Analytics / Telemetry:** No user telemetry or tracking.

---

## 📜 License

Distributed under the **MIT License**. See `LICENSE` for details.
