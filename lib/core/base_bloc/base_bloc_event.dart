part of 'base_bloc.dart';

abstract class BaseBlocEvent extends Equatable {
  final void Function(CustomState errorState)? onError;
  final void Function(dynamic data)? onSuccess;
  final String name;

  const BaseBlocEvent({
    required this.onSuccess,
    required this.onError,
    required this.name,
  });

  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [name];
}
