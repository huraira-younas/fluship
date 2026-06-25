import 'package:fluship/features/pipeline/models/pipeline_step_view.dart';
import 'package:fluship/services/pipeline/pipeline.dart';
import 'package:intl/intl.dart';
import 'report_html_theme.dart';

class ReportStepResult {
  const ReportStepResult({
    required this.elapsed,
    required this.success,
    required this.name,
  });

  final Duration? elapsed;
  final bool success;
  final String name;
}

class ReportHtmlBuilder {
  const ReportHtmlBuilder();

  String build({
    required List<ReportStepResult> steps,
    required ReportHtmlTheme theme,
    required String totalElapsed,
    required String buildNumber,
    required String platforms,
    required String appName,
    required String version,
    required bool success,
  }) {
    final nowStr = DateFormat('MMM d, yyyy · HH:mm').format(DateTime.now());
    final statusText = success ? 'Build Succeeded' : 'Build Failed';
    final statusColor = success ? theme.success : theme.error;
    final statusEmoji = success ? '✓' : '✗';

    final stepRows = StringBuffer();
    for (var i = 0; i < steps.length; i++) {
      stepRows.write(_stepRow(steps[i], theme, index: i));
    }

    final escapedBuild = _escape(buildNumber);
    final escapedVersion = _escape(version);
    final escapedApp = _escape(appName);

    return '${theme.bodyOpen}'
        '<div ${theme.cardOpen}>'
        '${_htmlHeader('Build Report &mdash; v$escapedVersion+$escapedBuild', escapedApp, theme)}'
        "${_htmlBanner('$statusEmoji&ensp;$statusText', statusColor)}"
        '<div style="background:${theme.cardBg};padding:18px 22px;${theme.borderLr}">'
        '<table style="width:100%;border-collapse:collapse;">'
        '${_summaryRow('Version', 'v$version+$buildNumber', theme, bold: true)}'
        '${_summaryRow('Platforms', platforms, theme)}'
        '${_summaryRow('Total Time', totalElapsed, theme, color: theme.accent, bold: true)}'
        '${_summaryRow('Date', nowStr, theme)}'
        '</table></div>'
        '<div style="background:${theme.cardBg};${theme.borderLr}">'
        '<div style="padding:14px 22px 10px;border-top:1px solid ${theme.cardBorder};'
        'border-bottom:1px solid ${theme.cardBorder};">'
        '<h2 ${theme.sectionH2Styled}>Pipeline Steps</h2></div>'
        '<table class="report-step-table" style="width:100%;border-collapse:collapse;">'
        '<tr style="background:${theme.bg};">'
        '<th ${theme.thStyleAligned('left')}>Step</th>'
        '<th ${theme.thStyleAligned('center')}>Status</th>'
        '<th ${theme.thStyleAligned('right')}>Time</th>'
        '</tr>$stepRows</table></div>'
        '${_htmlFooter(theme)}'
        '</div>'
        '${ReportHtmlTheme.bodyClose}';
  }

  String buildDriveLink({
    required List<String> fileNames,
    required ReportHtmlTheme theme,
    required String buildNumber,
    required String version,
    required String label,
    required String link,
  }) {
    final nowStr = DateFormat('MMM d, yyyy · HH:mm').format(DateTime.now());
    final escapedLabel = _escape(label);
    final escapedLink = _escape(link);
    final escapedVersion = _escape(version);
    final escapedBuild = _escape(buildNumber);
    final versionTag = version.isNotEmpty && buildNumber.isNotEmpty
        ? ' &mdash; v$escapedVersion+$escapedBuild'
        : '';
    final subtitle = '$escapedLabel Upload$versionTag';

    final fileRows = StringBuffer();
    for (final name in fileNames) {
      fileRows.write(
        '<tr><td style="padding:10px 14px;border-bottom:1px solid ${theme.cardBorder};'
        'color:${theme.text};font-size:13px;">📦&ensp;${_escape(name)}</td></tr>',
      );
    }

    final versionRow = version.isNotEmpty && buildNumber.isNotEmpty
        ? _summaryRow('Version', 'v$version+$buildNumber', theme, bold: true)
        : '';

    return '${theme.bodyOpen}'
        '<div ${theme.cardOpen}>'
        '${_htmlHeader(subtitle, escapedLabel, theme)}'
        "${_htmlBanner('📁&ensp;Upload Complete', theme.success)}"
        '<div style="background:${theme.cardBg};padding:18px 22px;${theme.borderLr}">'
        '<table style="width:100%;border-collapse:collapse;">'
        '${_summaryRow('Type', '$label Build', theme, bold: true)}'
        '$versionRow'
        '${_summaryRow('Date', nowStr, theme)}'
        '</table></div>'
        '<div style="background:${theme.cardBg};${theme.borderLr}">'
        '<div style="padding:14px 22px 10px;border-top:1px solid ${theme.cardBorder};'
        'border-bottom:1px solid ${theme.cardBorder};">'
        '<h2 ${theme.sectionH2Styled}>Uploaded Files</h2></div>'
        '<table style="width:100%;border-collapse:collapse;">'
        '$fileRows</table></div>'
        '<div style="background:${theme.cardBg};padding:20px 22px;text-align:center;${theme.borderLr}">'
        '<a href="$escapedLink" style="display:inline-block;background:'
        'linear-gradient(135deg,${theme.accent},${theme.section});color:#fff;text-decoration:none;'
        'padding:12px 32px;border-radius:8px;font-size:14px;font-weight:700;'
        'letter-spacing:0.2px;">Open in Google Drive</a>'
        '<p style="margin:10px 0 0;font-size:12px;color:${theme.textDim};">'
        'Anyone with the link can view</p></div>'
        '${_htmlFooter(theme)}'
        '</div>'
        '${ReportHtmlTheme.bodyClose}';
  }

