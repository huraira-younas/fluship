import 'package:fluship/services/project_service.dart/flutter_project_service.dart';
import 'package:fluship/services/project_service.dart/project_profiles_store.dart';
import 'package:fluship/shared/models/post_build_config.dart';
import 'package:fluship/core/base_bloc/base_bloc.dart';
import 'package:fluship/shared/models/post_git.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fluship/shared/models/distribution/distribution_config.dart';
import 'package:fluship/shared/models/android_config.dart';
import 'package:fluship/shared/models/base_config.dart';
import 'package:fluship/shared/models/ios_config.dart';
import 'package:fluship/shared/models/common_cmd.dart';
import 'package:fluship/shared/models/app_info.dart';
import 'package:fluship/shared/models/pre_git.dart';

part 'config_event.dart';
part 'config_state.dart';

class ConfigBloc extends BaseBloc<ConfigEvent, ConfigState> {
  final _projectService = const FlutterProjectService();
  final ProjectProfilesStore _profilesStore;

  ConfigBloc(this._profilesStore) : super(ConfigState.empty()) {
    on<SyncProjectAppInfo>(handler(_syncProjectAppInfo));

    on<DeleteProjectProfile>(handler(_deleteProjectProfile));
    on<SwitchProjectProfile>(handler(_switchProjectProfile));
    on<StartNewProfile>(handler(_startNewProfile));

    on<UpdateConfigs>(handler(_updateConfigs));
    on<ImportConfig>(handler(_importConfig));
    on<UpdateConfig>(handler(_updateConfig));
    on<LoadConfig>(handler(_loadConfig));
    on<SaveConfig>(handler(_saveConfig));
  }

  Map<String, dynamic> exportConfig() => state.toJson();
  Future<void> persistActiveProfile() => _persist(state);

  Future<Map<String, AppInfoModel>> resolveProjectAppInfo() async {
    final entries = await Future.wait(
      _profilesStore.projectNames.map((projectName) async {
        final profile = _profilesStore.getProfile(projectName);
        final rawAppInfo = profile?['appInfo'];
        final appInfo = AppInfoModel.fromJson(
          rawAppInfo is Map ? Map<String, dynamic>.from(rawAppInfo) : null,
        );
        final projectPath = appInfo.flutterProjectPath;
        if (projectPath == null || projectPath.isEmpty) {
          return MapEntry(projectName, appInfo);
        }

        try {
          final appIconPath = await _projectService.resolveAppIconPath(
            projectPath,
          );
          return MapEntry(
            projectName,
            appInfo.copyWith(appIconPath: appIconPath),
          );
        } on FlutterProjectException {
          return MapEntry(projectName, appInfo);
        }
      }),
    );

    return Map.fromEntries(entries);
  }

  ConfigState _applyConfig(ConfigState current, BaseConfig config) {
    return switch (config) {
      PostBuildConfigModel postBuild => current.copyWith(postBuild: postBuild),
      CommonCmdModel commonCmd => current.copyWith(commonCmd: commonCmd),
      AndroidConfigModel android => current.copyWith(android: android),
      AppInfoModel appInfo => current.copyWith(appInfo: appInfo),
      PostGitModel postGit => current.copyWith(postGit: postGit),
      PreGitModel preGit => current.copyWith(preGit: preGit),
      IosConfigModel ios => current.copyWith(ios: ios),
      DistributionConfigModel distribution => current.copyWith(
        distribution: distribution,
      ),

      _ => throw UnsupportedError('Invalid config type: ${config.runtimeType}'),
    };
  }

  Future<void> _updateConfig(
    Emitter<ConfigState> emit,
    UpdateConfig event,
  ) async {
    final updated = _applyConfig(state, event.config);
    emit(updated);
    await _persist(updated);
  }

  Future<void> _updateConfigs(
    Emitter<ConfigState> emit,
    UpdateConfigs event,
  ) async {
    var updated = state;
    for (final config in event.configs) {
      updated = _applyConfig(updated, config);
    }

    emit(updated);
    await _persist(updated);
  }

  Future<void> _loadConfig(Emitter<ConfigState> emit, LoadConfig event) async {
    emit(state.copyWith(loading: true));

    final activeProject = _profilesStore.activeProject;
    final profile = activeProject == null
        ? null
        : _profilesStore.getProfile(activeProject);

    if (activeProject == null || profile == null) {
      if (activeProject != null) await _profilesStore.clearActiveProject();
      emit(
        ConfigState.empty().copyWith(
          projectNames: _profilesStore.projectNames,
          loading: false,
        ),
      );
      return;
    }

    final loaded = await _loadProjectProfile(activeProject, profile);
    emit(loaded);
    await _persist(loaded);
  }

  Future<void> _startNewProfile(
    Emitter<ConfigState> emit,
    StartNewProfile event,
  ) async {
    await _persist(state);
    emit(
      ConfigState.empty().copyWith(projectNames: _profilesStore.projectNames),
    );
  }

