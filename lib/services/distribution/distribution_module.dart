import 'email/build_report_email_handler.dart';
import 'email/build_report_html_builder.dart';
import 'email/drive_link_email_handler.dart';
import 'email/gmail_smtp_client.dart';
import 'distribution_service.dart';
import 'handlers/exports.dart';

class DistributionModule {
  const DistributionModule._();

  static DistributionService createService() {
    const htmlBuilder = BuildReportHtmlBuilder();
    const emailClient = GmailSmtpClient();

    return DistributionService(
      handlers: [
        const DriveLinkEmailHandler(),
        const GoogleDriveHandler(),
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
