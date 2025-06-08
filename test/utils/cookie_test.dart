import 'package:test/test.dart';
import 'package:mockwebserver_dart/src/utils/cookie.dart';

void main() {
  group('parseCookieString', () {
    test('returns empty map for empty string', () {
      expect(parseCookieString(''), isEmpty);
    });

    test('parses single cookie', () {
      final cookies = parseCookieString('name=value');
      expect(cookies, {'name': 'value'});
    });

    test('parses multiple cookies', () {
      final cookies = parseCookieString('name1=value1; name2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('trims whitespace', () {
      final cookies = parseCookieString(' name = value ; name2 = value2 ');
      expect(cookies, {'name': 'value', 'name2': 'value2'});
    });

    test('skips empty parts', () {
      final cookies = parseCookieString('name1=value1;;name2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('skips parts without equals sign', () {
      final cookies = parseCookieString('name1=value1;invalid;name2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('skips parts with empty name', () {
      final cookies = parseCookieString('=value1;name2=value2');
      expect(cookies, {'name2': 'value2'});
    });

    test('handles quoted values', () {
      final cookies = parseCookieString('name="value"');
      expect(cookies, {'name': 'value'});
    });

    test('skips cookies with invalid name characters', () {
      final cookies = parseCookieString('name=value; invalid name=value2');
      expect(cookies, {'name': 'value'});
    });

    test('skips cookies with invalid value characters', () {
      final cookies = parseCookieString('name=value; name2=invalid\u0000value');
      expect(cookies, {'name': 'value'});
    });

    test('returns unmodifiable map', () {
      final cookies = parseCookieString('name=value');
      expect(() => cookies['new'] = 'value', throwsUnsupportedError);
    });

    test('handles real-world cookie string', () {
      final cookies = parseCookieString(
        'sessionId=abc123; user=john; theme=dark; lastVisit=2024-03-20',
      );
      expect(cookies, {
        'sessionId': 'abc123',
        'user': 'john',
        'theme': 'dark',
        'lastVisit': '2024-03-20',
      });
    });

    // Additional test cases
    test('handles cookies with valid special characters in value', () {
      final cookies = parseCookieString(r'name=value!@#$%^&*()_+-=[]{}|');
      expect(cookies, {'name': 'value!@#\$%^&*()_+-=[]{}|'});
    });

    test('handles cookies with spaces in quoted value', () {
      final cookies = parseCookieString('name="value with spaces"');
      expect(cookies, {'name': 'value with spaces'});
    });

    test('handles cookies with semicolons in quoted values', () {
      final cookies = parseCookieString('name="value;with;semicolons"');
      expect(cookies, {'name': 'value;with;semicolons'});
    });

    test('handles cookies with escaped quotes in quoted values', () {
      final cookies = parseCookieString('name="value\\"with\\"quotes"');
      expect(cookies, {'name': 'value"with"quotes'});
    });

    test('skips cookies with non-ASCII characters', () {
      final cookies = parseCookieString('name=value\u{1F600}');
      expect(cookies, isEmpty);
    });

    test('handles cookies with multiple spaces between parts', () {
      final cookies = parseCookieString('name1=value1;    name2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('handles cookies with tabs between parts', () {
      final cookies = parseCookieString('name1=value1;\tname2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('handles cookies with newlines between parts', () {
      final cookies = parseCookieString('name1=value1;\nname2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });

    test('handles cookies with mixed whitespace between parts', () {
      final cookies = parseCookieString('name1=value1; \t\n name2=value2');
      expect(cookies, {'name1': 'value1', 'name2': 'value2'});
    });
  });
}
