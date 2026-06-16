import 'package:flutter/material.dart';

import '../sections/build_config.dart';
import '../sections/pre_git.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      spacing: 20,
      children: <Widget>[BuildConfig(), PreGit()],
    );
  }
}
