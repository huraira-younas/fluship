---
name: fluship-widgets
description: Build Fluship screens with shared widgets and layout extensions. Use when adding or editing UI, screens, cards, buttons, text, fields, checkboxes, tabs, toasts, or padding.
---

# Fluship widgets

Use the shared widgets in `lib/shared/widgets/`. Do not add a one-off `Text`, `ElevatedButton`, `TextField`, `Checkbox`, or `Card` when one of these fits.

Colors, spacing, and radius come from `context.flushipTheme`. See the fluship-design skill. Do not copy palette values into a screen.

## Text

`AppText` sizes: `AppText.caption`, `.body`, `.subtitle`, `.title`, `.headline`, `.display`.

Role constructors: `AppText.label`, `.accent`, `.danger`, `.success`, `.code`, `.custom`.

Other roles (`secondary`, `muted`, `warn`, `dim`) use the default constructor with `variant` and `size`.

## Buttons

Named constructors: `AppButton.primary`, `.secondary`, `.outline`, `.ghost`, `.danger`, `.success`, `.icon`.

Sizes: `AppButtonSize.sm`, `.md`, `.lg`. Pass `onPressed: null` to disable. Set `isLoading` while work is in flight. `label` or an icon is required.

`AppCtaButton` is the empty-state column: large icon, title, body, optional button.

## Surfaces and inputs

`AppCard` takes `title`, `description`, and `children`. Optional `AppCardState` adds an enable switch. The card already pads with `spacing.lg` and uses `codeBg` plus `cardBorder`.

`AppTextField.floatingLabel` and `AppTextField.label` take `label` and `hint`. Use either `controller` or `initialValue`, not both.

`AppCheckbox` takes `value` and `onChanged`. Set `disabled` when the row cannot be toggled.

## Tabs

`AppTabs` is a scrolling underline tab. `AppTabTiles` is a tile row and can take `titleFor` and `iconFor`. Both take `labels`, the selected `label`, and `onChange`.

## Toast

`AppToast.info`, `.success`, `.warning`, `.error` take a message and an optional title. `AppToast.dismissAll` clears the queue. Do not call `toastification` from a screen.

## Layout extensions

On any widget, from `WidgetX`:

- `.padAll(value)`, `.padSym(h:, v:)`, `.padOnly(l:, t:, r:, b:)`
- `.expanded()`, `.flexible()`
- `.center()`, `.align(align:)`, `.onTap(...)`

`ContextX` exposes `screenWidth`, `screenHeight`, `theme`, `colorScheme`, and `unfocus()`.

Breakpoints live in `lib/core/responsive/`. `context.isTabletOrMobile` is compact or medium (under 840). `context.isDesktop` is wider. The shell uses that split: narrow windows show Config, Console, and Settings. Wide windows add Files and Processes.

## Example

```dart
final ft = context.flushipTheme;

return AppCard(
  title: 'Release',
  description: 'Bump and build the target project.',
  children: [
    AppText.body('Version is taken from Config.'),
    AppButton.primary(label: 'Run', onPressed: onRun),
  ],
).padAll(ft.spacing.md);
```
