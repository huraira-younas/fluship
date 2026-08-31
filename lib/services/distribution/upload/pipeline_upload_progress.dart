import 'package:equatable/equatable.dart';

import 'counted_upload.dart';

enum UploadChannel { play, appStore, drive }

class PipelineUploadProgress extends Equatable {
  const PipelineUploadProgress({
    required this.fileName,
    required this.channel,
    this.bytes = 0,
    this.total = 0,
    this.fileIndex,
    this.fileCount,
    this.percent,
  });

  final UploadChannel channel;
  final String fileName;
  final int? fileIndex;
  final int? fileCount;
  final int? percent;
  final int bytes;
  final int total;

  String get channelLabel => switch (channel) {
    .appStore => 'App Store',
    .play => 'Play Store',
    .drive => 'Drive',
  };

  double? get fraction {
    final value = percent;
    if (value != null) return (value.clamp(0, 100)) / 100;
    if (total > 0) return (bytes / total).clamp(0.0, 1.0);
    return null;
  }

  String get _percentSuffix => percent == null ? '' : '  $percent%';

  String get _fileSuffix => fileIndex != null && fileCount != null
      ? '  file $fileIndex/$fileCount'
      : '';

  String get _amount => total <= 0
      ? ''
      : '${formatMegabytes(bytes)} / ${formatMegabytes(total)} MB';

  String get _detail => '$_amount$_percentSuffix$_fileSuffix';

  String get caption {
    if (total > 0) return '$_detail  $fileName';
    if (percent != null) {
      return 'Uploading $fileName$_percentSuffix$_fileSuffix';
    }
    return fileName;
  }

  String get headerLabel {
    final value = percent;
    return value == null ? channelLabel : '$channelLabel $value%';
  }

  String get panelLabel {
    final value = percent;
    return value == null
        ? 'Uploading to $channelLabel'
        : 'Uploading to $channelLabel $value%';
  }

  String get consoleLine {
    if (total > 0) return '$channelLabel  $_detail  $fileName';
    return '$channelLabel$_percentSuffix$_fileSuffix  $fileName';
  }

  @override
  List<Object?> get props => [
    fileIndex,
    fileCount,
    fileName,
    channel,
    percent,
    bytes,
    total,
  ];
}
