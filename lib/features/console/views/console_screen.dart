import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

class ConsoleScreen extends StatelessWidget {
  const ConsoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      description: 'Run commands in the console',
      title: 'Console',
      children: [],
    );
  }
}
