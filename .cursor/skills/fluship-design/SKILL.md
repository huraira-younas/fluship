---
name: fluship-design
description: Apply Fluship theme tokens for color, spacing, radius, and presets. Use when changing theme, palette, spacing, radius, ThemeData, FlushipThemeExtension, or adding a theme preset.
---

# Fluship design

Product UI reads tokens from `context.flushipTheme`. Do not hardcode a color, padding, or radius when the palette, spacing, or radius already has a field.

## Read the theme

```dart
final ft = context.flushipTheme;
final colors = ft.colors;
final spacing = ft.spacing;
final radius = ft.radius;
```

`FlushipThemeExtension` also exposes `codeBg`, `codeBorder`, `headingColors`, and the source `AppTheme`.

`Theme.of(context)` is only for framework widgets that require `ThemeData` (`MaterialApp`, `Switch`, `Icon`). Prefer `ft.colors` for product color.

## Palette

Use `ThemePalette` fields: `bg`, `cardBg`, `cardBorder`, `text`, `textDim`, `muted`, `section`, `accent`, `accentHover`, `hover`, `disabled`, `success`, `warn`, `danger`, `dangerHover`, `error`, `cmd`, `consoleBg`, `consoleInner`, `consoleBorder`.

`codeBg` and `codeBorder` on the palette alias `consoleInner` and `consoleBorder`. The extension exposes the same names from the `AppTheme`.

## Spacing and radius

Defaults on `ThemeSpacing`: `sm` 8, `md` 15, `lg` 20.

Defaults on `ThemeRadius`: `input` 8, `card` 12, `btn` 10.

Apply spacing with `WidgetX` (`.padAll`, `.padSym`, `.padOnly`), not a raw `Padding` with a magic number.

## Presets

Registered presets (light and dark each): Nord (default), One Dark, Catppuccin Mocha, GitHub, Crimson, Instagram.

Settings lists `AppThemeRegistry.availableThemes` only. Extra `AppThemes` keys that are not registered do not appear.

`ThemeCubit` stores the preset key and `light` or `dark`. It ignores `ThemeMode.system`.

## Add a preset

1. Add an `AppThemes` value with a stable `key` and `displayName`.
2. Add `lib/core/app_theme/presets/<key>.dart` implementing `ThemePresetModule` (`id`, `lightTheme`, `darkTheme`). Build colors with `colorFromHex`.
3. Export it from `lib/core/app_theme/presets/exports.dart`.
4. Append the preset to `ThemePresetRegistry.modules`.

Do not register the preset only in the enum. `registerAll` skips work when the registry is already filled, and the palette UI reads the registry.
