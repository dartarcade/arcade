## 1.0.2

- Updated dependencies

## 1.0.0

- **FEAT**: Add staticFilesDirectory parameter to ArcadeTestServer for testing static file serving
- **FIX**: Fix WebSocket test hanging by properly setting up message listeners before sending

## 0.5.0

- **CHORE**: Update version to 0.5.0 to align with core arcade package.

## 0.1.0

### Initial Release

- **FEAT**: Complete HTTP status code matcher coverage for all Arcade exception types
  - `isBadRequest()`, `isUnauthorized()`, `isForbidden()`, `isMethodNotAllowed()`
  - `isConflict()`, `isImATeapot()`, `isUnprocessableEntity()`, `isInternalServerError()`
  - `isServiceUnavailable()`, `isCreated()`, and more
- **FEAT**: `ArcadeTestServer` for test server lifecycle management with automatic port allocation
- **FEAT**: `ArcadeTestClient` for HTTP client testing with all methods (GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS)
- **FEAT**: Comprehensive response validation with `TestResponse` class
- **FEAT**: JSON and text response matchers with path-based assertions
- **FEAT**: Header and content-type validation utilities
- **FEAT**: WebSocket testing support with `TestWebSocket`
- **FEAT**: State management utilities (`ArcadeTestState`) for test isolation and cleanup
- **FEAT**: Complete integration with standard Dart test package
- **FEAT**: Support for custom status codes via `context.statusCode`
- **FEAT**: Robust error handling and edge case coverage
- **FEAT**: Production-ready testing framework with 116 comprehensive tests
