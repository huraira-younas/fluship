import 'dart:io' show Platform;

import '../app_store/app_store_uploader.dart';
import '../contracts/distribution_context.dart';
import '../contracts/distribution_handler.dart';
import '../models/distribution_result.dart';

class AppStoreHandler implements DistributionHandler {
  const AppStoreHandler({this.uploader = const ITmsTransporterUploader()});

  final AppStoreUploader uploader;

  @override
  String get name => 'App Store Upload';

  @override
  Future<DistributionResult> run(DistributionContext context) async {
    final appstore = context.config.appstore;
    if (appstore == null || !appstore.enabled) {
      return DistributionResult.skipped('App Store upload is disabled.');
    }

    if (!Platform.isMacOS) {
      return DistributionResult.skipped('App Store upload requires macOS.');
    }

    final issuerId = appstore.issuerId?.trim() ?? '';
    if (issuerId.isEmpty) {
      return DistributionResult.skipped('App Store Issuer ID is not configured.');
    }

    final apiKeyId = appstore.apiKeyId?.trim() ?? '';
    if (apiKeyId.isEmpty) {
      return DistributionResult.skipped('App Store API Key ID is not configured.');
    }

    final apiKeyPath = appstore.apiKeyPath?.trim() ?? '';
    if (apiKeyPath.isEmpty) {
      return DistributionResult.skipped('App Store Auth Key (.p8) is not configured.');
    }

    final artifactsDir = context.snapshot.artifactsDir.trim();
    if (artifactsDir.isEmpty) {
      return DistributionResult.skipped(
        'Artifact output directory is unavailable.',
      );
    }

    final ipaPath = await uploader.findIpa(artifactsDir);
    if (ipaPath == null) {
      return DistributionResult.skipped('No IPA artifact found to upload.');
    }

    try {
      final uploaded = await uploader.upload(
        appstore: appstore,
        ipaPath: ipaPath,
        logger: context.logger,
      );
      return DistributionResult.success('Uploaded to App Store: $uploaded');
    } catch (error) {
      return DistributionResult.failed('App Store upload failed: $error');
    }
  }
}
