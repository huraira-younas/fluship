part of 'base_bloc.dart';

abstract class const BaseBlocEvent({
  required final void Function(dynamic data)? onSuccess,
  required final void Function(CustomState errorState)? onError,
  required final String name,
}) extends Equatable {
  Map<String, dynamic> toJson();

  @override
  List<Object?> get props => [name];
}
