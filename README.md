# mockwebserver-dart

A Dart implementation of a mock web server, inspired by [MSWJS](https://mswjs.io/).

## Features

- Simple API for defining mock handlers
- Path parameter support (e.g., `/users/:id`)
- Handler management with `use` and `resetHandlers`
- Built on top of [shelf](https://pub.dev/packages/shelf)
- One-time handlers for testing specific scenarios
- Support for all HTTP methods (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dev_dependencies:
  mockwebserver_dart: ^0.1.0
```

## Usage

```dart
import 'package:mockwebserver/mockwebserver.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  // Setup the mock server with initial handlers
  final server = MockWebServer.setup([
    HttpHandler.get('hello', (request, extra) async => Response.ok('Hello, test!')),
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

  final url = switch (server.url) {
    final url? => url,
    null => throw Exception('Failed to get server URL'),
  };

  // Make requests to the mock server
  final url = Uri.parse('$url/hello');
  final response = await http.get(url);
  print(response.body); // Hello, test!

  // Add new handlers
  server.use([
    HttpHandler.get('new', (request, extra) async => Response.ok('New handler!')),
  ]);

  // Reset to initial handlers
  server.resetHandlers();

  // Or set new handlers
  server.resetHandlers([
    HttpHandler.get('custom', (request, extra) async => Response.ok('Custom handler!')),
  ]);

  // Clean up
  await server.close();
}
```

## API

### `MockWebServer.setup([List<RequestHandler> handlers = const []])`

Creates a new mock server instance with optional initial handlers.

### HTTP Method Handlers

The package provides factory constructors for all HTTP methods:

- `HttpHandler.get(String path, ResponseResolver resolver)`
- `HttpHandler.post(String path, ResponseResolver resolver)`
- `HttpHandler.put(String path, ResponseResolver resolver)`
- `HttpHandler.delete(String path, ResponseResolver resolver)`
- `HttpHandler.patch(String path, ResponseResolver resolver)`
- `HttpHandler.head(String path, ResponseResolver resolver)`
- `HttpHandler.options(String path, ResponseResolver resolver)`
- `HttpHandler.any(String path, ResponseResolver resolver)` - matches any HTTP method

### Handler Options

You can configure handlers with options:

```dart
HttpHandler.get(
  'path',
  (request, extra) async => Response.ok('data'),
  options: HttpHandlerOptions(once: true), // Handler will only be used once
)
```

### `MockWebServer`

#### `use(List<RequestHandler> handlers)`

Adds new handlers to the server.

#### `resetHandlers([List<RequestHandler>? nextHandlers])`

Resets all handlers to their initial state or to the provided handlers.

#### `listen({int port = 0})`

Starts the server on the specified port (0 for random port).

#### `close()`

Stops the server.

#### `port`

Gets the port the server is listening on.

### Request Context

The `ResponseResolver` function receives two parameters:

1. `Request request` - The original shelf request object
2. `HttpRequestExtra extra` - Additional parsed request data:
   - `params` - Path parameters (e.g., `:id` from the URL)
   - `cookies` - Parsed request cookies

## Development

This project uses GitHub Actions for continuous integration. The workflow:

- Runs on push to main and pull requests
- Uses mise for Dart SDK management
- Verifies code formatting
- Runs static analysis
- Executes unit tests

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## TODO

- [ ] document how to use along with mockito and other mocking packages to track which handler is called with what request
- [ ] add support/document for other content type such as Protocol Buffers
