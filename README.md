# Dartseid

See the [documentation](https://dartseid.ex3.dev) for more information.

## TODO

### Foundation tasks

- [ ] dev and prod env (a way to disable the hotreloader)

### Essentials

- [x] Parse path parameters
- [x] Make `RequestContext.json` return a sealed class to wrap possible errors
- [x] Add support for hot reload
- [x] Handle all errors defaulting to 500
- [x] Add support for middlewares
- [ ] Add support for cookies (cleaner API)
- [ ] Add support for `application/x-www-form-urlencoded`
- [ ] Add support for `multipart/form-data` (File upload, etc.)
- [ ] Add a logger
- [ ] Add support for views. e.g. HTML views for websites
- [ ] Static file serving

### Essential but not urgent

- [ ] Add documentation
- [x] Add the raw request to context
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
