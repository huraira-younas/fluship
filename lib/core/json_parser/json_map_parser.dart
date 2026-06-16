import 'json_parser.dart';

extension type JsonModelReader._((Map<String, dynamic>, Type) _data) {
  JsonModelReader(Map<String, dynamic> json, Type modelType)
    : _data = (json, modelType);

  T parse<T>(String key, {T? defaultValue}) => JsonParser.parse<T>(
    defaultValue: defaultValue,
    modelType: _data.$2,
    _data.$1[key],
    field: key,
  );

  List<T> list<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    List<T> defaultValue = const [],
  }) => JsonParser.list<T>(
    defaultValue: defaultValue,
    modelType: _data.$2,
    _data.$1[key],
    field: key,
    fromJson,
  );

  T? objectOrNull<T>(T Function(Map<String, dynamic>) fromJson, String key) =>
      JsonParser.objectOrNull<T>(
        modelType: _data.$2,
        _data.$1[key],
        field: key,
        fromJson,
      );

  T object<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      JsonParser.object<T>(
        modelType: _data.$2,
        _data.$1[key],
        field: key,
        fromJson,
      );
}

extension JsonMapParser on Map<String, dynamic> {
  JsonModelReader at<T>() => JsonModelReader(this, T);
}
