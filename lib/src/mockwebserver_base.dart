import 'dart:async';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Type for a request handler, similar to MSWJS's request handler.
typedef MockHandler = FutureOr<Response> Function(RequestContext context);

/// Context object that wraps the original request and provides access to path parameters
class RequestContext {
  final Request request;
  final Map<String, String> params;

  RequestContext(this.request, this.params);

  /// Get a path parameter value
  String? param(String name) => params[name];
}

/// Route matcher for HTTP method and path.
class RouteHandler {
  final String method;
  final String path;
  final MockHandler handler;
  final List<String> _pathSegments;

  RouteHandler({
    required this.method,
    required this.path,
    required this.handler,
  }) : _pathSegments = path.split('/');

  bool matches(Request request) {
    if (request.method.toUpperCase() != method.toUpperCase()) {
      return false;
    }

    final requestSegments = request.url.path.split('/');
    if (requestSegments.length != _pathSegments.length) {
      return false;
    }

    for (var i = 0; i < _pathSegments.length; i++) {
      final segment = _pathSegments[i];
      final requestSegment = requestSegments[i];

      if (!segment.startsWith(':') && segment != requestSegment) {
        return false;
      }
    }

    return true;
  }

  Future<Response> handle(Request request) async {
    final requestSegments = request.url.path.split('/');
    final params = <String, String>{};

    for (var i = 0; i < _pathSegments.length; i++) {
      final segment = _pathSegments[i];
      if (segment.startsWith(':')) {
        final paramName = segment.substring(1);
        params[paramName] = requestSegments[i];
      }
    }

    return await handler(RequestContext(request, params));
  }
}

class MockWebServer {
  final List<RouteHandler> _initialHandlers;
  List<RouteHandler> _handlers;
  HttpServer? _server;
  int? _port;

  MockWebServer([List<RouteHandler> handlers = const []])
    : _initialHandlers = List.from(handlers),
      _handlers = List.from(handlers);

  /// Add route handlers.
  void use(List<RouteHandler> handlers) {
    _handlers.addAll(handlers);
  }

  /// Reset all handlers to initial state or to the provided handlers
  void resetHandlers([List<RouteHandler>? nextHandlers]) {
    _handlers = List.from(nextHandlers ?? _initialHandlers);
  }

  /// Start the server.
  Future<void> listen({int port = 0}) async {
    _server = await shelf_io.serve(
      (Request request) async {
        for (final rh in _handlers) {
          if (rh.matches(request)) {
            return await rh.handle(request);
          }
        }
        return Response.notFound(
          'No handler found for \\${request.method} \\${request.url.path}',
        );
      },
      'localhost',
      port,
    );
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
MockWebServer setupServer([List<RouteHandler> handlers = const []]) =>
    MockWebServer(handlers);

/// Helper to create a route handler for a method and path.
RouteHandler on(String method, String path, MockHandler handler) =>
    RouteHandler(method: method, path: path, handler: handler);
