import 'dart:async';

import 'package:mockwebserver/src/handlers/request_handler.dart';
import 'package:mockwebserver/src/utils/cookie.dart';
import 'package:shelf/shelf.dart';

enum HttpMethod { get, post, put, delete, patch, head, options }

sealed class _HttpMethodType {
  bool matches(String method);

  String get value;
}

class _ExactHttpMethod extends _HttpMethodType {
  final HttpMethod method;

  _ExactHttpMethod(this.method);

  @override
  bool matches(String method) =>
      this.method.name.toUpperCase() == method.toUpperCase();

  @override
  String get value => method.name;
}

class _RegExpHttpMethod extends _HttpMethodType {
  final RegExp method;

  _RegExpHttpMethod(this.method);

  @override
  bool matches(String method) => this.method.hasMatch(method);

  @override
  String get value => method.pattern;
}

class HttpHandlerOptions {
  final bool once;

  const HttpHandlerOptions({this.once = false});
}

class HttpRequestExtra {
  /// parsed request path parameters
  final Map<String, String> params;

  /// parsed request cookies
  final Map<String, String> cookies;

  HttpRequestExtra({required this.params, required this.cookies});
}

typedef ResponseResolver =
    FutureOr<Response> Function(Request request, HttpRequestExtra extra);

const _defaultOptions = HttpHandlerOptions(once: false);

class HttpHandler implements RequestHandler {
  final _HttpMethodType _method;
  final String _path;
  final ResponseResolver _resolver;
  final HttpHandlerOptions _options;

  final List<String> _pathSegments;
  int _usedCount = 0;

  HttpHandler._({
    required _HttpMethodType method,
    required String path,
    required ResponseResolver resolver,
    HttpHandlerOptions options = _defaultOptions,
  }) : _method = method,
       _path = path,
       _resolver = resolver,
       _options = options,
       _pathSegments = _normalizePath(path).split('/');

  /// Normalizes a path by removing leading/trailing slashes and empty segments
  static String _normalizePath(String path) {
    return path.split('/').where((segment) => segment.isNotEmpty).join('/');
  }

  /// factory to create a handler for GET requests.
  factory HttpHandler.get(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.get),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for POST requests.
  factory HttpHandler.post(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.post),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for PUT requests.
  factory HttpHandler.put(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.put),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for DELETE requests.
  factory HttpHandler.delete(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.delete),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for PATCH requests.
  factory HttpHandler.patch(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.patch),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for HEAD requests.
  factory HttpHandler.head(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.head),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for OPTIONS requests.
  factory HttpHandler.options(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _ExactHttpMethod(HttpMethod.options),
      path: path,
      resolver: resolver,
    );
  }

  /// factory to create a handler for any request.
  factory HttpHandler.any(String path, ResponseResolver resolver) {
    return HttpHandler._(
      method: _RegExpHttpMethod(
        RegExp(r'^(GET|POST|PUT|DELETE|PATCH|HEAD|OPTIONS)$'),
      ),
      path: path,
      resolver: resolver,
    );
  }

  /// check if the request should be handled by this handler
  @override
  bool test(Request request) {
    if (_options.once && _usedCount > 0) {
      return false;
    }

    if (!_method.matches(request.method)) {
      return false;
    }

    final requestPath = _normalizePath(request.url.path);
    final requestSegments = requestPath.split('/');

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

  Map<String, String> _getPathParameters(Request request) {
    final requestPath = _normalizePath(request.url.path);
    final requestSegments = requestPath.split('/');
    final params = <String, String>{};

    for (var i = 0; i < _pathSegments.length; i++) {
      final segment = _pathSegments[i];
      if (segment.startsWith(':')) {
        final paramName = segment.substring(1);
        params[paramName] = requestSegments[i];
      }
    }

    return params;
  }

  HttpRequestExtra _getExtra(Request request) {
    final params = _getPathParameters(request);

    final rawCookies = request.headers['cookie'];
    final cookies = parseCookieString(rawCookies ?? '');

    return HttpRequestExtra(params: params, cookies: cookies);
  }

  @override
  Future<Response> handle(Request request) async {
    _usedCount++;
    return await _resolver(request, _getExtra(request));
  }

  @override
  Future<void> log(Request request, Response response) async {
    print('${request.method} ${request.url.path} ${response.statusCode}');
  }
}
