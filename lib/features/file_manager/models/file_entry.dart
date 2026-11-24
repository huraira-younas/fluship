import 'package:equatable/equatable.dart';

class const FileEntry({
  required final bool isDirectory,
  required final int? sizeBytes,
  required final DateTime? modified,
  required final String name,
  required final String path,
}) extends Equatable {
  @override
  List<Object?> get props => [modified, isDirectory, sizeBytes, name, path];
}
