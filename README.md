<p align="center">
  <img src="assets/app_logo.png" alt="Fluship logo" width="160">
</p>

<h1 align="center">Fluship</h1>

<p align="center">
  <strong>Ship Flutter apps from one pipeline.</strong><br>
  Build, distribute, and report — without juggling terminals, store consoles, and email.
</p>

---

Fluship is a cross-platform Flutter app that turns your release workflow into a configurable pipeline. Define your steps once in **Config**, hit **Run Pipeline**, and watch everything execute in order — git hygiene, builds, store uploads, and HTML email reports.

**Fluship** = **Flutter** + **ship**

---

## Why Fluship?

Releasing a Flutter app usually means repeating the same manual steps: clean the project, bump the version, commit, build AAB/IPA, upload to Play Store or TestFlight, share artifacts, and notify your team. Fluship automates that entire flow from a single workspace.

Built for **solo developers** and **small teams** who ship regularly and want consistency without maintaining custom shell scripts.

---

## Highlights

| | |
| --- | --- |
| **One-click pipeline** | Run the full release flow from a single button |
| **Configurable stages** | Enable only the steps you need — git, build, distribute, report |
| **Multi-platform builds** | Android AAB/APK on any OS; iOS IPA on macOS |
| **Store distribution** | Google Play, TestFlight, Google Drive, email reports |
| **Developer workspace** | Live console, file browser, process manager, dark themes |

---

## Pipeline

Every run follows the same ordered sequence:

```
App Info → Pre-Git → Common Commands → Android Build → iOS Build
    → Post-Git → Distribution → Post-Build → Build Report
```

| Step | What it does |
| --- | --- |
| **App Info** | Resolves version, build number, and project metadata |
| **Pre-Git** | Stages and commits local changes; optional pull from remote |
| **Common Commands** | `flutter clean`, `pub get`, or `pub upgrade` |
| **Android Build** | AAB for Play Store, APK, or split APK |
| **iOS Build** | Pod install and IPA export *(macOS only)* |
| **Post-Git** | Commits pipeline changes; optional push to remote |
| **Distribution** | Play Store, App Store, Google Drive |
| **Post-Build** | Optional post-compilation actions |
| **Build Report** | HTML summary email via Gmail SMTP |

---

## Workspace

| Tab | Purpose |
| --- | --- |
| **Config** | Toggle pipeline stages, set build params, pick distribution targets |
| **Console** | Live shell output with session tabs — opens automatically on run |
| **Settings** | Project path, store credentials, OAuth keys, themes |
| **Files** | Browse and inspect files in your Flutter project |
| **Processes** | Monitor and terminate running system processes |

**Mobile** — Config, Console, and Settings in the bottom nav.  
**Desktop** — all five tabs in the side panel.

---

## Distribution

Configure credentials once in **Settings**, then enable targets in **Config**:

- **Google Play** — production or internal testing track
- **App Store** — upload IPA to TestFlight *(macOS)*
- **Google Drive** — share build artifacts with selected recipients
- **Build Report** — HTML email with pipeline summary via Gmail SMTP

Distribution options stay disabled until the required credentials are configured.

---

## Quick start

```bash
git clone <repository-url>
cd fluship
flutter pub get
flutter run
```

1. **Settings** — set your Flutter project path
2. **Settings** — add credentials for the stores and channels you use
3. **Config** — enable pipeline stages and set version / git branch
4. **Run Pipeline** — Fluship opens the Console and executes each step

---

## Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.12.0`
- A Flutter project with a valid `pubspec.yaml`
- **macOS** for iOS builds and App Store uploads

**Optional credentials** (only for the channels you enable):

| Channel | What you need |
| --- | --- |
| Google Play | Service account JSON + package name |
| App Store | App Store Connect API key |
| Google Drive | OAuth client JSON |
| Build report | Gmail app password + recipient email |

---

## Tech stack

Flutter · flutter_bloc · get_it · googleapis · mailer · shared_preferences

---

## License

License not yet specified. See repository owner for usage terms.
