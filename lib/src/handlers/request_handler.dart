import 'package:shelf/shelf.dart';

/// An abstraction that should help us implement more handler types in the future.
abstract interface class RequestHandler {
  /// Count of how many times the handler has been used.
  int get usedCount;

  /// Check if the handler can handle the [request].
  bool test(Request request);

  /// Handle the [request] and return a response.
  Future<Response> handle(Request request);

  /// Reset the handler to its initial state.
  void reset();

  /// Log the [request] and [response] for debugging purposes.
  Future<void> log(Request request, Response response);
}
