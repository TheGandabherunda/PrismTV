# Changelog

All notable changes to **PrismTV** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-11-04

### Added
- **Core Architecture**:
  - Pure MVVM architecture powered by GetX dependency injection and routing.
  - Decoupled `ILiveTvSource` and `IVodSource` interfaces for modular multi-source streaming.
  - Native `JioLiveSource` implementation for live streaming, dynamic manifest fetching, and automatic session renewal.
  - Secure offline caching and session persistence using Hive (`prism_auth_box`, `prism_settings_box`, `prism_cache_box`).
- **10-Foot Smart TV UI (Cinematic Dark / Prism Design System)**:
  - Full D-Pad remote navigation support (Up/Down/Left/Right/OK/Back).
  - Responsive channel cards with focus glow, HD tags, and favorite pin indicators.
  - Category carousels supporting Kannada (`ಕನ್ನಡ`), Entertainment, Movies, Sports, News, Music, Kids, and Favorites.
  - Live EPG preview pane with real-time progress bars, scheduling, and channel summaries.
  - Fullscreen hardware-accelerated video player with OSD controls and instant channel switching (▲/▼).
  - Quick channel drawer accessible during video playback without leaving the stream (◀).
  - Standalone TV authentication interface with remote-friendly numpad and instant Demo Preview mode.
- **Android TV Integration**:
  - Android TV Leanback launcher intent and banner support.
  - Touchscreen and hardware requirements set to non-mandatory for universal Smart TV / FireStick compatibility.
- **CI / CD Automation**:
  - GitHub Actions automated testing & static analysis (`ci.yml`).
  - Automated Release APK builder (`build_apk.yml`).
  - Tag-triggered GitHub Releases with automated `.apk` binary distribution (`release.yml`).

