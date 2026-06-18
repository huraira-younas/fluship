part of 'distribution_config.dart';

class DistributionEmail extends Equatable {
  const DistributionEmail({
    this.enabled = true,
    required this.email,
    required this.name,
  });

  final bool enabled;
  final String email;
  final String name;

  factory DistributionEmail.fromJson(Map<String, dynamic> json) {
    final data = json.at<DistributionEmail>();
    return DistributionEmail(
      enabled: data.parse<bool>('enabled', defaultValue: true),
      email: data.parse<String>('email'),
      name: data.parse<String>('name'),
    );
  }

  DistributionEmail copyWith({bool? enabled, String? email, String? name}) =>
      DistributionEmail(
        enabled: enabled ?? this.enabled,
        email: email ?? this.email,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'email': email,
    'name': name,
  };

  @override
  List<Object?> get props => [enabled, email, name];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
