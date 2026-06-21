import 'package:equatable/equatable.dart';

class DriveUploadOutcome extends Equatable {
  const DriveUploadOutcome({
    required this.fileNames,
    required this.label,
    required this.link,
  });

  final List<String> fileNames;
  final String label;
  final String link;

  @override
  List<Object?> get props => [fileNames, label, link];
}
