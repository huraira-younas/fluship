import 'distribution_service.dart';
import 'handlers/exports.dart';
import 'email/exports.dart';

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
          htmlBuilder: htmlBuilder,
          emailClient: emailClient,
        ),
      ],
    );
  }
}
