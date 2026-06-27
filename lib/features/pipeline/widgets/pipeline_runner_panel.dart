import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

import 'pipeline_runner_panel_body.dart';
import '../bloc/pipeline_bloc.dart';

class PipelineRunnerPanel extends StatelessWidget {
  const PipelineRunnerPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PipelineBloc, PipelineState, PipelineState>(
      builder: (_, s) => PipelineRunnerPanelBody(state: s),
      selector: (state) => state,
    );
  }
}
