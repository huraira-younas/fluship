import 'package:equatable/equatable.dart';

abstract class BaseConfig extends Equatable {
  const BaseConfig({required this.enabled});

  final bool enabled;

  BaseConfig copyWith({bool? enabled});
  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [enabled];
}
