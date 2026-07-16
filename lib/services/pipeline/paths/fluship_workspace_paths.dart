import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:path/path.dart' as p;

import '../utils/pipeline_utils.dart';

class FlushipWorkspacePaths {
  FlushipWorkspacePaths(this._profilesStore, {this.overrideRoot});

  final ProjectProfilesStore _profilesStore;
  final String? overrideRoot;

  Future<String> resolveRoot() async {
    final override = overrideRoot;
    if (override != null && override.isNotEmpty) return override;

    final activeProject = _profilesStore.activeProject;
    final raw = activeProject == null
        ? null
        : _profilesStore.getProfile(activeProject)?['appInfo'];
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
