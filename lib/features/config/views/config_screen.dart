import 'package:flutter/material.dart';

import '../sections/build_config.dart';

class ConfigScreen extends StatelessWidget {
  const ConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20,
      children: <Widget>[BuildConfig(), BuildConfig()],
    );
  }
}
