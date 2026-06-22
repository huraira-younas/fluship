import '../pipeline/resolver/distribution_step_kind.dart';
import 'contracts/distribution_handler.dart';
import 'drive/drive_uploader.dart';
import 'handlers/exports.dart';
import 'email/exports.dart';

class DistributionModule {
  const DistributionModule._();

  static Map<DistributionStepKind, DistributionHandler> createHandlerMap() {
    const driveUploader = GoogleDriveUploader();
    const htmlBuilder = ReportHtmlBuilder();
    const emailClient = GmailSmtpClient();

    return {
      .drive: const GoogleDriveHandler(
        htmlBuilder: htmlBuilder,
        emailClient: emailClient,
        uploader: driveUploader,
      ),
      .playStore: const PlayStoreHandler(),
      .appStore: const AppStoreHandler(),
      .report: const ReportEmailHandler(
        htmlBuilder: htmlBuilder,
        emailClient: emailClient,
      ),
    };
  }
}
