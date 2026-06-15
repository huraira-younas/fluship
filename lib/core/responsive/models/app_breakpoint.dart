enum AppBreakpoint {
  extraLarge,
  expanded,
  compact,
  medium,
  large;

  String get label => switch (this) {
    .extraLarge => 'extraLarge',
    .expanded => 'expanded',
    .compact => 'compact',
    .medium => 'medium',
    .large => 'large',
  };
}
