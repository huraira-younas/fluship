import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/core/navigator.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import 'views/file_manager_screen.dart';
import 'views/text_file_viewer.dart';
import 'bloc/file_manager_bloc.dart';

class FileManagerRoutes {
  static void openFileManager() {
    _push(
      screen: BlocProvider(
        child: const FileManagerScreen(),
        create: (_) {
          return getIt<FileManagerBloc>()..add(const FileManagerInitialized());
        },
      ),
    );
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