  Future<bool> _deleteProjectProfile(
    Emitter<ConfigState> emit,
    DeleteProjectProfile event,
  ) async {
    final storedProjects = _profilesStore.projectNames;
    if (!storedProjects.contains(event.projectName)) {
      throw StateError('Profile not found: ${event.projectName}');
    }

    final deletingActive = state.activeProject == event.projectName;
    if (!deletingActive) {
      await _profilesStore.deleteProfile(event.projectName);
      emit(state.copyWith(projectNames: _profilesStore.projectNames));
      return true;
    }

    if (storedProjects.length == 1) {
      await _profilesStore.deleteProfile(event.projectName);
      emit(ConfigState.empty());
      return true;
    }

    final fallbackProject = storedProjects
        .where((projectName) => projectName != event.projectName)
        .first;

    final fallbackProfile = _profilesStore.getProfile(fallbackProject);
    if (fallbackProfile == null) {
      throw StateError('Profile not found: $fallbackProject');
    }

    emit(state.copyWith(loading: true));
    final loaded = await _loadProjectProfile(fallbackProject, fallbackProfile);
    await _profilesStore.deleteProfile(event.projectName);

    final updated = loaded.copyWith(projectNames: _profilesStore.projectNames);
    emit(updated);
    await _persist(updated);
    return true;
  }

  Future<void> _switchProjectProfile(
    Emitter<ConfigState> emit,
    SwitchProjectProfile event,
  ) async {
    await _persist(state);

    final profile = _profilesStore.getProfile(event.projectName);
    if (profile == null) {
      throw StateError('Profile not found: ${event.projectName}');
    }

    emit(state.copyWith(loading: true));
    final loaded = await _loadProjectProfile(event.projectName, profile);
    emit(loaded);
    await _persist(loaded);
  }

  Future<void> _syncProjectAppInfo(
    Emitter<ConfigState> emit,
    SyncProjectAppInfo event,
  ) async {
    final appInfo = await _projectService.extractAppInfo(
      flutterProjectPath: event.flutterProjectPath,
      base: state.appInfo,
    );

    final projectName = appInfo.projectName;
    final savedProfile = state.activeProject == null && projectName != null
        ? _profilesStore.getProfile(projectName)
        : null;

    var target = state.copyWith(appInfo: appInfo);
    if (savedProfile != null) {
      final savedState = ConfigState.fromJson(savedProfile);

      final refreshedAppInfo = await _projectService.extractAppInfo(
        flutterProjectPath: event.flutterProjectPath,
        base: savedState.appInfo,
      );

      target = savedState.copyWith(appInfo: refreshedAppInfo);
    }

    final updated = await _activateProfile(
      target,
      missingProjectMessage: 'Project name is missing from pubspec.yaml',
    );
    emit(updated);
    await _persist(updated);
  }

  Future<void> _importConfig(
    Emitter<ConfigState> emit,
    ImportConfig event,
  ) async {
    final export = ConfigState.fromJson(event.data);
    var imported = export;

    imported = await _refreshProjectInfo(imported);

    imported = await _activateProfile(
      imported,
      missingProjectMessage:
          'Imported config must contain a valid Flutter project path',
    );
    emit(imported);
    await _persist(imported);
  }

  Future<void> _saveConfig(Emitter<ConfigState> emit, SaveConfig event) async {
    if (state.activeProject == null) {
      throw StateError('Select or import a Flutter project before saving');
    }
    await _persist(state);
  }

  Future<ConfigState> _refreshProjectInfo(ConfigState config) async {
    final path = config.appInfo.flutterProjectPath ?? '';
    if (path.isEmpty) return config;

    final appInfo = await _projectService.extractAppInfo(
      flutterProjectPath: path,
      base: config.appInfo,
    );
    return config.copyWith(appInfo: appInfo);
  }

  Future<ConfigState> _loadProjectProfile(
    String projectName,
    Map<String, dynamic> profile,
  ) async {
    var loaded = ConfigState.fromJson(profile);
    loaded = await _refreshProjectInfo(loaded);

    final resolvedProject = loaded.appInfo.projectName ?? projectName;
    if (resolvedProject != projectName) {
      await _profilesStore.renameProfile(
        newProjectName: resolvedProject,
        oldProjectName: projectName,
      );
    }

    return loaded.copyWith(
      projectNames: _profilesStore.projectNames,
      activeProject: resolvedProject,
      loading: false,
    );
  }

  Future<ConfigState> _activateProfile(
    ConfigState config, {
    required String missingProjectMessage,
  }) async {
    final projectName = config.appInfo.projectName;
    if (projectName == null || projectName.isEmpty) {
      throw StateError(missingProjectMessage);
    }

    final previousProject = state.activeProject;
    if (previousProject != null && previousProject != projectName) {
      await _profilesStore.renameProfile(
        oldProjectName: previousProject,
        newProjectName: projectName,
      );
    }

    return config.copyWith(
      activeProject: projectName,
      projectNames: {..._profilesStore.projectNames, projectName}.toList()
        ..sort(),
    );
  }

  Future<void> _persist(ConfigState config) async {
    final projectName = config.activeProject;
    if (projectName == null) return;

    await _profilesStore.saveProfile(projectName, config.toJson());
  }
}
