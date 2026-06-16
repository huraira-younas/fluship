typedef ValidatorFunction = String? Function(String? value);

// Hoisted: avoid allocating RegExp on every validate() / keystroke.
final _email = RegExp(
  r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$",
);

final _hostHexColon = RegExp(r'^[0-9a-f:]+$', caseSensitive: false);
final _numDecimal = RegExp(r'^[-+]?[0-9]*\.?[0-9]*$');
final _hostIpv4 = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
final _phoneDigits = RegExp(r'^\+[1-9]\d{9,14}$');
final _hostTldChars = RegExp(r'^[a-z0-9-]+$');
final _numInteger = RegExp(r'^[-+]?[0-9]*$');
final _whitespaceOrDash = RegExp(r'\s+|-');
final _dollarPrefix = RegExp(r'^\$\s*');

bool _isPlausibleWebHost(String host) {
  if (host.isEmpty) return false;
  final h = host.toLowerCase();
  if (h == 'localhost') return true;
  if (_hostIpv4.hasMatch(host)) return true;
  if (h.contains(':') && _hostHexColon.hasMatch(h)) {
    return h.split(':').length > 1;
  }
  if (!h.contains('.')) return false;
  final parts = h.split('.');
  if (parts.length < 2) return false;
  final tld = parts.last;
  return tld.length >= 2 && _hostTldChars.hasMatch(tld);
}

class ValidatorBuilder {
  final List<ValidatorFunction> _validators = [];

  ValidatorBuilder._();

  static ValidatorBuilder chain() => ValidatorBuilder._();

  ValidatorBuilder url([
    String message = 'Invalid URL',
    bool requireScheme = false,
  ]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      final s = value.trim();
      var uri = Uri.tryParse(s);
      if (uri == null) return message;
      if (!uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        if (requireScheme) return message;
        if (s.contains('://')) return message;
        uri = Uri.tryParse('https://$s');
      }
      if (uri == null) return message;
      if (!uri.isScheme('http') && !uri.isScheme('https')) return message;
      if (uri.host.isEmpty) return message;
      return _isPlausibleWebHost(uri.host) ? null : message;
    });
    return this;
  }

  ValidatorBuilder required([String message = 'Required field']) {
    _validators.add((value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    });
    return this;
  }

  ValidatorBuilder email([String message = 'Invalid email']) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      return _email.hasMatch(value.trim()) ? null : message;
    });
    return this;
  }

  ValidatorBuilder number(bool decimal, [String message = 'Invalid number']) {
    final pattern = decimal ? _numDecimal : _numInteger;
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      final normalized = value.trim().replaceFirst(_dollarPrefix, '');
      return pattern.hasMatch(normalized) ? null : message;
    });
    return this;
  }

  ValidatorBuilder phone([
    String message =
        'Enter a valid phone number with country code (e.g. +1234567890)',
  ]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      final phone = value.trim().replaceAll(_whitespaceOrDash, '');
      return _phoneDigits.hasMatch(phone) ? null : message;
    });
    return this;
  }

  ValidatorBuilder min(int len, [String? message]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      return value.length >= len
          ? null
          : (message ?? 'Minimum $len characters');
    });
    return this;
  }

  ValidatorBuilder max(int len, [String? message]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      return value.length <= len
          ? null
          : (message ?? 'Maximum $len characters');
    });
    return this;
  }

  ValidatorBuilder length(int len, [String? message]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      return value.length == len
          ? null
          : (message ?? 'Must be $len characters');
    });
    return this;
  }

  ValidatorBuilder matches(
    RegExp pattern, [
    String message = 'Invalid format',
  ]) {
    _validators.add((value) {
      if (value == null || value.isEmpty) return null;
      return pattern.hasMatch(value) ? null : message;
    });
    return this;
  }

  ValidatorBuilder oneOf(
    String? Function() other, [
    String message = 'Values must match',
  ]) {
    _validators.add((value) {
      final o = other();
      if (value == null || o == null) return null;
      return value == o ? null : message;
    });
    return this;
  }

  ValidatorBuilder custom(ValidatorFunction fn) {
    _validators.add(fn);
    return this;
  }

  ValidatorFunction build() {
    return (value) {
      for (final v in _validators) {
        final result = v(value);
        if (result != null) return result;
      }
      return null;
    };
  }
}
