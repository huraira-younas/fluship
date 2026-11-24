import 'package:fluship/features/config/bloc/config_bloc.dart';

abstract interface class PipelineConfigSource {
  Future<void> persistActiveProfile();
  ConfigState get state;
}

final class const ConfigBlocPipelineSource(final ConfigBloc _bloc)
    implements PipelineConfigSource {
  @override
  ConfigState get state => _bloc.state;

  @override
  Future<void> persistActiveProfile() => _bloc.persistActiveProfile();
}
