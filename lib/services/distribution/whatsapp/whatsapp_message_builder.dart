import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/pipeline/utils/pipeline_utils.dart';

import '../models/pipeline_run_snapshot.dart';
import '../upload/counted_upload.dart';
import 'whatsapp_client.dart';

typedef WhatsAppFileEntry = ({String name, int bytes});

/// Builds the plain-text run summary. WhatsApp renders `*bold*`, and caps a
/// message at [WhatsAppLimits.maxTextLength] characters.
class const WhatsAppMessageBuilder() {
  static const _maxErrorLength = 160;

  String build(
    PipelineRunSnapshot snapshot, {
    List<WhatsAppFileEntry> files = const [],
    int maxLength = WhatsAppLimits.maxTextLength,
    required String ownStepName,
  }) {
    final head = _header(snapshot);
    final tail = _filesAndLinks(snapshot, files);

    final stepLines = [
      for (final step in snapshot.steps)
        if (step.name != ownStepName) ?_stepLine(step),
    ];
    if (stepLines.isEmpty) return _clip('$head$tail', maxLength);

    const title = '\n\n*Steps*';
    var budget = maxLength - head.length - tail.length - title.length;

    final kept = <String>[];
    for (var i = 0; i < stepLines.length; i++) {
      final remaining = stepLines.length - i - 1;
      final reserve = remaining > 0 ? _moreLine(remaining).length + 1 : 0;
      final cost = stepLines[i].length + 1;
      if (cost + reserve > budget) {
        kept.add(_moreLine(stepLines.length - i));
        break;
      }
      kept.add(stepLines[i]);
      budget -= cost;
    }

    return _clip('$head$title\n${kept.join('\n')}$tail', maxLength);
  }

  String _header(PipelineRunSnapshot snapshot) {
    final (icon, outcome) = switch (snapshot.runStatus) {
      .completed => ('✅', 'succeeded'),
      .cancelled => ('⚠️', 'was cancelled'),
      .failed => ('❌', 'failed'),
      _ => ('ℹ️', 'finished'),
    };

    final duration = PipelineUtils.formatPipelineDuration(
      snapshot.totalElapsed,
    );

    return '$icon *${snapshot.appName}* '
        'v${snapshot.version}+${snapshot.buildNumber} $outcome\n'
        'Platforms: ${snapshot.platforms}\n'
        'Duration: $duration';
  }

  String? _stepLine(PipelineStepView step) {
    final elapsed = step.elapsed;
    final time = elapsed == null
        ? ''
        : ' (${PipelineUtils.formatPipelineDuration(elapsed)})';

    return switch (step.status) {
      .completed => '✓ ${step.name}$time',
      .failed => '✗ ${step.name}$time${_errorSuffix(step.errorMessage)}',
      .cancelled => '– ${step.name} (cancelled)',
      .skipped => '– ${step.name} (skipped)',
      .pending || .running => null,
    };
  }

  String _errorSuffix(String? error) {
    final firstLine = (error ?? '').trim().split('\n').first.trim();
    if (firstLine.isEmpty) return '';
    return firstLine.length <= _maxErrorLength
        ? ': $firstLine'
        : ': ${firstLine.substring(0, _maxErrorLength)}…';
  }

  String _filesAndLinks(
    PipelineRunSnapshot snapshot,
    List<WhatsAppFileEntry> files,
  ) {
    final buffer = StringBuffer();

    if (files.isNotEmpty) {
      buffer.write('\n\n*Files*');
      for (final file in files) {
        buffer.write('\n• ${file.name} (${formatMegabytes(file.bytes)} MB)');
      }
    }

    if (snapshot.links.isNotEmpty) {
      buffer.write('\n\n*Links*');
      for (final link in snapshot.links.entries) {
        buffer.write('\n${link.key}: ${link.value}');
      }
    }

    return buffer.toString();
  }

  String _moreLine(int count) => '… and $count more';

  String _clip(String text, int maxLength) =>
      text.length <= maxLength ? text : '${text.substring(0, maxLength - 1)}…';
}
