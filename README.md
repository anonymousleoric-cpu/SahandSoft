<div align="center">

<img src="assets/images/sahand_icon.png" width="128" alt="SahandSoft logo" />

# 🛡️ SahandSoft | Secure V2Ray VPN Client

**Modern, minimal, fully redesigned VPN client for Android**

🇮🇷 **[فارسی](README.fa.md)** · 🇬🇧 **English**

Developer: **Daniel Afshari** · Telegram: **[@SahandSoft](https://t.me/SahandSoft)**

</div>

---

## 📖 About

**SahandSoft** is a redesigned Android VPN client built on the Xray core
(`flutter_v2ray`). This edition is a **complete UI/UX rebuild** of the
open-source [BegzarApp](https://github.com/Begzar/BegzarApp) project (MIT):
new brand identity, new design system, Persian-first localization with full
RTL, light & dark Material 3 themes, and a new user-managed configuration
layer.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🎨 **SahandSoft Design System** | Centralized design tokens, soft cards, unified iconography, calm motion |
| 🌗 **Light & Dark themes** | Material 3, follows the system or manual override |
| 🇮🇷 **Persian first** | Default language is Persian with full RTL; English / 中文 / Русский included |
| ⚡ **Real connection states** | Disconnected / Connecting / Connected / Disconnecting — mirrors the actual VPN service |
| 🧩 **Your configs, your device** | Add `vmess` / `vless` / `trojan` / `ss` / `hysteria2` links manually or import a standard V2Ray subscription URL |
| 📊 **Honest stats** | Real download / upload speed, total usage, session duration, measured server delay, public IP check (masked) |
| 🚀 **Automatic best-server** | Measures real delays of all profiles and connects to the fastest one |
| 🚫 **Excluded apps** | Pick apps that bypass the tunnel (persisted and applied to the engine) |
| 🔒 **Root-device guard** | Refuses to run on rooted devices (upstream security policy) |

---

## 📲 Installation (Android)

### Option 1 — Download a ready APK from GitHub Actions
1. Open this repository → **Actions** tab → **Build APK (SahandSoft)**.
2. Open the latest successful run → scroll to **Artifacts** → download **SahandSoft-APKs**.
3. Unzip and install `SahandSoft-universal.apk` (or the APK matching your CPU: `arm64-v8a` for most modern phones).

### Option 2 — Build it yourself
```bash
flutter pub get
flutter build apk --release
# build/app/outputs/flutter-apk/app-release.apk
```

> ℹ️ Release signing uses a keystore provided through repository secrets
> (`ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`).
> For your own production builds, create a private keystore and keep it out
> of version control.

---

## 🧪 Quality gates

Every push to `main` runs on GitHub Actions:

- `flutter pub get`
- `dart run flutter_launcher_icons`
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`

---

## 🏗️ Project structure

```
lib/
├── main.dart                  # app entry, theming, root shell (nav bar / rail)
├── theme/
│   ├── app_tokens.dart        # design tokens (colors, radii, spacing, motion)
│   └── app_theme.dart         # Material 3 light/dark ThemeData + palette
├── core/
│   ├── models.dart            # VpnProfile + URI/subscription helpers (pure Dart)
│   ├── config_repository.dart # profiles, subscription import, prefs
│   └── v2ray_service.dart     # flutter_v2ray wrapper (engine layer)
├── screens/                   # home, servers, settings, language, exclusions, about
└── widgets/                   # connection button, stats, sheets, shared components
```

---

## ⚠️ Known limitations & transparency notes

- **Upstream backend is not part of the public source.** The original
  BegzarApp repository ships its HTTP client with an *empty base URL* — the
  server that provides free configs was intentionally removed from the open
  source. Consequently, the original "fetch config from Begzar's servers"
  flow cannot work from the public code. SahandSoft replaces it with an
  equivalent, fully functional layer: **you provide the configs** (manual
  links or subscription URL) and the app connects using the same Xray engine
  exactly as before. No mock data is used anywhere.
- **Update-check flow removed.** The upstream update dialog pointed at
  Begzar's private backend and is not applicable to this edition.
- **Fonts.** The bundled Gilroy and Dana fonts are commercial typefaces and
  were removed from this redistribution for licensing safety. The app now
  uses **Shabnam** (SIL OFL 1.1).
- **License note.** The upstream repo publishes this code tree under the MIT
  license (see `LICENSE`), while its README states that versions ≥ 5.5.0 are
  developed closed-source. This edition is based on the tree that is
  published under MIT, keeps the original copyright notice, and documents
  all modifications.
- **Testing scope.** CI runs analyze, unit/widget tests and a release build.
  Real-device VPN behavior (permission dialog, tunnel lifecycle) must be
  verified on hardware — no emulator/device is attached to the build
  environment.

---

## 🔐 Privacy

No analytics, no tracking, no data collection. See
[privacy.md](privacy.md). Configs and preferences stay on the device.

---

## 📜 License

This project is a derivative of [BegzarApp](https://github.com/Begzar/BegzarApp)
and is distributed under the **MIT License** — the original copyright notice
is preserved in [`LICENSE`](LICENSE). Fonts: Shabnam (SIL OFL 1.1).

---

## 📞 Contact

| | |
|---|---|
| 👤 Developer | **Daniel Afshari** |
| 📢 Telegram | [@SahandSoft](https://t.me/SahandSoft) |
| 🧱 Upstream project | [BegzarApp](https://github.com/Begzar/BegzarApp) (MIT) |

---

<div align="center">

🛡️ **SahandSoft — a calm, honest VPN client** 🛡️

</div>
