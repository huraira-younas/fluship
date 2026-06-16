import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluship/core/logger.dart';
import 'package:equatable/equatable.dart';
import 'dart:async' show FutureOr;

part 'base_bloc_event.dart';
part 'base_bloc_state.dart';

abstract class BaseBloc<E extends BaseBlocEvent, S extends BaseBlocState>
    extends Bloc<E, S> {
  BaseBloc(super.initialState);

  EventHandler<E, S> handler<T extends E>(
    FutureOr<dynamic> Function(Emitter<S> emit, T event) fn,
  ) {
    return (E event, Emitter<S> emit) async {
      try {
        Logger.info(tag: event.name, message: event.toJson());
        final data = await fn(emit, event as T);
        event.onSuccess?.call(data);
      } catch (e, st) {
        Logger.error(tag: event.name, message: e.toString(), stackTrace: st);
        final error = CustomState(message: e.toString(), title: event.name);
        final err = state.copyWith(error: error, loading: false) as S;
        event.onError?.call(error);
        emit(err);
      }
    };
  }
}

typedef EventHandler<E, S> = FutureOr<void> Function(E event, Emitter<S> emit);
