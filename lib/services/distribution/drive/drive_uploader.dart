import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'dart:io' show Directory, File;

import 'drive_upload_outcome.dart';
import 'drive_auth.dart';
import 'drive_mime.dart';

abstract interface class DriveUploader {
  Future<DriveUploadOutcome> upload({
    Future<void> Function(String fileName)? onFileUploaded,
    required GoogleDriveConfig driveConfig,
    required String artifactsDir,
    required String buildNumber,
    required String appName,
    required String version,
  });
}

class GoogleDriveUploader implements DriveUploader {
  const GoogleDriveUploader({DriveAuthClientFactory? authFactory})
    : _authFactory = authFactory ?? const GoogleDriveAuthClientFactory();

  static const _folderMime = 'application/vnd.google-apps.folder';
  final DriveAuthClientFactory _authFactory;

  @override
  Future<DriveUploadOutcome> upload({
    Future<void> Function(String fileName)? onFileUploaded,
    required GoogleDriveConfig driveConfig,
    required String artifactsDir,
    required String buildNumber,
    required String appName,
    required String version,
  }) async {
    final oauthPath = driveConfig.oauthJson?.trim() ?? '';
    if (oauthPath.isEmpty) {
      throw StateError('OAuth client JSON path is missing.');
    }

    final files = await _listArtifactFiles(artifactsDir);
    if (files.isEmpty) {
      throw StateError('No artifact files found in $artifactsDir.');
    }

    final client = await _authFactory.createClient(
      tokenJsonPath: driveConfig.tokenJson,
      oauthJsonPath: oauthPath,
    );

    try {
      final folderName = '$appName v$version+$buildNumber';
      final parentId = driveConfig.folderId?.trim();
      final api = drive.DriveApi(client);

      if (parentId != null && parentId.isNotEmpty) {
        await _trashExistingFolder(api, parentId: parentId, name: folderName);
      }

      final folder = await api.files.create(
        drive.File()
          ..name = folderName
          ..mimeType = _folderMime
          ..parents = parentId != null && parentId.isNotEmpty
              ? [parentId]
              : null,
      );

      final folderId = folder.id;
      if (folderId == null || folderId.isEmpty) {
        throw StateError('Drive folder was created without an id.');
      }

      final uploadedNames = <String>[];
      for (final file in files) {
        final name = p.basename(file.path);
        await onFileUploaded?.call(name);

        final length = await file.length();
        final mime = driveMimeForPath(file.path) ?? 'application/octet-stream';

        await api.files.create(
          uploadMedia: drive.Media(file.openRead(), length, contentType: mime),
          drive.File()
            ..name = name
            ..parents = [folderId],
        );

        uploadedNames.add(name);
      }

      await api.permissions.create(
        drive.Permission()
          ..type = 'anyone'
          ..role = 'reader',
        folderId,
      );

      return DriveUploadOutcome(
        link: 'https://drive.google.com/drive/folders/$folderId',
        fileNames: uploadedNames,
        label: appName,
      );
    } finally {
      client.close();
    }
  }

  Future<List<File>> _listArtifactFiles(String artifactsDir) async {
    final dir = Directory(artifactsDir);
    if (!await dir.exists()) return const [];

    final files = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File) files.add(entity);
    }

    files.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return files;
  }

  Future<void> _trashExistingFolder(
    drive.DriveApi api, {
    required String parentId,
    required String name,
  }) async {
    final query =
        "name = '${_escapeQuery(name)}' "
        "and mimeType = '$_folderMime' "
        "and '$parentId' in parents "
        "and trashed = false";

    final existing = await api.files.list(
      $fields: 'files(id)',
      spaces: 'drive',
      q: query,
    );

    for (final file in existing.files ?? const []) {
      final id = file.id;
      if (id != null && id.isNotEmpty) {
        await api.files.update(drive.File()..trashed = true, id);
      }
    }
  }

  String _escapeQuery(String value) => value.replaceAll("'", r"\'");
}
