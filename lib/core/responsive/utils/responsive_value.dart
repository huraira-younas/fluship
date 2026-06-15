import '../models/app_breakpoint.dart';

T pickResponsiveValue<T>({
  required AppBreakpoint breakpoint,
  required T compact,
  T? extraLarge,
  T? expanded,
  T? medium,
  T? large,
}) {
  final candidates = <AppBreakpoint, T?>{
    .extraLarge: extraLarge,
    .expanded: expanded,
    .compact: compact,
    .medium: medium,
    .large: large,
  };

  const order = <AppBreakpoint>[
    .extraLarge,
    .expanded,
    .compact,
    .medium,
    .large,
  ];

  final index = order.indexOf(breakpoint);

  for (var i = index; i >= 0; i--) {
    final value = candidates[order[i]];
    if (value != null) return value;
  }

  return compact;
}
