# AGENTS.md

Fluship is a local release cockpit. One saved profile runs an ordered shell pipeline (git, Flutter builds, store uploads, HTML email) against a target Flutter project.

The host app is macOS, Windows, Linux, and Web on Flutter 3.50.0 (Dart `^3.14.0`). Do not add `android/` or `ios/` back as Fluship app targets. Design widgets come from `package:material_ui/material_ui.dart`.

macOS plugins are linked through Swift Package Manager (`enable-swift-package-manager` in `pubspec.yaml`). The project has no Podfile. Do not add CocoaPods back; pick plugins that ship a Swift package.

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

## Dart style

New and edited code uses the newest syntax the SDK constraint allows (Dart 3.14 language version). Do not write the older form of anything below.

- Primary constructor in the class header, fields declared as `final` parameters: `class const CustomState({required final String message, required final String title}) extends Equatable`. Enums too: `enum LayoutTabs(final int value) {`.
- Private fields are private declaring parameters: `class ConsoleBloc({required final IConsoleSessionPool _pool}) extends BaseBloc<ConsoleEvent, ConsoleState>`.
- Super call, asserts, and constructor body go in a `this` block: `this : super(ConfigState.empty()) { on<LoadConfig>(...); }`.
- A field computed from a constructor parameter is initialized where it is declared: `final ProcessKiller _killer = killer ?? const ProcessKiller();`.
- A class or enum with no constructor gets no `()`: `enum AppButtonSize { sm, md, lg }`, `class _AppTabsState extends State<AppTabs>`.
- Constructors that stay in the body (several generative constructors, or a non-const super call in an `@immutable` class) drop the class name: `const new primary({...})`, `factory fromJson(Map<String, dynamic>? json)`.
- `super.key` and other super parameters, never `Key? key` passed along by hand: `class const App({super.key}) extends StatelessWidget`.
- Dot shorthands wherever the context type is known, for enum values, static constants, and constructors: `if (mode == .system) return;`, `crossAxisAlignment: .start`, `padding: .all(value)`, `duration: animate ? _animDuration : .zero`. Keep the type name only where the analyzer needs it (`expect(kind, ConsoleLineKind.error)`, `Curves.easeInOut`, `Icons.add`).
- Switch expressions and patterns instead of `if`/`else if` chains on a value or type: `.running || .idle => 'Pipeline ended in $duration',` and `case RunPipelineCommand(:final sessionId, :final command):`.
- Object patterns to unpack: `for (final MapEntry(:key, value: runner) in _runners.entries)`.
- Null-aware collection elements instead of `if (x != null) x`: `key: ?runner.processId,` and `{?step.id}`.
- Records with named fields instead of positional `$1`/`$2`: `({Map<String, dynamic> json, Type modelType}) _data`.
- Wildcards for unused parameters: `separatorBuilder: (_, _) => SizedBox(height: ft.spacing.sm)`.
- Class modifiers that state intent: `sealed class const ConfigEvent(...)` for bloc event families, `abstract interface class PipelineConsolePort` for contracts, `abstract final class JsonParser` for static-only holders, `final class` for config models.
- `Future.pause(grace)` for a plain wait, not `Future<void>.delayed(grace)`.
- Flutter: `spacing:` on `Row`/`Column` when every gap is the same (`Row(spacing: ft.spacing.sm, children: [...])`), `color.withValues(alpha: 0.12)` not `withOpacity`, `WidgetState` not `MaterialState`.

`analysis_options.yaml` flags in-body constructors that repeat the class name, fields that should be initialized where declared, and `if (x != null) x` elements. Nothing flags a class that should have a primary constructor, so write it that way yourself. `use_primary_constructors` stays off because it also demands `()` on classes and enums that have no constructor.

## Docs

- [docs/architecture.md](docs/architecture.md)
- [docs/flows.md](docs/flows.md)
- [docs/requirements.md](docs/requirements.md)

After Dart edits, run `dart format .` and `flutter analyze`.
