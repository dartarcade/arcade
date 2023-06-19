# Dartseid

## TODO

### Essentials

- [x] Parse path parameters
- [x] Make `RequestContext.json` return a sealed class to wrap possible errors
- [x] Add support for hot reload
- [x] Handle all errors defaulting to 500
- [x] Add support for middlewares
- [ ] Add support for cookies
- [ ] Add support for `multipart/form-data`
- [ ] Add support for `application/x-www-form-urlencoded`
- [ ] Add a logger
- [ ] Add support for views. e.g. HTML views for websites

### Essential but not urgent

- [ ] Add documentation
- [ ] Add support for HTTPS
- [ ] Add support for web sockets

### Nice to haves

- [ ] Use multi-threading to improve performance
- [ ] Use `cli_util` to show progress in the CLI when reloading
- [ ] Add default headers. e.g. `Cache-Control`, `X-Powered-By`, etc. Cache-Control should be configurable, and
  default to `no-cache` for API routes (JSON)
- [ ] CLI for Dartseid
  - [ ] Add an MVC-esk template generation
- [ ] Add support for GraphQL
