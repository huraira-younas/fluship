import 'json_parser.dart';

extension type JsonModelReader._(
  ({Map<String, dynamic> json, Type modelType}) _data,
) {
  new(Map<String, dynamic> json, Type modelType)
    : _data = (json: json, modelType: modelType);

  T parse<T>(String key, {T? defaultValue}) => JsonParser.parse<T>(
    defaultValue: defaultValue,
    modelType: _data.modelType,
    _data.json[key],
    field: key,
  );

  List<T> list<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson, {
    List<T> defaultValue = const [],
  }) => JsonParser.list<T>(
    defaultValue: defaultValue,
    modelType: _data.modelType,
    _data.json[key],
    field: key,
    fromJson,
  );

  T? objectOrNull<T>(T Function(Map<String, dynamic>) fromJson, String key) =>
      JsonParser.objectOrNull<T>(
        modelType: _data.modelType,
        _data.json[key],
        field: key,
        fromJson,
      );

  T object<T>(String key, T Function(Map<String, dynamic>) fromJson) =>
      JsonParser.object<T>(
        modelType: _data.modelType,
        _data.json[key],
        field: key,
        fromJson,
      );
}

extension JsonMapParser on Map<String, dynamic> {
  JsonModelReader at<T>() => JsonModelReader(this, T);
}
