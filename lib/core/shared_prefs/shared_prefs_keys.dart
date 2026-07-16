part of 'shared_prefs.dart';

enum SharedPrefsKeys {
  themeBrightness('theme_brightness'),
  projectProfiles('project_profiles'),
  activeProject('active_project'),
  themeMode('theme_mode');

  const SharedPrefsKeys(this.key);
  final String key;
}
