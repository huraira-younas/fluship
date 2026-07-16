import 'package:fluship/features/config/bloc/config_bloc.dart';

abstract interface class PipelineConfigSource {
  Future<void> persistActiveProfile();
  ConfigState get state;
}

final class ConfigBlocPipelineSource implements PipelineConfigSource {
  const ConfigBlocPipelineSource(this._bloc);
  final ConfigBloc _bloc;

  @override
  ConfigState get state => _bloc.state;

  @override
  Future<void> persistActiveProfile() => _bloc.persistActiveProfile();
}
