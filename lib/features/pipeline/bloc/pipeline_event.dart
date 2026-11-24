part of 'pipeline_bloc.dart';

sealed class const PipelineEvent({
  required super.name,
  super.onError,
  super.onSuccess,
}) extends BaseBlocEvent;

class const RunPipeline({super.onError, super.onSuccess})
    extends PipelineEvent {
  this : super(name: 'Run_Pipeline');

  @override
  Map<String, dynamic> toJson() => {};
}

class const CancelPipeline({super.onError, super.onSuccess})
    extends PipelineEvent {
  this : super(name: 'Cancel_Pipeline');

  @override
  Map<String, dynamic> toJson() => {};
}

class const RemovePipelineStep(
  final int index, {
  super.onError,
  super.onSuccess,
}) extends PipelineEvent {
  this : super(name: 'Remove_Pipeline_Step');

  @override
  Map<String, dynamic> toJson() => {'index': index};
}

class const DismissPipelinePanel({super.onError, super.onSuccess})
    extends PipelineEvent {
  this : super(name: 'Dismiss_Pipeline_Panel');

  @override
  Map<String, dynamic> toJson() => {};
}
