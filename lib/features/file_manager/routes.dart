import 'package:fluship/core/navigator.dart';
import 'package:flutter/material.dart';

import 'views/file_manager_screen.dart';
import 'views/text_file_viewer.dart';

class FileManagerRoutes {
  static void openFileManager() {
    _push(screen: const FileManagerScreen());
  }

  static void openTextViewer(String filePath) {
    _push(screen: TextFileViewer(filePath: filePath));
  }

  static Future<T?> _push<T>({
    required Widget screen,
    bool replace = false,
  }) async {
    final nav = appNavigatorKey.currentState;
    if (nav == null) throw Exception('Navigator is not initialized');
    final ctx = nav.context;
    return Navigator.push<T?>(ctx, MaterialPageRoute(builder: (_) => screen));
  }
}
