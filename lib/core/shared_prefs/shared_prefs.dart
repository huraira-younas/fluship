import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show jsonEncode, jsonDecode;

part 'shared_prefs_keys.dart';

class SharedPrefs {
  static SharedPrefs get i => _instance;
  late SharedPreferences _prefs;

  static final SharedPrefs _instance = SharedPrefs._internal();
  SharedPrefs._internal();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ------------------ Theme ------------------
  String get themeMode => _prefs.getString(SharedPrefsKeys.themeMode.key) ?? '';

  String get themeBrightness =>
      _prefs.getString(SharedPrefsKeys.themeBrightness.key) ?? '';

  Future<void> setThemeMode(String value) async {
    await _prefs.setString(SharedPrefsKeys.themeMode.key, value);
  }

  Future<void> setThemeBrightness(String value) async {
    await _prefs.setString(SharedPrefsKeys.themeBrightness.key, value);
  }

  // ------------------ Generic Methods ------------------
  Future<void> setObject(SharedPrefsKeys key, dynamic value) async {
    await _prefs.setString(key.key, jsonEncode(value));
  }

  Future<void> setString({
    required SharedPrefsKeys key,
    required String value,
  }) async {
    await _prefs.setString(key.key, value);
  }

  Future<void> setBool(SharedPrefsKeys key, bool value) async {
    await _prefs.setBool(key.key, value);
  }

  Future<void> setInt(SharedPrefsKeys key, int value) async {
    await _prefs.setInt(key.key, value);
  }

  Future<void> setDouble(SharedPrefsKeys key, double value) async {
    await _prefs.setDouble(key.key, value);
  }

  Future<void> remove(SharedPrefsKeys key) async =>
      await _prefs.remove(key.key);

  double getDouble(SharedPrefsKeys key) => _prefs.getDouble(key.key) ?? 0.0;

  bool getBool(SharedPrefsKeys key) => _prefs.getBool(key.key) ?? false;

  dynamic getObject(SharedPrefsKeys key) {
    final d = _prefs.getString(key.key);
    if (d == null) return null;
    return jsonDecode(d);
  }

  String? getString(SharedPrefsKeys key) => _prefs.getString(key.key);

  Future<void> clearAll() async => await _prefs.clear();

  int getInt(SharedPrefsKeys key) => _prefs.getInt(key.key) ?? 0;
}
