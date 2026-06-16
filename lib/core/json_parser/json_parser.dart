/// Generic JSON field parsing for model `fromJson` factories.
///
/// ```dart
/// final data = json.at<MyModel>();
/// data.parse<int>('count', defaultValue: 0);
/// data.parse<int?>('optional');
/// data.parse<DateTime>('created_at');
/// data.parse<List<String>>('tags', defaultValue: jsonEmptyStringList);
/// ```
library;

const jsonEmptyStringList = <String>[];

final class JsonParseException implements Exception {
  const JsonParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class JsonParser {
  static T parse<T>(
    dynamic value, {
    T? defaultValue,
    String? field,
    Type? modelType,
  }) {
    if (value == null) {
      if (defaultValue != null) return defaultValue;
      try {
        return null as T;
      } on TypeError {
        throw _fieldError(field, 'cannot be null', modelType: modelType);
      }
    }
    try {
      return _coerce<T>(value);
    } on TypeError {
      throw _fieldError(
        field,
        'must be ${_typeLabel<T>()}, got ${value.runtimeType}',
        modelType: modelType,
      );
    } on FormatException {
      throw _fieldError(
        field,
        'must be a valid DateTime, got "$value"',
        modelType: modelType,
      );
    }
  }

  static List<T> list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson, {
    List<T> defaultValue = const [],
    String? field,
    Type? modelType,
  }) {
    if (value == null) return defaultValue;
    try {
      final raw = value as List<dynamic>;
      final length = raw.length;
      final result = List<T>.empty(growable: true);
      for (var i = 0; i < length; i++) {
        try {
          result.add(fromJson(raw[i] as Map<String, dynamic>));
        } on JsonParseException {
          rethrow;
        } on TypeError {
          throw _fieldError(
            field == null ? null : '$field[$i]',
            'must be ${T.toString()}, got ${raw[i].runtimeType}',
            modelType: modelType,
          );
        }
      }
      return result;
    } on TypeError {
      throw _fieldError(
        field,
        'must be List<${T.toString()}>, got ${value.runtimeType}',
        modelType: modelType,
      );
    }
  }

  static T? objectOrNull<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson, {
    Type? modelType,
    String? field,
  }) {
    if (value == null) return null;
    try {
      return fromJson(value as Map<String, dynamic>);
    } on JsonParseException {
      rethrow;
    } on TypeError {
      throw _fieldError(
        field,
        'must be ${T.toString()}, got ${value.runtimeType}',
        modelType: modelType,
      );
    }
  }

  static T object<T>(
    dynamic value,
    T Function(Map<String, dynamic>) fromJson, {
    Type? modelType,
    String? field,
  }) {
    if (value == null) {
      throw _fieldError(field, 'cannot be null', modelType: modelType);
    }

    try {
      return fromJson(value as Map<String, dynamic>);
    } on JsonParseException {
      rethrow;
    } on TypeError {
      throw _fieldError(
        field,
        'must be ${T.toString()}, got ${value.runtimeType}',
        modelType: modelType,
      );
    }
  }

  static Never _fieldError(String? field, String reason, {Type? modelType}) {
    final detail = field == null ? 'Value $reason' : 'Field "$field" $reason';
    final model = modelType?.toString();
    final message = model == null ? detail : '$model: $detail';
    throw JsonParseException(message);
  }

  static String _typeLabel<T>() {
    final base = _baseTypeName(T);
    return switch (base) {
      'List<String>' => 'List<String>',
      'DateTime' => 'DateTime',
      'double' => 'double',
      'String' => 'String',
      'bool' => 'bool',
      'int' => 'int',
      _ => '$T',
    };
  }

  static String _baseTypeName(Type type) {
    final name = type.toString();
    return name.endsWith('?') ? name.substring(0, name.length - 1) : name;
  }

  static T _coerce<T>(dynamic value) =>
      _coerceByName(_baseTypeName(T), value) as T;

  static dynamic _coerceByName(String typeName, dynamic value) =>
      switch (typeName) {
        'DateTime' => DateTime.parse(value as String),
        'double' => (value as num).toDouble(),
        'List<String>' => _stringList(value),
        'String' => value as String,
        'bool' => value as bool,
        'int' => (value as num).toInt(),
        _ => throw JsonParseException('Unsupported parse type: $typeName'),
      };

  static List<String> _stringList(dynamic value) {
    final raw = value as List<dynamic>;
    final length = raw.length;
    final result = List<String>.filled(length, '', growable: false);
    for (var i = 0; i < length; i++) {
      result[i] = raw[i] as String;
    }
    return result;
  }
}
