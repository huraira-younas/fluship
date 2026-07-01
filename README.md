<p align="center">
  <img src="assets/app_logo.png" alt="Fluship logo" width="160">
</p>

<h1 align="center">Fluship</h1>

<p align="center">
  <strong>Ship Flutter apps from one pipeline. No chaos. Just vibes.</strong><br>
  Build, distribute, and report without juggling terminals, store consoles, and random email threads.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-^3.12.0-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Windows%20%7C%20Web-lightgrey" alt="Platforms">
  <img src="https://img.shields.io/badge/state-management-flutter__bloc-8B5CF6" alt="flutter_bloc">
  <img src="https://img.shields.io/badge/license-MIT-22C55E" alt="MIT License">
  <img src="https://img.shields.io/badge/open%20source-yes-FF6B6B" alt="Open Source">
</p>

<p align="center">
  <code>Fluship</code> = <strong>Flutter</strong> + <strong>ship</strong> 🚀
</p>

<p align="center">
  <sub>
    Crafted with love by
    <a href="https://github.com/huraira-younas"><strong>Huraira</strong></a>
    💙
  </sub>
</p>

---

## The vibe check

You know that release day feeling? Clean the project. Bump the version. Commit. Build the AAB. Build the IPA. Upload to Play Store. Pray TestFlight cooperates. Email the team a screenshot of a terminal that nobody wants to read.

Yeah. We felt that too.

**Fluship** is a cross-platform Flutter app that turns your entire release workflow into one configurable pipeline. Define your steps once in **Config**, smash **Run Pipeline**, and watch everything execute in order: git hygiene, builds, store uploads, and a proper HTML email report at the end.

Built for **solo devs** and **small teams** who ship regularly and want consistency without maintaining a folder of cursed shell scripts that only one person understands.

**Fluship is open source.** Fork it, star it, contribute PRs, or run it as-is. The code is yours to use under the [MIT License](LICENSE).

No cap, this is literally your release flow on autopilot.

---

## Why you'll actually use this

| Pain point | How Fluship fixes it |
| --- | --- |
| Same manual steps every release | One button runs the full pipeline |
| Scripts break on different machines | Configurable stages, saved in the app |
| Android on Windows, iOS on Mac | Multi-platform builds where it makes sense |
| Store uploads are a whole thing | Google Play, TestFlight, Drive, email reports |
| Terminal tabs everywhere | Live console with session tabs, built in |
| Ugly dev tools | 6 aesthetic themes because we're not animals |

---

## Highlights (the main character energy)

✨ **One-click pipeline**  
Run the full release flow from a single button. That's it. That's the tweet.

🧩 **Configurable stages**  
Enable only what you need: git, build, distribute, report. Your pipeline, your rules.

📱 **Multi-platform builds**  
Android AAB/APK on any OS. iOS IPA on macOS. Split APKs if you're into that.

🛒 **Store distribution**  
Google Play, TestFlight, Google Drive uploads, and HTML email reports. All from one place.

🖥️ **Developer workspace**  
Live console, file browser, process manager, and dark themes that actually slap.

---

## The pipeline (step by step, no skips)

Every run follows the same ordered sequence. Consistency is the whole point.

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

Think of it like a playlist. Same order. Same energy. Every time.

---

## Workspace tour

Fluship isn't just a pipeline runner. It's a whole dev workspace.

| Tab | Purpose |
| --- | --- |
| **Config** | Toggle pipeline stages, set build params, pick distribution targets |
| **Console** | Live shell output with session tabs (opens automatically on run) |
| **Settings** | Project path, store credentials, OAuth keys, themes |
| **Files** | Browse and inspect files in your Flutter project |
| **Processes** | Monitor and terminate running system processes |

**Mobile:** Config, Console, and Settings in the bottom nav.  
**Desktop:** All five tabs in the side panel. Bigger screen, bigger pipeline energy.

---

## Distribution channels

Configure credentials once in **Settings**, then flip on targets in **Config**:

| Channel | What you get |
| --- | --- |
| **Google Play** | Production or internal testing track upload |
| **App Store** | Upload IPA to TestFlight *(macOS)* |
| **Google Drive** | Share build artifacts with selected recipients |
| **Build Report** | HTML email with full pipeline summary via Gmail SMTP |

Distribution options stay disabled until the required credentials are set up. No accidental uploads. You're welcome.

---

