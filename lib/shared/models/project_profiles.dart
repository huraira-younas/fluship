import 'package:fluship/features/config/bloc/config_bloc.dart';
import 'package:equatable/equatable.dart';

class ProjectProfile extends Equatable {
  final ConfigState config;
  final String name;
  final String id;

  const ProjectProfile({
    required this.config,
    required this.name,
    required this.id,
  });

  Map<String, dynamic> toJson() => {
    'config': config.toJson(),
    'name': name,
    'id': id,
  };

  factory ProjectProfile.fromJson(Map<String, dynamic> json) => ProjectProfile(
    config: ConfigState.fromJson(json['config']),
    name: json['name'],
    id: json['id'],
  );

  @override
  List<Object?> get props => [config, name, id];
}

class ProjectProfiles extends Equatable {
  final List<ProjectProfile> profiles;
  final String activeProfileId;
  
  const ProjectProfiles({
    required this.activeProfileId,
    required this.profiles,
  });

  factory ProjectProfiles.fromJson(
    Map<String, dynamic> json,
    String projectName,
  ) => ProjectProfiles(
    activeProfileId: json[projectName]['activeProfileId'],
    profiles: json[projectName]['profiles']
        .map((e) => ProjectProfile.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson(String projectName) => {
    projectName: {
      'profiles': profiles.map((e) => e.toJson()).toList(),
      'activeProfileId': activeProfileId,
    },
  };

  @override
  List<Object?> get props => [profiles];
}
