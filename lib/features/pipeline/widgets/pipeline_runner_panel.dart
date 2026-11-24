import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'pipeline_runner_panel_body.dart';
import '../bloc/pipeline_bloc.dart';

class const PipelineRunnerPanel({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocSelector<PipelineBloc, PipelineState, PipelineState>(
      builder: (_, s) => PipelineRunnerPanelBody(state: s),
      selector: (state) => state,
    );
  }
}
