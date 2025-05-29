<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

# mockwebserver-dart

A Dart implementation of a mock web server, inspired by [MSWJS](https://mswjs.io/).

## Features

- Simple API for defining mock handlers
- Path parameter support (e.g., `/users/:id`)
- Handler management with `use` and `resetHandlers`
- Built on top of [shelf](https://pub.dev/packages/shelf)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  mockwebserver: ^0.1.0
```

## Usage

```dart
import 'package:mockwebserver/mockwebserver.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  // Make requests to the mock server
  final url = Uri.parse('http://localhost:${server.port}/hello');
  final response = await http.get(url);
  print(response.body); // Hello, test!

  // Add new handlers
  server.use([
    on('GET', 'new', (context) async => Response.ok('New handler!')),
  ]);

  // Reset to initial handlers
  server.resetHandlers();

  // Or set new handlers
  server.resetHandlers([
    on('GET', 'custom', (context) async => Response.ok('Custom handler!')),
  ]);

  // Clean up
  await server.close();
}
```

## API

### `setupServer([List<RouteHandler> handlers = const []])`

Creates a new mock server instance with optional initial handlers.

### `on(String method, String path, MockHandler handler)`

Creates a route handler for a specific HTTP method and path.

### `MockWebServer`

#### `use(List<RouteHandler> handlers)`

Adds new handlers to the server.

#### `resetHandlers([List<RouteHandler>? nextHandlers])`

Resets all handlers to their initial state or to the provided handlers.

#### `listen({int port = 0})`

Starts the server on the specified port (0 for random port).

#### `close()`

Stops the server.

#### `port`

Gets the port the server is listening on.

### Path Parameters

You can use path parameters in your routes by prefixing the parameter name with `:`. The parameter value will be available in the handler through the `RequestContext`:

```dart
on('GET', 'users/:id', (context) async {
  final id = context.param('id');
  return Response.ok(jsonEncode({'id': id}));
})
```

## License

MIT

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
