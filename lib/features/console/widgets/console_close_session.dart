import 'package:fluship/features/console/models/console_session.dart';
import 'package:flutter/material.dart';

Future<bool> confirmCloseSession(
  BuildContext context,
  ConsoleSession session,
) async {
  if (!session.isRunning) return true;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Close ${session.title}?'),
      content: const Text(
        'A command is still running in this tab. '
        'Closing will stop the process and remove its output.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Keep open'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Close tab'),
        ),
      ],
    ),
  );

  return result ?? false;
}