## Themes (because aesthetics matter)

Pick your vibe in **Settings**. Each preset ships with light and dark modes:

| Theme | Energy |
| --- | --- |
| **Nord** | Clean, calm, default king |
| **Catppuccin Mocha** | Cozy dev hours |
| **One Dark** | Classic IDE nostalgia |
| **Dracula** | Purple hours |
| **Tokyo Night** | Late night ship sessions |
| **Gruvbox** | Warm retro terminal |
| **Solarized Dark** | OG readable dark |
| **GitHub** | Familiar and safe |
| **Crimson** | Bold and loud |
| **Instagram** | Gradient main character |
| **WhatsApp** | Green and go |

---

## Quick start (get shipping in 4 steps)

```bash
git clone <repository-url>
cd fluship
flutter pub get
flutter run
```

Then inside the app:

1. **Settings** → set your Flutter project path
2. **Settings** → add credentials for the stores and channels you use
3. **Config** → enable pipeline stages and set version / git branch
4. **Run Pipeline** → Fluship opens the Console and executes each step

That's the whole onboarding. Low effort, high reward.

---

## Requirements

**Core (non-negotiable):**

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `^3.12.0`
- A Flutter project with a valid `pubspec.yaml`

**Platform specific:**

- **macOS** required for iOS builds and App Store uploads

**Optional credentials** (only for the channels you enable):

| Channel | What you need |
| --- | --- |
| Google Play | Service account JSON + package name |
| App Store | App Store Connect API key |
| Google Drive | OAuth client JSON |
| Build report | Gmail app password + recipient email |

---

## Tech stack

The app is built with the good stuff:

| Layer | Tools |
| --- | --- |
| UI | Flutter, Material Design |
| State | `flutter_bloc`, `equatable` |
| DI | `get_it` |
| Distribution | `googleapis`, `googleapis_auth`, `mailer` |
| Storage | `shared_preferences` |
| Utilities | `file_picker`, `url_launcher`, `toastification`, `intl`, `http`, `path`, `xml` |

---

## Project structure (for the curious)

```
lib/
├── core/           # Theme system, responsive layout, JSON parsing
├── di/             # Dependency injection setup
├── features/       # Config, Console, Settings, File Manager, Pipeline, Processes
├── services/       # Pipeline execution, shell console, distribution handlers
└── shared/         # Reusable widgets, models, extensions
```

---

## FAQ (real questions, real answers)

**Can I run only Android on Windows?**  
Yes. Disable iOS stages. Android builds work cross-platform.

**Do I need every credential on day one?**  
Nope. Only configure what you actually use. Everything else stays off.

**What if a step fails?**  
Check the **Console** tab. Live output shows exactly what happened. Fix it, rerun.

**Is this replacing CI/CD?**  
Not really. It's your local release cockpit. Pair it with GitHub Actions if you want, or run it solo. Your call.

---

## Open source & license

Fluship is **free and open source software**, released under the **MIT License**.

That means you can:

| You can | Details |
| --- | --- |
| **Use it** | Personal projects, client work, side hustles, whatever |
| **Modify it** | Customize the pipeline, UI, or distribution flow |
| **Share it** | Ship forks, internal tools, or your own spin on Fluship |
| **Contribute back** | PRs, issues, and docs are always welcome |

Just keep the copyright notice and license text when you redistribute. Full legal text lives in [LICENSE](LICENSE).

**Contributing:** Found a bug? Want a feature? Open an issue or send a PR on [GitHub](https://github.com/huraira-younas/fluship). Community contributions make this project better for everyone.

---

## Made with love

Fluship wasn't built in a vacuum. It was built by a dev who got tired of release day chaos and decided to fix it for everyone.

| | |
| --- | --- |
| **Developer** | [Huraira](https://github.com/huraira-younas) |
| **GitHub** | [@huraira-younas](https://github.com/huraira-younas) |
| **Repo** | [github.com/huraira-younas/fluship](https://github.com/huraira-younas/fluship) |

Developed with care, shipped with intention, and shared with the community because good tools deserve to be open.

If Fluship saved you from a messy release night, a ⭐ on the repo goes a long way. Seriously, it makes my day.

---

<p align="center">
  <sub>
    Built with Flutter · Shipped with Fluship · Open source<br>
    Made with love by <a href="https://github.com/huraira-younas"><strong>Huraira</strong></a> 🫡
  </sub>
</p>
