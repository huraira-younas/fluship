import 'distribution_service.dart';
import 'drive/drive_uploader.dart';
import 'handlers/exports.dart';
import 'email/exports.dart';

class DistributionModule {
  const DistributionModule._();

  static DistributionService createService() {
    const driveUploader = GoogleDriveUploader();
    const htmlBuilder = ReportHtmlBuilder();
    const emailClient = GmailSmtpClient();

    return DistributionService(
      handlers: [
        const GoogleDriveHandler(
          htmlBuilder: htmlBuilder,
          emailClient: emailClient,
          uploader: driveUploader,
        ),
        const PlayStoreHandler(),
        const AppStoreHandler(),
        const ReportEmailHandler(
          htmlBuilder: htmlBuilder,
          emailClient: emailClient,
        ),
      ],
    );
  }
}
