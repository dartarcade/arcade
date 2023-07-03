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
- [x] Add support for hooks
- [x] Add support for `multipart/form-data` (File upload, etc.)
- [x] Add support for `application/x-www-form-urlencoded`
- [x] Add a logger
- [x] Static file serving
- [x] Add support for views
- Global configuration
    - [x] Configure static file serving directory
- [ ] CORS support

### Essential but not urgent

- Add documentation
    - [x] Get started guide
        - Needs to be consistently updated
- [x] Add the raw request to context
- [ ] Add support for cookies (cleaner API)
- [ ] Add support for HTTPS
- [ ] Add support for web sockets

### Nice to haves

- [ ] Use multi-threading to improve performance
- [ ] Add default headers. e.g. `Cache-Control`, `X-Powered-By`, etc. `Cache-Control` should be configurable, and
  default to `no-cache` for API routes (JSON)
- [ ] CLI for Dartseid
    - Commands
        - [ ] `dev` command
            Addtional notes:
            - Maybe rename to `serve` and make it generic for prod and dev.
                Maybe a `--reload` flag to enable hot reloading during dev.
            - Currently, got reloading only works for function code changes like
                functions and method source changes. It does not register new
                routes (basicaly it doesn't run anything that has already been
                run which makes sense). Explore having hot reload be remove in 
                favor of hot restarts instead. This may cause slow startups
                though so maybe giving the user an option to enable hot restarts
                or hot reloads and explaining the caveats between both in the
                docs.
        - [ ] `build` command  
            Additional notes:
            - Test the performance of JIT (dart run) vs AOT (dart compile exe).
                JIT may be faster after warmup due to optimizations.
    - `generate` command
        - [ ] Generate a project with a template picker.
        - [ ] Generate controllers, services, etc. if the user picked the
          MVC-esk template
- [ ] Add support for GraphQL
- [ ] Use `cli_util` to show progress in the CLI when reloading
