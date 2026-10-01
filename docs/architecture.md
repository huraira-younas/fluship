# Architecture

Fluship is a local release cockpit. One saved config drives an ordered shell pipeline: git, Flutter builds, store uploads, and an HTML email. It is a desktop and web app, not a CI system.

Fluship itself runs on macOS, Windows, Linux, and Web. It does not ship an Android or iOS app. The pipeline still builds and uploads the target Flutter project's Android and iOS artifacts.

## Layers

New code follows these boundaries.

| Layer | Path | Owns | Does not own |
| --- | --- | --- | --- |
| Core | `lib/core/` | Theme, responsive layout, `BaseBloc`, JSON helpers, `SharedPrefs`, logger | Feature screens |
| DI | `lib/di/` | `GetIt` registration and `AppBlocProviders` | Business rules |
| Features | `lib/features/` | Screens, blocs, feature widgets | Another feature's internals |
| Services | `lib/services/` | Pipeline, shell, distribution, project profiles, file picker | Widgets |
| Shared | `lib/shared/` | Models, app shell, reusable widgets, extensions | Feature-specific flow |

A feature may depend on another feature only through a contract. Today those contracts are `PipelineConfigSource` and `PipelineConsolePort`.

## Boot

1. `main` calls `AppDependencies.initialize`.
2. That ensures `WidgetsFlutterBinding`, loads `SharedPrefs`, then calls `AppLocator.initialize`.
3. `App` builds `MultiBlocProvider` and `MaterialApp`.

`ThemeCubit` and `NavigatorCubit` are created in the widget tree. `ConfigBloc`, `ConsoleBloc`, and `PipelineBloc` come from `GetIt`. `FileManagerBloc` and `ProcessManagerBloc` are factories created by their screens.

`ConfigBloc` loads the active profile on creation (`LoadConfig`).

## Shell

`LayoutScreen` watches `NavigatorCubit` (`LayoutTabs`) and swaps the body.

| Tab | Screen | Width |
| --- | --- | --- |
| Config | `ConfigScreen` | All widths. Scrolls. |
| Console | `ConsoleScreen` | All widths. Fills the body. |
| Settings | `SettingsScreen` | All widths. Scrolls. |
| Files | `FileManagerScreen` | Wide layout only. Fills the body. |
| Processes | `ProcessManagerScreen` | Wide layout only. Fills the body. |

Narrow widths (`context.isTabletOrMobile`, compact or medium breakpoint) show Config, Console, and Settings. Wider layouts add Files and Processes in a side panel. The narrow shell is for small desktop windows and web. It is not an Android or iOS target.

Viewports under `LayoutConstraints.material3.minWidth` (360) show a short message instead of the shell.

## State

`ConfigBloc` holds the active project profile: paths, version, git, Android build, iOS build, distribution, and the report. It persists through `ProjectProfilesStore` and `SharedPrefs`. Import still accepts older snake_case JSON. That is saved user data.

`ConsoleBloc` owns shell sessions through `IConsoleSessionPool`.

`PipelineBloc` reads config and writes console output only through `PipelineConfigSource` and `PipelineConsolePort`. It does not import those feature blocs directly. Step order lives in `ConfigPipelineResolver`, not in the bloc loop.

`BaseBloc` wraps handlers with logging and a `CustomState` error on the current state.

## Themes

Presets that are actually registered, each with a light and dark `AppTheme`:

- Nord (default)
- One Dark
- Catppuccin Mocha
- GitHub
- Crimson
- Instagram

`ThemePresetRegistry.registerAll` fills `AppThemeRegistry`. The Settings palette lists `AppThemeRegistry.availableThemes` only. `AppThemes` has extra keys that are not registered. Do not treat those as selectable themes.

`AppThemeDataMapper` turns an `AppTheme` into `ThemeData` plus `FlushipThemeExtension`. Product UI reads `context.flushipTheme` for palette, spacing, and radius.

`ThemeCubit` persists the preset key and light or dark mode. `setThemeMode` ignores `ThemeMode.system`.

## Distribution handlers

`DistributionModule.createHandlerMap` registers:

| Kind | Handler | Uploader |
| --- | --- | --- |
| Play Store | `PlayStoreHandler` | `GooglePlayPublisherUploader` |
| App Store | `AppStoreHandler` | `ITmsTransporterUploader` |
| Drive | `GoogleDriveHandler` | `GoogleDriveUploader` |
| Report | `ReportEmailHandler` | `GmailSmtpClient` |

These upload the target project's artifacts. They are not Fluship app targets.
