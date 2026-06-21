enum DistributionResultStatus { success, skipped, failed }

class DistributionResult {
  const DistributionResult._({required this.status, required this.message});

  final DistributionResultStatus status;
  final String message;

  factory DistributionResult.success([String message = '']) =>
      DistributionResult._(status: .success, message: message);

  factory DistributionResult.skipped(String reason) =>
      DistributionResult._(status: .skipped, message: reason);

  factory DistributionResult.failed(String reason) =>
      DistributionResult._(status: .failed, message: reason);

  bool get isSuccess => status == .success;
  bool get isSkipped => status == .skipped;
  bool get isFailed => status == .failed;
}
