import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'package:fluship/shared/widgets/app_text.dart';
import '../repository/file_manager_repository.dart';

class TextFileViewer extends StatefulWidget {
  const TextFileViewer({required this.filePath, super.key});
  final String filePath;

  @override
  State<TextFileViewer> createState() => _TextFileViewerState();
}

class _TextFileViewerState extends State<TextFileViewer> {
  late final Future<String> _contentFuture;

  @override
  void initState() {
    super.initState();
    _contentFuture = getIt<FileManagerRepository>().readTextFile(
      widget.filePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;
    final fileName = p.basename(widget.filePath);

    return Scaffold(
      backgroundColor: ft.colors.bg,
      appBar: AppBar(
        title: AppText.title(fileName, overflow: .ellipsis, maxLines: 1),
        foregroundColor: ft.colors.text,
        backgroundColor: ft.colors.bg,
      ),
      body: FutureBuilder<String>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: .all(ft.spacing.lg),
                child: AppText.danger(
                  snapshot.error.toString(),
                  textAlign: .center,
                ),
              ),
            );
          }

          final content = snapshot.data ?? '';

          return Container(
            width: double.infinity,
            color: ft.colors.codeBg,
            child: SingleChildScrollView(
              padding: .all(ft.spacing.lg),
              child: SelectableText(
                content,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: ft.colors.cmd,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
