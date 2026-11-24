enum DistributionResultStatus { success, skipped, failed }

class const DistributionResult._({
  required final DistributionResultStatus status,
  required final String message,
}) {
  factory success([String message = '']) =>
      DistributionResult._(status: .success, message: message);

  factory skipped(String reason) =>
      DistributionResult._(status: .skipped, message: reason);

  factory failed(String reason) =>
      DistributionResult._(status: .failed, message: reason);

  bool get isSuccess => status == .success;
  bool get isSkipped => status == .skipped;
  bool get isFailed => status == .failed;

  DistributionResult copyWith({String? message}) =>
      DistributionResult._(status: status, message: message ?? this.message);
}
