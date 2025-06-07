import 'dart:collection';

/// Parse a cookie string from a request header.
/// Returns an unmodifiable map of cookie names to values.
///
/// Example:
/// ```dart
/// final cookies = parseCookieString('name1=value1; name2=value2');
/// print(cookies['name1']); // prints: value1
/// ```
Map<String, String> parseCookieString(String cookieString) {
  if (cookieString.isEmpty) {
    return const {};
  }

  final cookies = <String, String>{};
  int index = 0;

  while (index < cookieString.length) {
    // Skip leading whitespace
    while (index < cookieString.length && _isWhitespace(cookieString[index])) {
      index++;
    }
    if (index == cookieString.length) break;

    // Parse name
    final nameStart = index;
    while (index < cookieString.length &&
        cookieString[index] != '=' &&
        cookieString[index] != ';') {
      index++;
    }

    // If we hit a semicolon before an equals sign, skip to next cookie
    if (index == cookieString.length || cookieString[index] == ';') {
      index++;
      continue;
    }

    final name = cookieString.substring(nameStart, index).trim();
    if (name.isEmpty) {
      // Skip to next cookie
      index++;
      continue;
    }

    // Skip '='
    index++;

    // Parse value
    String value;
    if (index < cookieString.length && cookieString[index] == '"') {
      // Handle quoted value
      index++;
      final valueStart = index;
      while (index < cookieString.length) {
        if (cookieString[index] == '"' && cookieString[index - 1] != '\\') {
          break;
        }
        index++;
      }
      if (index == cookieString.length) break;
      value = cookieString.substring(valueStart, index);
      value = value.replaceAll('\\"', '"');
      index++;
    } else {
      // Handle unquoted value
      final valueStart = index;
      while (index < cookieString.length && cookieString[index] != ';') {
        index++;
      }
      value = cookieString.substring(valueStart, index).trim();
    }

    try {
      _validateName(name);
      _validateValue(value);
      cookies[name] = value;
    } catch (e) {
      // Skip invalid cookies
    }

    // Skip to next cookie
    while (index < cookieString.length && cookieString[index] != ';') {
      index++;
    }
    index++;
  }

  return UnmodifiableMapView(cookies);
}

/// Check if a character is whitespace.
bool _isWhitespace(String char) {
  return char == ' ' || char == '\t' || char == '\n' || char == '\r';
}

/// Validates a cookie name according to RFC 6265.
/// Throws [FormatException] if the name is invalid.
void _validateName(String name) {
  const separators = [
    "(",
    ")",
    "<",
    ">",
    "@",
    ",",
    ";",
    ":",
    "\\",
    '"',
    "/",
    "[",
    "]",
    "?",
    "=",
    "{",
    "}",
  ];

  if (name.isEmpty) {
    throw FormatException('Cookie name cannot be empty');
  }

  for (int i = 0; i < name.length; i++) {
    int codeUnit = name.codeUnitAt(i);
    if (codeUnit <= 32 || codeUnit >= 127 || separators.contains(name[i])) {
      throw FormatException(
        'Invalid character in cookie name, code unit: \'$codeUnit\'',
        name,
        i,
      );
    }
  }
}

/// Validates a cookie value according to RFC 6265.
/// Throws [FormatException] if the value is invalid.
void _validateValue(String value) {
  if (value.isEmpty) return;

  for (int i = 0; i < value.length; i++) {
    int codeUnit = value.codeUnitAt(i);
    if (codeUnit < 0x20 || codeUnit >= 0x7F) {
      throw FormatException(
        'Invalid character in cookie value, code unit: \'$codeUnit\'',
        value,
        i,
      );
    }
  }
}
