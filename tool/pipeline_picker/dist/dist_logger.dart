import 'dart:io';

import 'package:fluship/services/distribution/contracts/distribution_logger.dart';
import 'package:fluship/services/distribution/models/distribution_result.dart';

class StdoutDistributionLogger implements DistributionLogger {
  const StdoutDistributionLogger();

  @override
  Future<void> logLine(DistributionResult result) async {
    stdout.write(result.message);
  }
}
