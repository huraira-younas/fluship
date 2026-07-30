import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:path/path.dart' as p;
import 'dart:io' show File, Process;

import '../contracts/distribution_logger.dart';
import '../models/distribution_result.dart';

abstract interface class AppStoreUploader {
  Future<String> upload({
    required IosConfig appstore,
    DistributionLogger? logger,
    required String ipaPath,
  });
}

class ITmsTransporterUploader implements AppStoreUploader {
  const ITmsTransporterUploader();

  @override
  Future<String> upload({
    required IosConfig appstore,
    DistributionLogger? logger,
    required String ipaPath,
  }) async {
    final apiKeyPath = appstore.apiKeyPath?.trim() ?? '';
    final issuerId = appstore.issuerId?.trim() ?? '';
    final apiKeyId = appstore.apiKeyId?.trim() ?? '';

    if (issuerId.isEmpty || apiKeyId.isEmpty || apiKeyPath.isEmpty) {
      throw StateError('App Store Connect credentials are incomplete.');
    }

    final keyFile = File(apiKeyPath);
    if (!await keyFile.exists()) {
      throw StateError('Auth key file not found at $apiKeyPath.');
    }

    final ipaFile = File(ipaPath);
    if (!await ipaFile.exists()) {
      throw StateError('IPA file not found at $ipaPath.');
    }

    final result = await Process.run('xcrun', [
      'iTMSTransporter',
      '-m',
      'upload',
      '-assetFile',
      ipaPath,
      '-apiKey',
      apiKeyId,
      '-apiIssuer',
      issuerId,
      '-apiKeyPath',
      apiKeyPath,
      '-v',
      'eXtreme',
    ]);

    final stdoutText = result.stdout.toString().trim();
    final stderrText = result.stderr.toString().trim();

    if (logger != null) {
      for (final line in [
        ...stdoutText.split('\n'),
        ...stderrText.split('\n'),
      ]) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        await logger.logLine(DistributionResult.success('$trimmed\n'));
      }
    }

    if (result.exitCode != 0) {
      final detail = _trimOutput(stderrText).isNotEmpty
          ? _trimOutput(stderrText)
          : _trimOutput(stdoutText);
      throw StateError(
        detail.isEmpty
            ? 'iTMSTransporter exited with code ${result.exitCode}.'
            : detail,
      );
    }

    return p.basename(ipaPath);
  }

  String _trimOutput(String value) {
    final lines = value
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return '';
    if (lines.length <= 5) return lines.join('\n');
    return '${lines.take(5).join('\n')}\n…';
  }
}
