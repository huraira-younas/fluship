import 'package:equatable/equatable.dart';
import 'base_config.dart';

enum PlayStoreDistribution {
  production,
  internal;

  static PlayStoreDistribution? fromString(String? value) => switch (value) {
    'production' => .production,
    'internal' => .internal,
    _ => null,
  };
}

class DistributionEmail extends Equatable {
  const DistributionEmail({required this.email, required this.name});

  final String email;
  final String name;

  factory DistributionEmail.fromJson(Map<String, dynamic>? json) =>
      DistributionEmail(
        email: json?['email'] as String,
        name: json?['name'] as String,
      );

  DistributionEmail copyWith({String? email, String? name}) =>
      DistributionEmail(email: email ?? this.email, name: name ?? this.name);

  Map<String, dynamic> toJson() => {'email': email, 'name': name};

  @override
  List<Object?> get props => [email, name];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}

final class DistributionConfigModel extends BaseConfig {
  const DistributionConfigModel({
    this.emails = const [],
    this.appstore = false,
    super.enabled = true,
    this.drive = false,
    this.playstore,
  });

  final PlayStoreDistribution? playstore;
  final List<DistributionEmail> emails;
  final bool appstore;
  final bool drive;

  factory DistributionConfigModel.fromJson(Map<String, dynamic>? json) =>
      DistributionConfigModel(
        emails: json?['emails'] as List<DistributionEmail>? ?? [],
        appstore: json?['appstore'] as bool? ?? false,
        enabled: json?['enabled'] as bool? ?? true,
        drive: json?['drive'] as bool? ?? false,
        playstore: PlayStoreDistribution.fromString(
          json?['playstore'] as String?,
        ),
      );

  @override
  DistributionConfigModel copyWith({
    PlayStoreDistribution? playstore,
    List<DistributionEmail>? emails,
    bool? appstore,
    bool? enabled,
    bool? drive,
  }) => DistributionConfigModel(
    playstore: playstore ?? this.playstore,
    appstore: appstore ?? this.appstore,
    enabled: enabled ?? this.enabled,
    emails: emails ?? this.emails,
    drive: drive ?? this.drive,
  );

  @override
  Map<String, dynamic> toJson() => {
    'emails': emails.map((e) => e.toJson()).toList(),
    'playstore': playstore?.name,
    'appstore': appstore,
    'drive': drive,
  };

  @override
  bool? get stringify => true;
}
