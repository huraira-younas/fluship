part of 'shared_prefs.dart';

enum SharedPrefsKeys {
  themeMode('theme_mode'),
  appInfo('app_info');

  const SharedPrefsKeys(this.key);
  final String key;
}
