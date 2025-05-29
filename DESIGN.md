# DESIGN.md

## Overview

This document describes the design of the `MockWebServer` Dart library, which provides a mock HTTP server API inspired by [mswjs](https://mswjs.io/)'s `setupServer`. The goal is to enable easy mocking of HTTP endpoints for testing and development, with a flexible and extensible handler system.

## Core Concepts

### 1. RouteHandler
- **Purpose:** Represents a single HTTP route handler, matching requests by HTTP method and path.
- **Constructor:** Uses named parameters for clarity and extensibility: `RouteHandler({required method, required path, required handler})`.
- **Fields:**
  - `method`: HTTP method (e.g., 'GET', 'POST').
  - `path`: A `String` pattern to match the request path, supporting `:paramName` syntax for path parameters.
  - `handler`: A function that takes a `RequestContext` and returns a `Response` (sync or async).
  - `_pathSegments`: Internal field storing the path split into segments for matching.
- **Matching:** The `matches` method checks if a request's method and path match the handler's criteria:
  1. Case-insensitive method matching
  2. Path segment count matching
  3. Segment-by-segment comparison
  4. Parameter extraction for segments starting with `:`

### 2. RequestContext
- **Purpose:** Wraps the original request and provides access to path parameters.
- **Fields:**
  - `request`: The original shelf `Request` object.
  - `params`: Map of path parameter names to their values.
- **Methods:**
  - `param(String name)`: Returns the value of a path parameter.

### 3. MockWebServer
- **Purpose:** Manages a collection of `RouteHandler`s and runs an HTTP server using the `shelf` package.
- **Construction:** Created via the `setupServer` factory, which takes a list of `RouteHandler`s.
- **Fields:**
  - `_initialHandlers`: Immutable list of handlers set during server creation.
  - `_handlers`: Current list of active handlers.
  - `_server`: The underlying HTTP server instance.
  - `_port`: The port the server is listening on.
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

### 4. Handler Registration
- **Helper Function:** `on(method, path, handler)` creates a `RouteHandler` with named parameters for clarity.
- **Extensibility:** New types of handlers (e.g., for websockets, advanced matching) can be added by extending `RouteHandler` or adding new helper functions.

## Implementation Details

### Path Parameter Handling
- Parameters are extracted during request matching
- Parameter names are derived from path segments starting with `:`
- Values are stored in the `RequestContext` for handler access
- Example: `/users/:id/posts/:postId` extracts `id` and `postId` parameters

### Handler State Management
- Initial handlers are stored separately from current handlers
- `use()` appends new handlers to the current set
- `resetHandlers()` restores initial state or sets new handlers
- State changes are immediate and affect subsequent requests

### Response Handling
- Uses shelf's `Response` class for all responses
- Supports standard HTTP methods and status codes
- Handles JSON responses with proper content-type headers
- Supports custom headers and response bodies

## Design Principles

- **Simplicity:** API is minimal and inspired by mswjs, making it easy to use for most test scenarios.
- **Extensibility:** Named parameters and clear separation of concerns make it easy to add new features.
- **Testability:** Designed for use in automated tests, with predictable and inspectable behavior.
- **Immutable Initial State:** Initial handlers remain unchanged, ensuring tests can always reset to a known state.

## Maintenance Guidelines

### Adding New Features
1. Update tests first to define expected behavior
2. Implement feature in the appropriate component
3. Update documentation and examples
4. Add new test cases for edge cases

### Code Organization
- Keep handler matching logic in `RouteHandler`
- Maintain parameter extraction in request handling
- Separate concerns between routing and response generation
- Use clear naming conventions for internal fields

### Testing Strategy
- Unit tests for each component
- Integration tests for handler management
- Edge case testing for path parameters
- State management verification

### Common Patterns
- Handler definition: `on(method, path, handler)`
- Path parameters: `:paramName` in path
- Response creation: `Response.ok(body)`
- JSON responses: `jsonEncode(data)` with content-type header

## Example Usage

```dart
void main() {
  late MockWebServer server;

  setUp(() async {
    // Initialize with initial handlers
    server = setupServer([
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
    await server.listen();
  });

  tearDown(() async {
    await server.close();
  });

  test('can modify handlers during test', () async {
    // Add temporary handlers
    server.use([
      on('GET', 'new', (context) async => Response.ok('New handler!')),
    ]);

    // Reset to new handlers
    server.resetHandlers([
      on('GET', 'custom', (context) async => Response.ok('Custom handler!')),
    ]);

    // Reset to initial state
    server.resetHandlers();
  });
}
```

## Future Considerations
- Support for query parameters
- Wildcard path matching
- Request body parsing helpers
- Response delay simulation
- Request/response logging
- Middleware support
- Handler composition
- Request validation
- Response templating
- Error handling middleware

---

This document should be updated as new features are added or design decisions are made.
