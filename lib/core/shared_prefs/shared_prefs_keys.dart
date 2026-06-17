part of 'shared_prefs.dart';

enum SharedPrefsKeys {
  themeBrightness('theme_brightness'),
  distribution('distribution'),
  commonCmd('common_cmd'),
  postBuild('post_build'),
  themeMode('theme_mode'),
  appInfo('app_info'),
  postGit('post_git'),
  android('android'),
  preGit('pre_git'),
  ios('ios');

  const SharedPrefsKeys(this.key);
  final String key;
}
