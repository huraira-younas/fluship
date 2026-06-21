import 'package:flutter/material.dart' show WidgetsFlutterBinding;
import 'package:file_picker/file_picker.dart';
import 'core/shared_prefs/shared_prefs.dart';
import 'dart:io' show Platform;
import 'core/logger.dart';
import 'di/locator.dart';

class AppDependencies {
  static Future<void> initialize() async {
    final start = DateTime.now();

    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isMacOS) {
      await FilePicker.skipEntitlementsChecks();
    }

    await SharedPrefs.i.init();
    AppLocator.initialize();

    final elapsed = DateTime.now().difference(start);
    Logger.info(
      message: "Initialized in ${elapsed.inSeconds} seconds",
      tag: "App_Dependencies",
    );
  }
}
