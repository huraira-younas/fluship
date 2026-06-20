import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter/material.dart';

class FileManagerScreen extends StatelessWidget {
  const FileManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const AppText.title('File Manager')));
  }
}
