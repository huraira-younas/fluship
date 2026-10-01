# Requirements

## Host app

- Flutter SDK 3.47.5. Dart constraint `^3.13.4`.
- Fluship runs on macOS, Windows, Linux, and Web.
- Fluship does not ship an Android or iOS app. Do not add `android/` or `ios/` back as app targets.

## Target project

- A Flutter project with a valid `pubspec.yaml`.
- The pipeline still builds that project's Android artifacts on any host OS that can run `flutter build`.
- iOS builds and App Store upload require macOS.
- Android builds of the target project stay cross-platform.

## Credentials

Only the channels you enable need credentials.

| Channel | Needs |
| --- | --- |
| Google Play | Service account JSON and package name |
| App Store | App Store Connect API key |
| Google Drive | OAuth client JSON |
| Build report | Gmail app password and at least one recipient |

## UI

- Use shared widgets (`AppText`, `AppButton`, `AppCard`, `AppTextField`, `AppCheckbox`, `AppTabs`, `AppToast`) and `context.flushipTheme`.
- Do not add one-off `Text`, `ElevatedButton`, or `Card` when a shared widget fits.
- Layout uses `WidgetX`: `.padAll`, `.padSym`, `.padOnly`, `.expanded`, `.flexible`, `.center`.

## Checks

After Dart edits, run `dart format .` and `flutter analyze`.
