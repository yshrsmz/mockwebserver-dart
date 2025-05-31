import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockwebserver/mockwebserver.dart';
import 'dart:io';

void main() async {
  // Setup the mock server with initial handlers
  final server = setupServer([
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
  ]);

  // Start the server
  await server.listen();
  print('Server running on port ${server.port}');

  try {
    // Test initial handlers
    print('\nTesting initial handlers:');

    final helloUrl = Uri.parse('http://localhost:${server.port}/hello');
    var response = await http.get(helloUrl);
    print('GET /hello: ${response.body}');

    final echoUrl = Uri.parse('http://localhost:${server.port}/echo');
    response = await http.post(echoUrl, body: 'ping');
    print('POST /echo: ${response.body}');

    final userUrl = Uri.parse('http://localhost:${server.port}/users/123');
    response = await http.get(userUrl);
    print('GET /users/123: ${response.body}');

    // Test adding new handlers
    print('\nAdding new handlers:');
    server.use([
      on('GET', 'new', (context) async => Response.ok('New handler!')),
    ]);

    final newUrl = Uri.parse('http://localhost:${server.port}/new');
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
      on('GET', 'custom', (context) async => Response.ok('Custom handler!')),
    ]);

    final customUrl = Uri.parse('http://localhost:${server.port}/custom');
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
