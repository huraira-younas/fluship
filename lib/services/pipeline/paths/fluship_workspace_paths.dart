import 'package:fluship/core/shared_prefs/shared_prefs.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:path/path.dart' as p;

import '../utils/pipeline_utils.dart';

class FlushipWorkspacePaths {
  const FlushipWorkspacePaths({this.overrideRoot});
  final String? overrideRoot;

  Future<String> resolveRoot() async {
    final override = overrideRoot;
    if (override != null && override.isNotEmpty) return override;

    final raw = SharedPrefs.i.getObject(SharedPrefsKeys.appInfo);
    final appInfo = AppInfoModel.fromJson(raw as Map<String, dynamic>?);
    final saved = appInfo.flushipWorkspacePath;

    return (saved != null && saved.isNotEmpty) ? p.normalize(saved) : '';
  }
}

String pipelineOutputRelativePath({
  required String projectName,
  required String buildNumber,
  required String version,
}) {
  return p.posix.join(
    'outputs',
    PipelineUtils.sanitizeProjectFolderName(projectName),
    'v${PipelineUtils.sanitizePathSegment(version)}',
    PipelineUtils.sanitizePathSegment(buildNumber),
  );
}

String pipelineOutputDirectory({
  required String flushipRoot,
  required String projectName,
  required String buildNumber,
  required String version,
}) {
  return p.join(
    flushipRoot,
    'outputs',
    PipelineUtils.sanitizeProjectFolderName(projectName),
    'v${PipelineUtils.sanitizePathSegment(version)}',
    PipelineUtils.sanitizePathSegment(buildNumber),
  );
}
