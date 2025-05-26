import 'package:mockwebserver/mockwebserver.dart';
import 'package:test/test.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';

void main() {
  group('MockWebServer', () {
    late MockWebServer server;

    setUp(() async {
      server = setupServer([
        on('GET', 'hello', (req) async => Response.ok('Hello, test!')),
        on('POST', 'echo', (req) async {
          final body = await req.readAsString();
          return Response.ok(jsonEncode({'echo': body}), headers: {'content-type': 'application/json'});
        }),
      ]);
      await server.listen();
    });

    tearDown(() async {
      await server.close();
    });

    test('responds to GET /hello', () async {
      final url = Uri.parse('http://localhost:${server.port}/hello');
      final response = await HttpClient().getUrl(url).then((req) => req.close());
      final body = await response.transform(utf8.decoder).join();
      expect(response.statusCode, 200);
      expect(body, 'Hello, test!');
    });

    test('responds to POST /echo', () async {
      final url = Uri.parse('http://localhost:${server.port}/echo');
      final client = HttpClient();
      final request = await client.postUrl(url);
      request.write('ping');
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      expect(response.statusCode, 200);
      expect(jsonDecode(body), {'echo': 'ping'});
    });

    test('returns 404 for unknown route', () async {
      final url = Uri.parse('http://localhost:${server.port}/notfound');
      final response = await HttpClient().getUrl(url).then((req) => req.close());
      expect(response.statusCode, 404);
    });
  });
}