  List<ReportStepResult> stepsFromPipelineViews(List<PipelineStepView> views) {
    return views
        .where(
          (v) =>
              v.status != .pending &&
              v.name != DistributionStepKind.report.name,
        )
        .map(
          (v) => ReportStepResult(
            success: v.status == .completed,
            elapsed: v.elapsed,
            name: v.name,
          ),
        )
        .toList();
  }

  String _stepRow(
    ReportStepResult step,
    ReportHtmlTheme theme, {
    required int index,
  }) {
    final elapsed = step.elapsed;
    final elapsedText = elapsed == null
        ? '—'
        : PipelineUtils.formatPipelineDuration(elapsed);
    final rowBg = index.isEven ? theme.cardBg : theme.bg;

    return '<tr style="background:$rowBg;">'
        '<td style="padding:10px 14px;border-bottom:1px solid ${theme.cardBorder};'
        'color:${theme.text};font-size:13px;">${_escape(step.name)}</td>'
        '<td style="padding:10px 14px;border-bottom:1px solid ${theme.cardBorder};'
        'text-align:center;min-width:90px;">${_statusBadge(step.success, theme)}</td>'
        '<td style="padding:10px 14px;border-bottom:1px solid ${theme.cardBorder};'
        'color:${theme.section};font-size:12px;text-align:right;'
        'font-family:Consolas,monospace;">$elapsedText</td>'
        '</tr>';
  }

  String _htmlHeader(String subtitle, String appName, ReportHtmlTheme theme) {
    return '<div style="background:linear-gradient(135deg,${theme.accent},${theme.section});'
        'padding:24px 22px;text-align:center;">'
        '<h1 style="margin:0;font-size:22px;color:#fff;letter-spacing:-0.3px;">'
        '⚡ $appName</h1>'
        '<p style="margin:6px 0 0;font-size:13px;color:rgba(255,255,255,0.85);font-weight:500;">'
        '$subtitle</p></div>';
  }

  String _htmlFooter(ReportHtmlTheme theme) {
    return '<div style="background:${theme.cardBg};'
        '${theme.borderLr}border-bottom:1px solid ${theme.cardBorder};'
        'padding:16px 22px;text-align:center;">'
        '<p style="margin:0 0 4px;font-size:12px;color:${theme.textDim};">'
        'Generated by <strong style="color:${theme.accent};">'
        '${ReportHtmlTheme.flushipName}</strong>'
        ' v${ReportHtmlTheme.flushipVersion}</p>'
        '<p style="margin:0;font-size:12px;color:${theme.section};">'
        'Made with ❤️ by Senpai</p></div>';
  }

  String _htmlBanner(String text, String bg) {
    return '<div style="background:$bg;padding:12px 22px;text-align:center;">'
        '<span style="color:${ReportHtmlTheme.badgeText};font-size:14px;font-weight:700;'
        'letter-spacing:0.2px;">$text</span></div>';
  }

  String _summaryRow(
    String label,
    String value,
    ReportHtmlTheme theme, {
    bool bold = false,
    String? color,
  }) {
    final textColor = color ?? theme.text;
    final weight = bold ? 'font-weight:600;' : '';
    return '<tr><td style="padding:8px 0;color:${theme.textDim};font-size:12px;width:110px;">'
        '${_escape(label)}</td>'
        '<td style="padding:8px 0;color:$textColor;font-size:13px;$weight">'
        '${_escape(value)}</td></tr>';
  }

  String _statusBadge(bool ok, ReportHtmlTheme theme) {
    if (ok) {
      return '<span style="display:inline-block;background:${theme.success};'
          'color:${ReportHtmlTheme.badgeText};padding:3px 10px;border-radius:20px;'
          'font-size:11px;font-weight:600;white-space:nowrap;">'
          '✓ Passed</span>';
    }

    return '<span style="display:inline-block;background:${theme.error};'
        'color:${ReportHtmlTheme.badgeText};padding:3px 10px;border-radius:20px;'
        'font-size:11px;font-weight:600;white-space:nowrap;">'
        '✗ Failed</span>';
  }

  String _escape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
