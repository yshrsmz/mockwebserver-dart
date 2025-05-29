import 'package:mockwebserver/mockwebserver.dart';
import 'package:test/test.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  group('MockWebServer', () {
    late MockWebServer server;

    setUp(() async {
      server = setupServer([
        on('GET', 'hello', (context) async => Response.ok('Hello, test!')),
        on('POST', 'echo', (context) async {
          final body = await context.request.readAsString();
          return Response.ok(
            jsonEncode({'echo': body}),
            headers: {'content-type': 'application/json'},
          );
        }),
        on('GET', 'users/:id', (context) async {
          final id = context.param('id');
          return Response.ok(jsonEncode({'id': id}));
        }),
        on('GET', 'users/:id/posts/:postId', (context) async {
          final id = context.param('id');
          final postId = context.param('postId');
          return Response.ok(jsonEncode({'userId': id, 'postId': postId}));
        }),
      ]);
      await server.listen();
    });

    tearDown(() async {
      await server.close();
    });

    test('responds to GET /hello', () async {
      final url = Uri.parse('http://localhost:${server.port}/hello');
      final response = await http.get(url);
      expect(response.statusCode, 200);
      expect(response.body, 'Hello, test!');
    });

    test('responds to POST /echo', () async {
      final url = Uri.parse('http://localhost:${server.port}/echo');
      final response = await http.post(url, body: 'ping');
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), {'echo': 'ping'});
    });

    test('returns 404 for unknown route', () async {
      final url = Uri.parse('http://localhost:${server.port}/notfound');
      final response = await http.get(url);
      expect(response.statusCode, 404);
    });

    test('handles path parameters', () async {
      final url = Uri.parse('http://localhost:${server.port}/users/123');
      final response = await http.get(url);
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), {'id': '123'});
    });

    test('handles multiple path parameters', () async {
      final url = Uri.parse(
        'http://localhost:${server.port}/users/123/posts/456',
      );
      final response = await http.get(url);
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), {'userId': '123', 'postId': '456'});
    });

    test('can reset handlers to initial state', () async {
      // First verify original handler works
      final url = Uri.parse('http://localhost:${server.port}/hello');
      var response = await http.get(url);
      expect(response.body, 'Hello, test!');

      // Add a new handler
      server.use([
        on('GET', 'new', (context) async => Response.ok('New handler!')),
      ]);

      // Verify new handler works
      final newUrl = Uri.parse('http://localhost:${server.port}/new');
      response = await http.get(newUrl);
      expect(response.body, 'New handler!');

      // Reset to initial state
      server.resetHandlers();

      // Verify new handler is gone
      response = await http.get(newUrl);
      expect(response.statusCode, 404);

      // Verify original handler still works
      response = await http.get(url);
      expect(response.body, 'Hello, test!');
    });

    test('can set new handlers and reset to them', () async {
      // First verify original handler works
      final url = Uri.parse('http://localhost:${server.port}/hello');
      var response = await http.get(url);
      expect(response.body, 'Hello, test!');

      // Set new handlers
      final newHandlers = [
        on('GET', 'new', (context) async => Response.ok('New handler!')),
      ];
      server.resetHandlers(newHandlers);

      // Verify old handler is gone
      response = await http.get(url);
      expect(response.statusCode, 404);

      // Verify new handler works
      final newUrl = Uri.parse('http://localhost:${server.port}/new');
      response = await http.get(newUrl);
      expect(response.body, 'New handler!');

      // Add temporary handler
      server.use([
        on('GET', 'temp', (context) async => Response.ok('Temporary handler!')),
      ]);

      // Verify temporary handler works
      final tempUrl = Uri.parse('http://localhost:${server.port}/temp');
      response = await http.get(tempUrl);
      expect(response.body, 'Temporary handler!');

      // Reset to new handlers
      server.resetHandlers(newHandlers);

      // Verify temporary handler is gone
      response = await http.get(tempUrl);
      expect(response.statusCode, 404);

      // Verify new handler still works
      response = await http.get(newUrl);
      expect(response.body, 'New handler!');

      // Reset to initial state
      server.resetHandlers();

      // Verify we're back to original handlers
      response = await http.get(url);
      expect(response.body, 'Hello, test!');
    });

    test('can add multiple handlers at once', () async {
      server.resetHandlers();
      server.use([
        on('GET', 'one', (context) async => Response.ok('One')),
        on('GET', 'two', (context) async => Response.ok('Two')),
      ]);

      final url1 = Uri.parse('http://localhost:${server.port}/one');
      final url2 = Uri.parse('http://localhost:${server.port}/two');

      var response = await http.get(url1);
      expect(response.body, 'One');

      response = await http.get(url2);
      expect(response.body, 'Two');
    });

    test('can add a single handler', () async {
      server.resetHandlers();
      server.use([
        on('GET', 'single', (context) async => Response.ok('Single handler')),
      ]);

      final url = Uri.parse('http://localhost:${server.port}/single');
      final response = await http.get(url);
      expect(response.body, 'Single handler');
    });
  });
}
