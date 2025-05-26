import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Type for a request handler, similar to MSWJS's request handler.
typedef MockHandler = FutureOr<Response> Function(Request request);

/// Route matcher for HTTP method and path.
class RouteHandler {
  final String method;
  final Pattern path;
  final MockHandler handler;

  RouteHandler({required this.method, required this.path, required this.handler});

  bool matches(Request request) {
    return request.method.toUpperCase() == method.toUpperCase() &&
        path.matchAsPrefix(request.url.path) != null;
  }
}

class MockWebServer {
  final List<RouteHandler> _handlers;
  HttpServer? _server;
  int? _port;

  MockWebServer([List<RouteHandler> handlers = const []]) : _handlers = List.from(handlers);

  /// Add a new route handler.
  void use(RouteHandler handler) => _handlers.add(handler);

  /// Start the server.
  Future<void> listen({int port = 0}) async {
    final handler = (Request request) async {
      for (final rh in _handlers) {
        if (rh.matches(request)) {
          return await rh.handler(request);
        }
      }
      return Response.notFound('No handler found for \\${request.method} \\${request.url.path}');
    };
    _server = await shelf_io.serve(handler, 'localhost', port);
    _port = _server!.port;
  }

  /// Stop the server.
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
  }

  /// Get the port the server is listening on.
  int? get port => _port;
}

/// Factory function to setup a mock server, similar to mswjs's setupServer.
MockWebServer setupServer([List<RouteHandler> handlers = const []]) => MockWebServer(handlers);

/// Helper to create a route handler for a method and path.
RouteHandler on(String method, Pattern path, MockHandler handler) => RouteHandler(method: method, path: path, handler: handler);
