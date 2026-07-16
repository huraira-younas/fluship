import 'package:fluship/core/shared_prefs/shared_prefs.dart';

class ProjectProfilesStore {
  ProjectProfilesStore({SharedPrefs? sharedPrefs})
    : _sharedPrefs = sharedPrefs ?? SharedPrefs.i;

  final SharedPrefs _sharedPrefs;

  String? get activeProject => _sharedPrefs.getString(.activeProject);

  List<String> get projectNames {
    final names = _profiles.keys.toList()..sort();
    return names;
  }

  Future<void> setActiveProject(String projectName) =>
      _sharedPrefs.setString(value: projectName, key: .activeProject);

  Future<void> clearActiveProject() => _sharedPrefs.remove(.activeProject);

  Map<String, dynamic>? getProfile(String projectName) {
    final profile = _profiles[projectName];
    return profile is Map ? Map<String, dynamic>.from(profile) : null;
  }

  Future<void> saveProfile(
    String projectName,
    Map<String, dynamic> config,
  ) async {
    final profiles = _profiles..[projectName] = config;
    await _sharedPrefs.setObject(.projectProfiles, profiles);
    await setActiveProject(projectName);
  }

  Future<bool> deleteProfile(String projectName) async {
    final profiles = _profiles;
    if (!profiles.containsKey(projectName)) return false;

    profiles.remove(projectName);
    await _sharedPrefs.setObject(.projectProfiles, profiles);
    if (activeProject == projectName) await clearActiveProject();
    return true;
  }

  Future<void> renameProfile({
    required String newProjectName,
    required String oldProjectName,
  }) async {
    if (newProjectName == oldProjectName) return;

    final profiles = _profiles;
    if (profiles.containsKey(newProjectName)) {
      throw StateError('Profile already exists: $newProjectName');
    }

    final profile = profiles.remove(oldProjectName);
    if (profile != null) profiles[newProjectName] = profile;

    await _sharedPrefs.setObject(.projectProfiles, profiles);
    await setActiveProject(newProjectName);
  }

  Map<String, dynamic> get _profiles {
    final value = _sharedPrefs.getObject(.projectProfiles);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  }
}
