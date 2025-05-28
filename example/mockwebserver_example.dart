import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockwebserver/mockwebserver.dart';
import 'dart:io';

void main() async {
  // Create a mock server with a GET and POST handler
  final server = setupServer([
    on('GET', 'hello', (req) async => Response.ok('Hello, world!')),
    on('POST', 'echo', (req) async {
      final body = await req.readAsString();
      return Response.ok(
        jsonEncode({'echo': body}),
        headers: {'content-type': 'application/json'},
      );
    }),
  ]);

  await server.listen();
  print('Mock server running at http://localhost:${server.port}');

  // Make a GET request to the hello endpoint
  final client = http.Client();
  final getResponse = await client.get(
    Uri.parse('http://localhost:${server.port}/hello'),
  );
  print('GET Response: ${getResponse.body}');

  // Make a POST request to the echo endpoint
  final postResponse = await client.post(
    Uri.parse('http://localhost:${server.port}/echo'),
    body: 'Hello from POST request',
  );
  print('POST Response: ${postResponse.body}');

  client.close();

  // To stop the server:
  await server.close();

  print('Server closed');
  exit(0);
}
