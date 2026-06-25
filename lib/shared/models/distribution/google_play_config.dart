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

class GooglePlayConsoleConfig extends Equatable {
  final PlayStoreDistribution? distribution;
  final String? packageName;
  final String? saJsonPath;

  const GooglePlayConsoleConfig({
    this.distribution,
    this.packageName,
    this.saJsonPath,
  });

  bool get canSend =>
      hasCreds(saJsonPath) && hasCreds(packageName) && distribution != null;

  GooglePlayConsoleConfig copyWith({
    PlayStoreDistribution? distribution,
    String? packageName,
    String? saJsonPath,
  }) => GooglePlayConsoleConfig(
    distribution: distribution ?? this.distribution,
    packageName: packageName ?? this.packageName,
    saJsonPath: saJsonPath ?? this.saJsonPath,
  );

  factory GooglePlayConsoleConfig.fromJson(Map<String, dynamic> json) {
    final data = json.at<GooglePlayConsoleConfig>();
    return GooglePlayConsoleConfig(
      distribution: .fromString(data.parse<String?>('distribution')),
      packageName: data.parse<String?>('packageName'),
      saJsonPath: data.parse<String?>('saJsonPath'),
    );
  }

  Map<String, dynamic> toJson() => {
    'distribution': distribution?.name,
    'packageName': packageName,
    'saJsonPath': saJsonPath,
  };
  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;

  @override
  List<Object?> get props => [distribution, packageName, saJsonPath];
}
