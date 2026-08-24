import 'catalog/readiness_test.dart' as readiness;
import 'dist/dist_cli_test.dart' as dist_cli;
import 'host/apk_collect_test.dart' as apk;
import 'host/cleanup_test.dart' as cleanup;
import 'host/host_permissions_test.dart' as permissions;
import 'host/open_page_test.dart' as open_page;
import 'progress/heartbeat_test.dart' as heartbeat;
import 'progress/progress_state_test.dart' as progress_state;
import 'progress/progress_test.dart' as progress;
import 'report/log_pdf_test.dart' as pdf;
import 'report/report_html_test.dart' as report_html;
import 'report/report_pdf_test.dart' as report_pdf;
import 'share/whatsapp_send_test.dart' as whatsapp_send;
import 'share/whatsapp_test.dart' as whatsapp;
import 'support/io_helpers_test.dart' as io_helpers;

Future<void> main() async {
  io_helpers.main();
  readiness.main();
  progress.main();
  progress_state.main();
  heartbeat.main();
  dist_cli.main();
  permissions.main();
  open_page.main();
  await whatsapp.main();
  whatsapp_send.main();
  pdf.main();
  report_html.main();
  report_pdf.main();
  apk.main();
  cleanup.main();
}
