part of 'distribution_config.dart';

class const ReportRecipientConfig({
  final bool buildReport = false,
  final List<DistributionEmail> emails = const [],
  final String? reportRecipient,
  final String? gmailAddress,
  final String? appPassword,
}) extends Equatable {
  bool get canSend =>
      hasCreds(reportRecipient) &&
      hasCreds(gmailAddress) &&
      hasCreds(appPassword);

  ReportRecipientConfig copyWith({
    List<DistributionEmail>? emails,
    String? reportRecipient,
    String? gmailAddress,
    String? appPassword,
    bool? buildReport,
  }) => ReportRecipientConfig(
    reportRecipient: reportRecipient ?? this.reportRecipient,
    gmailAddress: gmailAddress ?? this.gmailAddress,
    appPassword: appPassword ?? this.appPassword,
    buildReport: buildReport ?? this.buildReport,
    emails: emails ?? this.emails,
  );

  factory fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReportRecipientConfig();

    final data = json.at<ReportRecipientConfig>();
    return ReportRecipientConfig(
      buildReport: data.parse<bool>('buildReport', defaultValue: false),
      emails: data.list('emails', DistributionEmail.fromJson),
      reportRecipient: data.parse<String?>('reportRecipient'),
      gmailAddress: data.parse<String?>('gmailAddress'),
      appPassword: data.parse<String?>('appPassword'),
    );
  }

  Map<String, dynamic> toJson() => {
    'emails': emails.map((e) => e.toJson()).toList(),
    'reportRecipient': reportRecipient,
    'gmailAddress': gmailAddress,
    'buildReport': buildReport,
    'appPassword': appPassword,
  };

  @override
  List<Object?> get props => [
    reportRecipient,
    gmailAddress,
    buildReport,
    appPassword,
    emails,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
