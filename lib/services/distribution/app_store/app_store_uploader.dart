import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:path/path.dart' as p;
import 'dart:convert' show LineSplitter, Utf8Decoder;
import 'dart:io' show File, Process;

import '../contracts/distribution_logger.dart';
import '../models/distribution_result.dart';
import 'transporter_progress.dart';

typedef TransporterLine = void Function(String line, int? percent);
typedef TransporterStarter =
    Future<Process> Function(String executable, List<String> arguments);

abstract interface class AppStoreUploader {
  Future<String> upload({
    required IosConfig appstore,
    DistributionLogger? logger,
    required String ipaPath,
    TransporterLine? onLine,
  });
}

class ITmsTransporterUploader implements AppStoreUploader {
  const ITmsTransporterUploader({this.startProcess});

  final TransporterStarter? startProcess;

  @override
  Future<String> upload({
    required IosConfig appstore,
    DistributionLogger? logger,
    required String ipaPath,
    TransporterLine? onLine,
  }) async {
    final args = await _validatedArgs(appstore: appstore, ipaPath: ipaPath);

    // The Fluship app still uses Process.run, same as before this work.
    // Streaming is only for the agent CLI when it asks for live lines.
    if (onLine == null && startProcess == null) {
      return _runToCompletion(args: args, logger: logger, ipaPath: ipaPath);
    }
    return _streamToCompletion(
      args: args,
      logger: logger,
      ipaPath: ipaPath,
      onLine: onLine,
    );
  }

  Future<List<String>> _validatedArgs({
    required IosConfig appstore,
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

    return [
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
    ];
  }

  Future<String> _runToCompletion({
    required List<String> args,
    required String ipaPath,
    DistributionLogger? logger,
  }) async {
    final result = await Process.run('xcrun', args);
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
      throw StateError(_failureDetail(stderrText, stdoutText, result.exitCode));
    }
    return p.basename(ipaPath);
  }

  Future<String> _streamToCompletion({
    required List<String> args,
    required String ipaPath,
    DistributionLogger? logger,
    TransporterLine? onLine,
  }) async {
    final starter = startProcess ?? Process.start;
    final process = await starter('xcrun', args);
    final stdoutTail = <String>[];
    final stderrTail = <String>[];

    Future<void> absorb(Stream<List<int>> stream, List<String> tail) async {
      await for (final line
          in stream
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;
        _keepTail(tail, trimmed);
        onLine?.call(trimmed, parseTransporterPercent(trimmed));
        if (logger != null) {
          await logger.logLine(DistributionResult.success('$trimmed\n'));
        }
      }
    }

    try {
      await Future.wait([
        absorb(process.stdout, stdoutTail),
        absorb(process.stderr, stderrTail),
      ]);
      final exitCode = await process.exitCode;
      if (exitCode != 0) {
        throw StateError(
          _failureDetail(
            stderrTail.join('\n'),
            stdoutTail.join('\n'),
            exitCode,
          ),
        );
      }
      return p.basename(ipaPath);
    } finally {
      process.kill();
    }
  }

  String _failureDetail(String stderrText, String stdoutText, int exitCode) {
    final detail = _trimOutput(stderrText).isNotEmpty
        ? _trimOutput(stderrText)
        : _trimOutput(stdoutText);
    return detail.isEmpty
        ? 'iTMSTransporter exited with code $exitCode.'
        : detail;
  }

  void _keepTail(List<String> tail, String line) {
    tail.add(line);
    if (tail.length > 8) tail.removeAt(0);
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
