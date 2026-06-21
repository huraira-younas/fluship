import 'email/build_report_email_handler.dart';
import 'email/build_report_html_builder.dart';
import 'email/drive_link_email_handler.dart';
import 'handlers/google_drive_handler.dart';
import 'handlers/play_store_handler.dart';
import 'handlers/app_store_handler.dart';
import 'email/gmail_smtp_client.dart';
import 'distribution_service.dart';

class DistributionModule {
  const DistributionModule._();

  static DistributionService createService() {
    const htmlBuilder = BuildReportHtmlBuilder();
    const emailClient = GmailSmtpClient();

    return DistributionService(
      handlers: [
        const GoogleDriveHandler(),
        const DriveLinkEmailHandler(),
        const PlayStoreHandler(),
        const AppStoreHandler(),
        const BuildReportEmailHandler(
          emailClient: emailClient,
          htmlBuilder: htmlBuilder,
        ),
      ],
    );
  }
}
