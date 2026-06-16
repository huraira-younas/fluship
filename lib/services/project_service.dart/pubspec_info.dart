import 'package:equatable/equatable.dart';

final class PubspecInfo extends Equatable {
  const PubspecInfo({
    required this.projectName,
    required this.version,
    this.buildNumber,
  });

  final String? buildNumber;
  final String projectName;
  final String version;

  @override
  List<Object?> get props => [projectName, buildNumber, version];
}
