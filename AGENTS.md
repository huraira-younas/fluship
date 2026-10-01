# AGENTS.md

Fluship is a local release cockpit. One saved profile runs an ordered shell pipeline (git, Flutter builds, store uploads, HTML email) against a target Flutter project.

The host app is macOS, Windows, Linux, and Web on Flutter 3.47.5 (Dart `^3.13.4`). Do not add `android/` or `ios/` back as Fluship app targets. Design widgets come from `package:material_ui/material_ui.dart`.

## Layers

- `lib/core/`: theme, responsive layout, `BaseBloc`, prefs, logger. No screens.
- `lib/di/`: `GetIt` (`AppLocator`) and `AppBlocProviders`.
- `lib/features/`: screens and blocs. Cross-feature access goes through a contract (`PipelineConfigSource`, `PipelineConsolePort`).
- `lib/services/`: pipeline, shell, distribution, profiles. No widgets.
- `lib/shared/`: models, shell, widgets, extensions.

## UI

New UI uses the fluship-design and fluship-widgets skills. Do not introduce a one-off `Text`, `ElevatedButton`, or `Card` when `AppText`, `AppButton`, or `AppCard` fits. Layout uses `.padAll`, `.padSym`, `.padOnly`, `.expanded`, and `.flexible`.

## Pipeline

Step order is owned by `ConfigPipelineResolver`. Add a stage there and in Config, not inside the `PipelineBloc` loop.

Do not delete Android or iOS pipeline stages. Those build the target project, not the Fluship app.

Leave the snake_case config import in place. It reads saved user profiles.

## Docs

- [docs/architecture.md](docs/architecture.md)
- [docs/flows.md](docs/flows.md)
- [docs/requirements.md](docs/requirements.md)

After Dart edits, run `dart format .` and `flutter analyze`.
