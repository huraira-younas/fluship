import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import '../bloc/pipeline_bloc.dart';
import 'pipeline_runner_panel_body.dart';

class PipelineRunnerPanel extends StatelessWidget {
  const PipelineRunnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PipelineBloc, PipelineState, PipelineState>(
      selector: (state) => state,
      builder: (context, state) {
        return state.isPanelVisible
            ? PipelineRunnerPanelBody(state: state)
            : const SizedBox.shrink();
      },
    );
  }
}
