part of 'shared_prefs.dart';

enum SharedPrefsKeys {
  commonCmd('common_cmd'),
  themeMode('theme_mode'),
  appInfo('app_info'),
  preGit('pre_git');

  const SharedPrefsKeys(this.key);
  final String key;
}
