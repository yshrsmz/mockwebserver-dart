import 'dart:convert';
import 'package:mockwebserver/mockwebserver.dart';

void main() async {
  // Create a mock server with a GET and POST handler
  final server = setupServer([
    on('GET', 'hello', (req) async => Response.ok('Hello, world!')),
    on('POST', 'echo', (req) async {
      final body = await req.readAsString();
      return Response.ok(jsonEncode({'echo': body}), headers: {'content-type': 'application/json'});
    }),
  ]);

  await server.listen();
  print('Mock server running at http://localhost:${server.port}');

  // To stop the server:
  // await server.close();
}
