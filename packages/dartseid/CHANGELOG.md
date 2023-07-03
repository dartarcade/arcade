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
