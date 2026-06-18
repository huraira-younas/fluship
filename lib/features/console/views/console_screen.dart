import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../widgets/console_toolbar.dart';
import '../widgets/console_output.dart';
import '../widgets/console_input.dart';
import '../bloc/console_bloc.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = context.read<ConfigBloc>().state.appInfo.flutterProjectPath;
      context.read<ConsoleBloc>().add(SyncProjectPath(path: path));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigBloc, ConfigState>(
      listenWhen: (previous, current) =>
          previous.appInfo.flutterProjectPath !=
          current.appInfo.flutterProjectPath,
      listener: (context, state) {
        context.read<ConsoleBloc>().add(
          SyncProjectPath(path: state.appInfo.flutterProjectPath),
        );
      },
      child: AppCard(
        expandedBody: true,
        title: 'Console',
        spacing: 16,
        description:
            'Run shell commands in your Flutter project directory. '
            'Output streams live — use Stop to cancel a running command.',
        children: [
          const ConsoleToolbar(),
          const ConsoleOutput().expanded(),
          const ConsoleInput(),
        ],
      ),
    );
  }
}
