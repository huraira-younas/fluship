abstract final class DistributionPlatforms {
  static const _androidExtensions = ['.apk', '.aab'];
  static const _iosExtensions = ['.ipa'];

  /// Derived from what the run actually produced, so a platform whose build
  /// failed is not reported as shipped.
  static String fromArtifacts(Iterable<String> artifactPaths) {
    final platforms = <String>[
      if (_hasAny(artifactPaths, _androidExtensions)) 'Android',
      if (_hasAny(artifactPaths, _iosExtensions)) 'iOS',
    ];

    return platforms.isEmpty ? 'None' : platforms.join(', ');
  }

  static bool _hasAny(Iterable<String> paths, List<String> extensions) =>
      paths.any((path) => extensions.any(path.endsWith));
}
