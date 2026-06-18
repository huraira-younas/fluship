part of 'pipeline_bloc.dart';

sealed class PipelineEvent extends BaseBlocEvent {
  const PipelineEvent({required super.name, super.onError, super.onSuccess});
}

class RunPipeline extends PipelineEvent {
  const RunPipeline({super.onError, super.onSuccess})
    : super(name: 'Run_Pipeline');

  @override
  Map<String, dynamic> toJson() => {};
}

class CancelPipeline extends PipelineEvent {
  const CancelPipeline({super.onError, super.onSuccess})
    : super(name: 'Cancel_Pipeline');

  @override
  Map<String, dynamic> toJson() => {};
}

class DismissPipelinePanel extends PipelineEvent {
  const DismissPipelinePanel({super.onError, super.onSuccess})
    : super(name: 'Dismiss_Pipeline_Panel');

  @override
  Map<String, dynamic> toJson() => {};
}
