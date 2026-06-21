import 'package:fluship/features/config/bloc/config_bloc.dart';

class DistributionPlatforms {
  const DistributionPlatforms._();

  static String fromConfig(ConfigState state) {
    final platforms = <String>[];
    if (state.android.enabled) platforms.add('Android');
    if (state.ios.enabled) platforms.add('iOS');
    return platforms.isEmpty ? 'None' : platforms.join(', ');
  }
}
