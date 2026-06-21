class ReportHtmlTheme {
  const ReportHtmlTheme._();

  static const bodyOpen =
      '<!DOCTYPE html><html><head><meta charset="utf-8"></head>'
      '<body style="margin:0;padding:24px 12px;background:#0f172a;'
      'font-family:Segoe UI,system-ui,sans-serif;">'
      '<div style="max-width:560px;margin:0 auto;">';
  static const bodyClose = '</div></body></html>';

  static const borderLr = 'border-left:1px solid #1e293b;border-right:1px solid #1e293b;';
  static const bg = '#0f172a';
  static const success = '#34d399';
  static const error = '#f87171';
  static const muted = '#64748b';
  static const accent = '#38bdf8';
  static const cardBorder = '#1e293b';
  static const cardBg = '#1e293b';
  static const section = '#94a3b8';
  static const sectionH2 =
      'style="margin:0;font-size:13px;font-weight:700;color:#cbd5e1;'
      'text-transform:uppercase;letter-spacing:0.6px;"';
  static const thStyle =
      'style="padding:8px 12px;font-size:11px;font-weight:700;color:#64748b;'
      'text-transform:uppercase;letter-spacing:0.4px;text-align:{align};"';

  static const flushipVersion = '1.0.0';
}
