import 'package:flutter/material.dart' show IconData, Icons;

class ProcessCommandLabel {
  const ProcessCommandLabel._();

  static String displayName(String command) {
    final lower = command.toLowerCase();

    if (lower.contains('aapt2')) return 'aapt2';
    if (lower.contains('gradle')) return 'Gradle';
    if (lower.contains('xcodebuild')) return 'xcodebuild';
    if (lower.contains('pod install') || lower.contains('pod update')) {
      return 'CocoaPods';
    }

    final flutterMatch = RegExp(r'flutter\s+(\S+)').firstMatch(command);
    if (flutterMatch != null) return 'flutter ${flutterMatch.group(1)}';
    if (lower.contains('flutter')) return 'flutter';

    final dartMatch = RegExp(r'dart(vm)?\s').firstMatch(lower);
    if (dartMatch != null) return 'dart';

    if (lower.contains('java')) return 'Java';

    final token = RegExp(r'[/\\]([^/\\]+)$').firstMatch(command.trim());
    if (token != null) return token.group(1)!;

    final first = command.trim().split(RegExp(r'\s+')).first;
    return first.length > 32 ? '${first.substring(0, 29)}...' : first;
  }

  static IconData iconFor(String command) {
    final lower = command.toLowerCase();

    if (lower.contains('gradle') || lower.contains('java')) {
      return Icons.build_circle_outlined;
    }
    if (lower.contains('flutter') || lower.contains('dart')) {
      return Icons.flutter_dash;
    }
    if (lower.contains('aapt2')) return Icons.android_outlined;
    if (lower.contains('pod') || lower.contains('xcodebuild')) {
      return Icons.apple;
    }

    return Icons.memory_rounded;
  }
}
