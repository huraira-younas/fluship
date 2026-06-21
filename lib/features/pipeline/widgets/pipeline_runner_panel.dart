import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'pipeline_runner_panel_body.dart';
import '../bloc/pipeline_bloc.dart';

class PipelineRunnerPanel extends StatelessWidget {
  const PipelineRunnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PipelineBloc, PipelineState, PipelineState>(
      selector: (state) => state,
      builder: (context, state) {
        return AnimatedSize(
          duration: const Duration(milliseconds: 1000),
          child: state.isPanelVisible
              ? PipelineRunnerPanelBody(state: state)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}
