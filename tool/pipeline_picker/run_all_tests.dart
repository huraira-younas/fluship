import 'apk_collect_test.dart' as apk;
import 'cleanup_test.dart' as cleanup;
import 'host_permissions_test.dart' as permissions;
import 'log_pdf_test.dart' as pdf;
import 'open_page_test.dart' as open_page;
import 'progress_test.dart' as progress;
import 'readiness_test.dart' as readiness;
import 'report_html_test.dart' as report_html;
import 'report_pdf_test.dart' as report_pdf;
import 'whatsapp_test.dart' as whatsapp;

void main() {
  readiness.main();
  progress.main();
  permissions.main();
  open_page.main();
  whatsapp.main();
  pdf.main();
  report_html.main();
  report_pdf.main();
  apk.main();
  cleanup.main();
}
