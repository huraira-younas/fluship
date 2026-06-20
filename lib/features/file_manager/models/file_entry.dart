import 'package:equatable/equatable.dart';

class FileEntry extends Equatable {
  const FileEntry({
    required this.isDirectory,
    required this.sizeBytes,
    required this.modified,
    required this.name,
    required this.path,
  });

  final DateTime? modified;
  final bool isDirectory;
  final int? sizeBytes;
  final String name;
  final String path;

  @override
  List<Object?> get props => [modified, isDirectory, sizeBytes, name, path];
}
