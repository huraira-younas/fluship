import 'package:fluship/features/config/bloc/config_bloc.dart';

import 'step_resolvers.dart';
import 'command_step.dart';

typedef StepResolver = List<CommandStep> Function(ConfigState state);

class ConfigPipelineResolver {
  static const _resolvers = <StepResolver>[
    //! Pipeline Steps In Order Of Execution
    resolveAppInfo,
    resolvePreGit,
    resolveCommonCmd,
    resolveAndroid,
    resolveIos,
    resolvePostGit,
    resolveDistribution,
    resolvePostBuild,
  ];

  static List<CommandStep> resolve(ConfigState state) => [
    for (final resolver in _resolvers) ...resolver(state),
  ];
}

extension ConfigStatePipeline on ConfigState {
  List<CommandStep> get pipelineSteps => ConfigPipelineResolver.resolve(this);
}
