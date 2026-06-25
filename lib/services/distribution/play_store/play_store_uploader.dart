import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:googleapis/androidpublisher/v3.dart' as androidpublisher;
import 'package:path/path.dart' as p;
import 'dart:io' show Directory, File;

import '../contracts/distribution_logger.dart';
import '../models/distribution_result.dart';
import 'play_store_auth.dart';

abstract interface class PlayStoreUploader {
  Future<String?> findAab(String artifactsDir);

  Future<String> upload({
    required PlayStoreDistribution distribution,
    required String packageName,
    required String saJsonPath,
    DistributionLogger? logger,
    required String aabPath,
  });
}

class GooglePlayPublisherUploader implements PlayStoreUploader {
  const GooglePlayPublisherUploader({PlayStoreAuthClientFactory? authFactory})
    : _authFactory = authFactory ?? const GooglePlayAuthClientFactory();

  final PlayStoreAuthClientFactory _authFactory;

  @override
  Future<String?> findAab(String artifactsDir) async {
    final dir = Directory(artifactsDir);
    if (!await dir.exists()) return null;

    final aabs = <File>[];
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.aab')) {
        aabs.add(entity);
      }
    }

    if (aabs.isEmpty) return null;

    aabs.sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    return aabs.first.path;
  }

  @override
  Future<String> upload({
    required PlayStoreDistribution distribution,
    required String packageName,
    required String saJsonPath,
    DistributionLogger? logger,
    required String aabPath,
  }) async {
    final aabFile = File(aabPath);
    if (!await aabFile.exists()) {
      throw StateError('AAB file not found at $aabPath.');
    }

    final client = await _authFactory.createClient(saJsonPath: saJsonPath);

    try {
      final api = androidpublisher.AndroidPublisherApi(client);

      await _log(logger, '[play] creating edit for $packageName');
      final edit = await api.edits.insert(
        androidpublisher.AppEdit(),
        packageName,
      );

      final editId = edit.id;
      if (editId == null || editId.isEmpty) {
        throw StateError('Play Store edit was created without an id.');
      }

      final aabName = p.basename(aabPath);
      await _log(logger, '[play] uploading: $aabName');

      final length = await aabFile.length();
      final bundle = await api.edits.bundles.upload(
        packageName,
        editId,
        uploadMedia: androidpublisher.Media(
          contentType: 'application/octet-stream',
          aabFile.openRead(),
          length,
        ),
      );

      final versionCode = bundle.versionCode;
      if (versionCode == null) {
        throw StateError('Uploaded bundle did not return a version code.');
      }

      await _log(
        logger,
        '[play] uploaded $aabName (versionCode: $versionCode)',
      );

      final trackName = switch (distribution) {
        .production => 'production',
        .internal => 'internal',
      };

      await _log(logger, '[play] assigning to $trackName track');
      await api.edits.tracks.update(
        androidpublisher.Track(
          track: trackName,
          releases: [
            androidpublisher.TrackRelease(
              versionCodes: [versionCode.toString()],
              status: 'completed',
            ),
          ],
        ),
        packageName,
        editId,
        trackName,
      );

      await _log(logger, '[play] committing edit');
      await api.edits.commit(packageName, editId);

      return aabName;
    } on androidpublisher.DetailedApiRequestError catch (error) {
      final hint = error.status == 403
          ? ' Ensure the service account has release permissions in Play Console.'
          : '';
      throw StateError(
        'Play Store API error (${error.status}): ${error.message}$hint',
      );
    } finally {
      client.close();
    }
  }

  Future<void> _log(DistributionLogger? logger, String message) async {
    if (logger == null) return;
    await logger.logLine(DistributionResult.success('$message\n'));
  }
}
