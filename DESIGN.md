# DESIGN.md

## Overview

This document describes the design of the `MockWebServer` Dart library, which provides a mock HTTP server API inspired by [mswjs](https://mswjs.io/)'s `setupServer`. The goal is to enable easy mocking of HTTP endpoints for testing and development, with a flexible and extensible handler system.

## Core Concepts

### 1. RouteHandler
- **Purpose:** Represents a single HTTP route handler, matching requests by HTTP method and path.
- **Constructor:** Uses named parameters for clarity and extensibility: `RouteHandler({required method, required path, required handler})`.
- **Fields:**
  - `method`: HTTP method (e.g., 'GET', 'POST').
  - `path`: A `Pattern` (usually a `String` or `RegExp`) to match the request path.
  - `handler`: A function that takes a `Request` and returns a `Response` (sync or async).
- **Matching:** The `matches` method checks if a request's method and path match the handler's criteria.

### 2. MockWebServer
- **Purpose:** Manages a collection of `RouteHandler`s and runs an HTTP server using the `shelf` package.
- **Construction:** Created via the `setupServer` factory, which takes a list of `RouteHandler`s.
- **API:**
  - `listen({int port = 0})`: Starts the server on the given port (or a random port if 0).
  - `close()`: Stops the server.
  - `use(List<RouteHandler> handlers)`: Adds new handlers to the current set.
  - `resetHandlers([List<RouteHandler>? nextHandlers])`: 
    - Without arguments: Resets to the original initial handlers
    - With arguments: Sets new handlers (temporarily) without modifying initial state
  - `port`: Returns the port the server is listening on.
- **Request Handling:**
  - For each incoming request, iterates through handlers and invokes the first match.
  - Returns 404 if no handler matches.
- **Handler Management:**
  - Initial handlers set during server creation remain immutable
  - Current handlers can be modified through `use()` and `resetHandlers()`
  - Always possible to reset to the original initial state

### 3. Handler Registration
- **Helper Function:** `on(method, path, handler)` creates a `RouteHandler` with named parameters for clarity.
- **Extensibility:** New types of handlers (e.g., for websockets, advanced matching) can be added by extending `RouteHandler` or adding new helper functions.

## Extensibility & Future Features
- **Request Inspection:** Can add request logging or history for assertions in tests.
- **Dynamic Handler Management:** Support for removing or reordering handlers at runtime.
- **Advanced Path Matching:** Support for path parameters, wildcards, or more complex matching logic.
- **Response Templates:** Helpers for common response types (JSON, redirects, etc).
- **Middleware Support:** Allow pre-processing or post-processing of requests/responses.

## Design Principles
- **Simplicity:** API is minimal and inspired by mswjs, making it easy to use for most test scenarios.
- **Extensibility:** Named parameters and clear separation of concerns make it easy to add new features.
- **Testability:** Designed for use in automated tests, with predictable and inspectable behavior.
- **Immutable Initial State:** Initial handlers remain unchanged, ensuring tests can always reset to a known state.

## Example Usage

```dart
void main() {
  late MockWebServer server;

  setUp(() async {
    // Initialize with initial handlers
    server = setupServer([
      on('GET', 'hello', (req) async => Response.ok('Hello, test!')),
      on('POST', 'echo', (req) async => Response.ok('Echo!')),
    ]);
    await server.listen();
  });

  tearDown(() async {
    await server.close();
  });

  test('can modify handlers during test', () async {
    // Add temporary handlers
    server.use([
      on('GET', 'temp', (req) async => Response.ok('Temp!')),
    ]);

    // Reset to new handlers
    server.resetHandlers([
      on('GET', 'new', (req) async => Response.ok('New!')),
    ]);

    // Reset to initial state
    server.resetHandlers();
  });
}
```

---

This document should be updated as new features are added or design decisions are made.
