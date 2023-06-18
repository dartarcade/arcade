# Dartseid

## TODO

- [x] Parse path parameters
- [x] Make `RequestContext.json` return a sealed class to wrap possible errors
- [x] Add support for hot reload
- [x] Handle all errors defaulting to 500
- [ ] Add support for middlewares
- [ ] Add support for HTML views
- [ ] Add better headers support
    - [ ] Add default headers. e.g. `Cache-Control`, `X-Powered-By`, etc. Cache-Control should be configurable, and
      default to `no-cache` for API routes (JSON)
- [ ] Add support for cookies
