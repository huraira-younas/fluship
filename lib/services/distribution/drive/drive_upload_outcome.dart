import 'package:equatable/equatable.dart';

class const DriveUploadOutcome({
  required final List<String> fileNames,
  required final String label,
  required final String link,
}) extends Equatable {
  @override
  List<Object?> get props => [fileNames, label, link];
}
