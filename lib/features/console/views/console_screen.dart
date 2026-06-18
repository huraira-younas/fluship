import 'package:fluship/core/app_theme/fluship_theme_extension.dart';
import 'package:fluship/shared/extensions/widget_extensions.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:fluship/shared/widgets/app_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/di/locator.dart';
import 'package:flutter/material.dart';

import '../widgets/console_toolbar.dart';
import '../widgets/console_output.dart';
import '../widgets/console_input.dart';
import '../models/console_line.dart';
import '../bloc/console_bloc.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({super.key});

  @override
  State<ConsoleScreen> createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  final _csBloc = getIt<ConsoleBloc>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final path = context.read<ConfigBloc>().state.appInfo.flutterProjectPath;
      _csBloc.add(SyncProjectPath(path: path));
    });
  }

  @override
  Widget build(BuildContext context) {
    final ft = context.flushipTheme;

    return BlocListener<ConfigBloc, ConfigState>(
      listenWhen: (p, c) =>
          p.appInfo.flutterProjectPath != c.appInfo.flutterProjectPath,
      listener: (context, state) {
        _csBloc.add(SyncProjectPath(path: state.appInfo.flutterProjectPath));
      },
      child: Container(
        decoration: BoxDecoration(
          border: .all(color: ft.colors.cardBorder),
          borderRadius: .circular(ft.radius.card),
          color: ft.colors.consoleBg,
        ),
        padding: .all(ft.spacing.lg),
        child: Column(
          crossAxisAlignment: .stretch,
          spacing: ft.spacing.md,
          children: [
            const AppText.title('Console'),
            const AppText.label(
              'Run shell commands in your Flutter project directory. '
              'Output streams live — use Stop to cancel a running command.',
            ),
            BlocSelector<ConsoleBloc, ConsoleState, (String?, bool)>(
              selector: (state) => (state.projectPath, state.isRunning),
              builder: (context, data) {
                final (projectPath, isRunning) = data;
                return ConsoleToolbar(
                  onClear: () => _csBloc.add(const ClearConsole()),
                  onStop: () => _csBloc.add(const CancelCommand()),
                  projectPath: projectPath,
                  isRunning: isRunning,
                );
              },
            ),
            BlocSelector<ConsoleBloc, ConsoleState, List<ConsoleLine>>(
              selector: (state) => state.lines,
              builder: (context, lines) =>
                  ConsoleOutput(lines: lines).expanded(),
            ),
            BlocSelector<ConsoleBloc, ConsoleState, bool>(
              selector: (state) => state.isRunning,
              builder: (context, isRunning) {
                return ConsoleInput(
                  onSubmit: (command) =>
                      _csBloc.add(SubmitCommand(command: command)),
                  disabled: isRunning,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
