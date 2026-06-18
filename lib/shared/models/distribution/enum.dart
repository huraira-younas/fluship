part of 'distribution_config.dart';

enum PlayStoreDistribution {
  production,
  internal;

  static PlayStoreDistribution? fromString(String? value) => switch (value) {
    'production' => .production,
    'internal' => .internal,
    _ => null,
  };
}
