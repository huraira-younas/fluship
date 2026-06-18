part of 'distribution_config.dart';

class ReportRecipientConfig extends Equatable {
  final List<DistributionEmail> emails;
  final String? reportRecipient;
  final String? gmailAddress;
  final String? appPassword;

  const ReportRecipientConfig({
    this.emails = const [],
    this.reportRecipient,
    this.gmailAddress,
    this.appPassword,
  });

  ReportRecipientConfig copyWith({
    List<DistributionEmail>? emails,
    String? reportRecipient,
    String? gmailAddress,
    String? appPassword,
  }) => ReportRecipientConfig(
    reportRecipient: reportRecipient ?? this.reportRecipient,
    gmailAddress: gmailAddress ?? this.gmailAddress,
    appPassword: appPassword ?? this.appPassword,
    emails: emails ?? this.emails,
  );

  factory ReportRecipientConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ReportRecipientConfig();

    final data = json.at<ReportRecipientConfig>();
    return ReportRecipientConfig(
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
    'appPassword': appPassword,
  };

  @override
  List<Object?> get props => [
    reportRecipient,
    gmailAddress,
    appPassword,
    emails,
  ];

  @override
  String toString() => toJson().toString();

  @override
  bool? get stringify => true;
}
