import 'package:shelf/shelf.dart';

/// An abstraction that should help us implement more handler types in the future.
abstract interface class RequestHandler {
  int get usedCount;
  bool test(Request request);
  Future<Response> handle(Request request);
  void reset();
  Future<void> log(Request request, Response response);
}
