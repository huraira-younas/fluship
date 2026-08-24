import 'dart:io';

import '../io_helpers.dart';
import '../share/apk_collect.dart';

class DistCliFailure {
  const DistCliFailure(this.code, this.message);

  final int code;
  final String message;
}

({Map<String, dynamic> secrets, Map<String, dynamic> cache}) loadAgentJson(
  Map<String, String> parsed,
) {
  return (
    secrets: readJsonFile(resolveAgentPath(parsed['secrets'], 'secrets.json')),
    cache: readJsonFile(
      resolveAgentPath(parsed['cache'], 'pipeline-cache.json'),
    ),
  );
}

Future<void> runDistMain({
  required List<String> args,
  required String usage,
  required Future<void> Function(Map<String, String> parsed) run,
}) async {
  final parsed = parseCliFlags(args);
  if (parsed.containsKey('help')) {
    stdout.writeln(usage);
    return;
  }
  try {
    await run(parsed);
  } catch (error) {
    stderr.writeln('$error');
    exitCode = 1;
  }
}

String secretString(Map<String, dynamic> secrets, String key) {
  return asString(secrets[key]);
}

List<String> existingFiles(Iterable<String> paths) {
  return [
    for (final path in paths)
      if (fileExists(path)) path,
  ];
}

String? newestArtifact(String directory, String extension) {
  final dir = Directory(directory);
  if (!dir.existsSync()) return null;
  final files = [
    for (final entity in dir.listSync())
      if (entity is File &&
          fileNameOf(entity.path).toLowerCase().endsWith(extension))
        entity,
  ];
  if (files.isEmpty) return null;
  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  return files.first.path;
}

List<String> resolveApks({
  required List<String> explicit,
  required String outputDir,
}) {
  final fromFlags = existingFiles(explicit);
  if (fromFlags.isNotEmpty) return fromFlags;
  if (outputDir.trim().isEmpty) return const [];
  return collectShareApks(outputDir: outputDir);
}

String? resolveOneArtifact({
  required String? explicit,
  required String outputDir,
  required String extension,
}) {
  final path = explicit?.trim() ?? '';
  if (path.isNotEmpty) return path;
  if (outputDir.trim().isEmpty) return null;
  return newestArtifact(outputDir, extension);
}

DistCliFailure? playValidation({
  required String saJsonPath,
  required String packageName,
  required String aabPath,
  required String track,
}) {
  if (track != 'production' && track != 'internal') {
    return const DistCliFailure(64, 'Track must be production or internal.');
  }
  if (packageName.isEmpty || saJsonPath.isEmpty) {
    return const DistCliFailure(
      1,
      'Play secrets are missing. Set playSaJsonPath and playPackageName.',
    );
  }
  if (!fileExists(saJsonPath)) {
    return const DistCliFailure(1, 'Play service account JSON was not found.');
  }
  if (aabPath.isEmpty || !fileExists(aabPath)) {
    return const DistCliFailure(1, 'No AAB was collected in this run.');
  }
  return null;
}

DistCliFailure? driveValidation({
  required String oauthJson,
  required String tokenJson,
  required List<String> files,
}) {
  if (oauthJson.isEmpty) {
    return const DistCliFailure(
      1,
      'Drive secrets are missing. Set driveOauthJson.',
    );
  }
  if (!fileExists(oauthJson)) {
    return const DistCliFailure(1, 'Drive OAuth client JSON was not found.');
  }
  if (tokenJson.isEmpty || !fileExists(tokenJson)) {
    return const DistCliFailure(
      1,
      'Drive token is missing. Auth once in Fluship Settings, then set driveTokenJson.',
    );
  }
  if (files.isEmpty) {
    return const DistCliFailure(1, 'No APK was collected in this run.');
  }
  return null;
}

DistCliFailure? appStoreValidation({
  required bool isMacOS,
  required String issuerId,
  required String apiKeyId,
  required String apiKeyPath,
  required String ipaPath,
}) {
  if (!isMacOS) {
    return const DistCliFailure(1, 'App Store upload requires macOS.');
  }
  if (issuerId.isEmpty || apiKeyId.isEmpty || apiKeyPath.isEmpty) {
    return const DistCliFailure(
      1,
      'App Store secrets are missing. Set issuer, key id, and .p8 path.',
    );
  }
  if (!fileExists(apiKeyPath)) {
    return const DistCliFailure(1, 'App Store Auth Key (.p8) was not found.');
  }
  if (ipaPath.isEmpty || !fileExists(ipaPath)) {
    return const DistCliFailure(1, 'No IPA was collected in this run.');
  }
  return null;
}

DistCliFailure? slackValidation({
  required String webhookUrl,
  required String link,
}) {
  if (webhookUrl.isEmpty) {
    return const DistCliFailure(
      1,
      'Slack secrets are missing. Set slackWebhookUrl.',
    );
  }
  if (link.isEmpty) {
    return const DistCliFailure(
      1,
      'Drive link is missing. Pass --link or run distDrive first.',
    );
  }
  return null;
}

void writeLastDrive({
  required String path,
  required String link,
  required List<String> fileNames,
}) {
  writeJsonFile(path, {'link': link, 'fileNames': fileNames});
}

String readLastDriveLink(String path) {
  return asString(readJsonFile(path)['link']);
}
