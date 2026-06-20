import 'dart:io' show Directory, File, FileSystemEntity;

import 'package:fluship/services/pipeline/paths/fluship_workspace_paths.dart';
import 'package:path/path.dart' as p;

import '../models/file_entry.dart';

class FileManagerRepository {
  const FileManagerRepository({FlushipWorkspacePaths? workspacePaths})
    : _workspacePaths = workspacePaths ?? const FlushipWorkspacePaths();

  final FlushipWorkspacePaths _workspacePaths;

  static const _textExtensions = {
    '.properties',
    '.gradle',
    '.plist',
    '.conf',
    '.json',
    '.yaml',
    '.dart',
    '.html',
    '.yml',
    '.txt',
    '.log',
    '.xml',
    '.csv',
    '.env',
    '.cfg',
    '.ini',
    '.bat',
    '.ps1',
    '.css',
    '.md',
    '.sh',
    '.js',
    '.ts',
  };

  Future<String> resolveOutputsRoot() async {
    final root = await _workspacePaths.resolveRoot();
    return p.join(root, 'outputs');
  }

  bool isTextFile(String path) {
    return _textExtensions.contains(p.extension(path).toLowerCase());
  }

  Future<String> readTextFile(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File not found: $path');
    }

    return file.readAsString();
  }

  Future<List<FileEntry>> listDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return const [];
    }

    final entities = await directory.list().toList();
    final entries = <FileEntry>[];

    for (final entity in entities) {
      entries.add(await _toEntry(entity));
    }

    entries.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }

      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return entries;
  }

  Future<FileEntry> _toEntry(FileSystemEntity entity) async {
    final stat = await entity.stat();
    final isDirectory = entity is Directory;

    return FileEntry(
      sizeBytes: isDirectory ? null : stat.size,
      name: p.basename(entity.path),
      isDirectory: isDirectory,
      modified: stat.modified,
      path: entity.path,
    );
  }
}
