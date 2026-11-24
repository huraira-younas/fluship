import 'package:equatable/equatable.dart';

final class const PubspecInfo({
  required final String projectName,
  required final String version,
  final String? buildNumber,
}) extends Equatable {
  @override
  List<Object?> get props => [projectName, buildNumber, version];
}
