import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';

import 'distribution_step_kind.dart';
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
  ];

  static List<CommandStep> resolve(
    ConfigState state, {
    required Future<DistributionContext> Function() reportContextProvider,
    required Map<DistributionStepKind, DistributionHandler> handlers,
    required Future<DistributionContext> Function() contextProvider,
  }) => [
    for (final resolver in _resolvers) ...resolver(state),
    ...resolveDistribution(
      contextProvider: contextProvider,
      handlers: handlers,
      state,
    ),
    ...resolvePostBuild(state),
    ...resolveReport(
      contextProvider: reportContextProvider,
      handlers: handlers,
      state,
    ),
  ];
}
