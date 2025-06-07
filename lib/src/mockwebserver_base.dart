import 'dart:async';
import 'dart:io';
import 'package:mockwebserver/src/handlers/request_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class MockWebServer {
  final List<RequestHandler> _initialHandlers;
  List<RequestHandler> _handlers;
  HttpServer? _server;
  int? _port;

  MockWebServer._([List<RequestHandler> handlers = const []])
    : _initialHandlers = List.from(handlers),
      _handlers = List.from(handlers);

  /// Factory function to setup a mock server, similar to mswjs's setupServer.
  factory MockWebServer.setup(List<RequestHandler> handlers) =>
      MockWebServer._(handlers);

  /// Add route handlers.
  void use(List<RequestHandler> handlers) {
    _handlers.addAll(handlers);
  }

  /// Reset all handlers to initial state or to the provided handlers
  void resetHandlers([List<RequestHandler>? nextHandlers]) {
    _handlers = List.from(nextHandlers ?? _initialHandlers);
  }

  Future<HttpServer> _parepareServer(int port) async {
    final handler = Pipeline().addMiddleware(logRequests()).addHandler((
      Request request,
    ) async {
      for (final rh in _handlers) {
        if (rh.test(request)) {
          return await rh.handle(request);
        }
      }
      return Response.notFound(
        'No handler found for ${request.method} /${request.url.path}',
      );
    });

    return await shelf_io.serve(handler, 'localhost', port);
  }

  /// Start the server.
  Future<void> listen({int port = 0}) async {
    _server = await _parepareServer(port);
    _port = _server!.port;
  }

  /// Stop the server.
  Future<void> close() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
  }

  /// Get the port the server is listening on.
  /// Returns null if the server is not listening.
  int? get port => _port;

  /// Get the URL the server is listening on.
  /// Returns null if the server is not listening.
  String? get url => _port == null ? null : 'http://localhost:$_port';
}
