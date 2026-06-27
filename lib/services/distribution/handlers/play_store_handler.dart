import '../contracts/distribution_context.dart';
import '../play_store/play_store_uploader.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

class PlayStoreHandler implements DistributionHandler {
  const PlayStoreHandler({this.uploader = const GooglePlayPublisherUploader()});

  final PlayStoreUploader uploader;

  @override
  String get name => 'Play Store Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final playstore = context.config.playstore;
    final distribution = playstore?.distribution;
    if (playstore == null || distribution == null) {
      return DistributionResult.skipped('Play Store upload is disabled.');
    }

    final saJsonPath = playstore.saJsonPath?.trim() ?? '';
    if (saJsonPath.isEmpty) {
      return DistributionResult.skipped(
        'Service account JSON is not configured.',
      );
    }

    final packageName = playstore.packageName?.trim() ?? '';
    if (packageName.isEmpty) {
      return DistributionResult.skipped('Package name is not configured.');
    }

    final artifactsDir = context.snapshot.artifactsDir.trim();
    if (artifactsDir.isEmpty) {
      return DistributionResult.skipped(
        'Artifact output directory is unavailable.',
      );
    }

    final aabPath = await uploader.findAab(artifactsDir);
    if (aabPath == null) {
      return DistributionResult.skipped('No AAB artifact found to upload.');
    }

    try {
      final notes = context.config.releaseNotes?.trim();
      final uploaded = await uploader.upload(
        releaseNotes: notes != null && notes.isNotEmpty ? notes : null,
        distribution: distribution,
        packageName: packageName,
        saJsonPath: saJsonPath,
        logger: context.logger,
        aabPath: aabPath,
      );

      return DistributionResult.success(
        'Uploaded to Play Store (${distribution.name}): $uploaded',
      );
    } catch (error) {
      return DistributionResult.failed('Play Store upload failed: $error');
    }
  }
}
