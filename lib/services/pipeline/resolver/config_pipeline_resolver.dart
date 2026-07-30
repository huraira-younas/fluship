import 'package:fluship/services/distribution/contracts/distribution_handler.dart';
import 'package:fluship/services/distribution/contracts/distribution_context.dart';
import 'package:fluship/features/config/bloc/config_bloc.dart';

import '../artifacts/pipeline_run_artifacts.dart';
import 'distribution_step_kind.dart';
import 'step_resolvers.dart';
import 'command_step.dart';

class ConfigPipelineResolver {
  static List<CommandStep> resolve(
    ConfigState state, {
    required Future<DistributionContext> Function() reportContextProvider,
    required Map<DistributionStepKind, DistributionHandler> handlers,
    required Future<DistributionContext> Function() contextProvider,
    required PipelineRunArtifacts artifacts,
  }) => [
    //! Pipeline Steps In Order Of Execution
    ...resolveAppInfo(state),
    ...resolvePreGit(state),
    ...resolveCommonCmd(state),
    ...resolveAndroid(state, artifacts: artifacts),
    ...resolveIos(state, artifacts: artifacts),
    ...resolvePostGit(state),
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
