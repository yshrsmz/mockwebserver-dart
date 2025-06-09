import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockwebserver_dart/http.dart';
import 'package:mockwebserver_dart/mockwebserver.dart';

void main() async {
  // Setup the mock server with initial handlers
  final server = MockWebServer.setup([
    HttpHandler.get(
      'hello',
      (request, extra) async => Response.ok('Hello, test!'),
    ),
    HttpHandler.post('echo', (request, extra) async {
      final body = await request.readAsString();

      return Response.ok(
        jsonEncode({'echo': body}),
        headers: {'content-type': 'application/json'},
      );
    }),
    HttpHandler.get('users/:id', (request, extra) async {
      final id = extra.params['id'];
      return Response.ok(jsonEncode({'id': id}));
    }),
  ]);

  // Start the server
  await server.listen();
  print('Server running on port ${server.port}');

  final url = switch (server.url) {
    final url? => url,
    null => throw Exception('Failed to get server URL'),
  };
  print('Server URL: $url');

  try {
    // Test initial handlers
    print('\nTesting initial handlers:');

    final helloUrl = Uri.parse('$url/hello');
    var response = await http.get(helloUrl);
    print('GET /hello: ${response.body}');

    final echoUrl = Uri.parse('$url/echo');
    response = await http.post(echoUrl, body: 'ping');
    print('POST /echo: ${response.body}');

    final userUrl = Uri.parse('$url/users/123');
    response = await http.get(userUrl);
    print('GET /users/123: ${response.body}');

    // Test adding new handlers
    print('\nAdding new handlers:');
    server.use([
      HttpHandler.get(
        'new',
        (request, extra) async => Response.ok('New handler!'),
      ),
    ]);

    final newUrl = Uri.parse('$url/new');
    response = await http.get(newUrl);
    print('GET /new: ${response.body}');

    // Test resetting to initial handlers
    print('\nResetting to initial handlers:');
    server.resetHandlers();

    response = await http.get(newUrl);
    print('GET /new (after reset): ${response.statusCode}');

    // Test setting new handlers
    print('\nSetting new handlers:');
    server.resetHandlers([
      HttpHandler.get(
        'custom',
        (request, extra) async => Response.ok('Custom handler!'),
      ),
    ]);

    final customUrl = Uri.parse('$url/custom');
    response = await http.get(customUrl);
    print('GET /custom: ${response.body}');

    // Verify old handlers are gone
    response = await http.get(helloUrl);
    print('GET /hello (after new handlers): ${response.statusCode}');
  } finally {
    // Clean up
    await server.close();
    print('\nServer closed');
  }
}
