## 0.1.4+2

 - **FIX**: Duplicate global hooks.

## 0.1.4+1

 - **FIX**: Run global hooks.

## 0.1.4

 - **FEAT**(arcade): add support for setting status code.

## 0.1.3

 - **FEAT**: update dependencies.

## 0.1.2

 - **FIX**: name clash.
 - **FEAT**: add support for global before, after and afterWebSocket hooks.
 - **FEAT**: optimize route matching and static file checking.
 - **FEAT**: group routes support.
 - **FEAT**: match wildcard routes on any sub path segment.

## 0.1.1+1

 - **REFACTOR**: fix samples and examples.
 - **FIX**(server_helper): process signal empty stream for platform windows.

## 0.1.1

 - **FEAT**: rename to arcade.

## 0.1.0+1

 - **FIX**: dartseid_cli will hot restart the app instead of hot reload for more reliability.

## 0.1.0

- **FEAT**(dartseid): add support for web sockets

## 0.0.10

- **FEAT**(core): added `Route.any` and `*`

## 0.0.9+2

 - **FIX**(core): updated to logger dependencies. Need to solve cyclic deps.
 - **FIX**(all): Licenses copyright.

## 0.0.9+1

 - **FIX**(dartseid): update imports for config dependency.

## 0.0.9

 - **FEAT**(config): new configuration package.

## 0.0.8

 - **FIX**: hot reloading now initializes the application.
 - **FIX**: not found route not closed.
 - **FIX**: normalized routes when matching, decode path params during construction of context.pathParameters.
 - **FEAT**: detect prod (compiled) or dev (JIT) environment.
 - **FEAT**: add before and after hooks, and remove middleware. Before hooks are a replacement for middlewares, separate request and response headers in RequestContext.
 - **FEAT**: add records and levels to logging.
 - **FEAT**: add a rudimentary logger that uses a separate isolate to log.
 - **FEAT**: add file upload support.
 - **FEAT**: add todo API sample.
 - **FEAT**: add support for custom exceptions.

## 0.0.7

- Allow for compiling by disabling hot reloading when compiling for production using `dart compile exe`.

## 0.0.6

- Introduce a new routing API based on hooks. This allows for more flexibility in defining routes.
- Multiple bug fixes

## 0.0.5

- Add configuration for `dartseid_views` in `DartseidConfiguration` class

## 0.0.4

- Add a logger
- Improve hot reloading. Now after reloading, the `init()` function is called again so that the application is
  reinitialized. This allows routes to be redefined.

## 0.0.3

- Add file upload support
- Add support for `multipart/form-data` requests
- Add support for `application/x-www-form-urlencoded` requests
- Add a sample todo API

## 0.0.2

- Added `rawRequest` to `RequestContext` to allow access to the raw request object for advanced use cases.
- Fixed a bug with not found route not closing the response.

## 0.0.1

- Initial version.
