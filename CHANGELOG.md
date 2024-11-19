# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2024-11-19

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.2.2`](#arcade---v022)
 - [`arcade_config` - `v0.1.1`](#arcade_config---v011)
 - [`todo_api` - `v2.1.0`](#todo_api---v210)
 - [`arcade_views` - `v0.1.0+1`](#arcade_views---v0101)
 - [`arcade_logger` - `v0.0.5+2`](#arcade_logger---v0052)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `arcade_views` - `v0.1.0+1`
 - `arcade_logger` - `v0.0.5+2`

---

#### `arcade` - `v0.2.2`

 - **FEAT**: add support for custom headers in static file responses ([#39](https://github.com/dartarcade/arcade/issues/39)).

#### `arcade_config` - `v0.1.1`

 - **FEAT**: add support for custom headers in static file responses ([#39](https://github.com/dartarcade/arcade/issues/39)).

#### `todo_api` - `v2.1.0`

 - **FEAT**: add support for custom headers in static file responses ([#39](https://github.com/dartarcade/arcade/issues/39)).


## 2024-11-16

### Changes

---

Packages with breaking changes:

 - [`arcade_config` - `v0.1.0`](#arcade_config---v010)
 - [`arcade_views` - `v0.1.0`](#arcade_views---v010)
 - [`todo_api` - `v2.0.0`](#todo_api---v200)

Packages with other changes:

 - [`arcade` - `v0.2.1+2`](#arcade---v0212)
 - [`arcade_logger` - `v0.0.5+1`](#arcade_logger---v0051)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `arcade` - `v0.2.1+2`
 - `arcade_logger` - `v0.0.5+1`

---

#### `arcade_config` - `v0.1.0`

 - **BREAKING** **FEAT**: Move views to jinja templates ([#38](https://github.com/dartarcade/arcade/issues/38)).

#### `arcade_views` - `v0.1.0`

 - **BREAKING** **FEAT**: Move views to jinja templates ([#38](https://github.com/dartarcade/arcade/issues/38)).

#### `todo_api` - `v2.0.0`

 - **BREAKING** **FEAT**: Move views to jinja templates ([#38](https://github.com/dartarcade/arcade/issues/38)).


## 2024-10-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.2.1`](#arcade---v021)

---

#### `arcade` - `v0.2.1`

 - **FEAT**: Add emitToAll function for websockets.


## 2024-10-18

### Changes

---

Packages with breaking changes:

 - [`arcade` - `v0.2.0`](#arcade---v020)

---

#### `arcade` - `v0.2.0`

 - **BREAKING** **FEAT**: Move Route to route, add types to route.group ([#36](https://github.com/dartarcade/arcade/issues/36)).


## 2024-07-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.4+2`](#arcade---v0142)

---

#### `arcade` - `v0.1.4+2`

 - **FIX**: Duplicate global hooks.


## 2024-07-29

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.4+1`](#arcade---v0141)

---

#### `arcade` - `v0.1.4+1`

 - **FIX**: Run global hooks.


## 2024-06-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.4`](#arcade---v014)

---

#### `arcade` - `v0.1.4`

 - **FEAT**(arcade): add support for setting status code.


## 2024-06-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.3`](#arcade---v013)
 - [`arcade_cli` - `v0.0.4`](#arcade_cli---v004)
 - [`arcade_config` - `v0.0.5`](#arcade_config---v005)
 - [`arcade_logger` - `v0.0.5`](#arcade_logger---v005)
 - [`arcade_views` - `v0.0.7`](#arcade_views---v007)

---

#### `arcade` - `v0.1.3`

 - **FEAT**: update dependencies.

#### `arcade_cli` - `v0.0.4`

 - **FEAT**: update dependencies.

#### `arcade_config` - `v0.0.5`

 - **FEAT**: update dependencies.

#### `arcade_logger` - `v0.0.5`

 - **FEAT**: update dependencies.

#### `arcade_views` - `v0.0.7`

 - **FEAT**: update dependencies.


## 2023-12-24

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.2`](#arcade---v012)
 - [`arcade_cache` - `v0.0.2`](#arcade_cache---v002)
 - [`arcade_cache_redis` - `v0.0.2`](#arcade_cache_redis---v002)
 - [`arcade_config` - `v0.0.4`](#arcade_config---v004)
 - [`arcade_logger` - `v0.0.4`](#arcade_logger---v004)
 - [`arcade_views` - `v0.0.6+2`](#arcade_views---v0062)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `arcade_views` - `v0.0.6+2`

---

#### `arcade` - `v0.1.2`

 - **FIX**: name clash.
 - **FEAT**: add support for global before, after and afterWebSocket hooks.
 - **FEAT**: optimize route matching and static file checking.
 - **FEAT**: group routes support.
 - **FEAT**: match wildcard routes on any sub path segment.

#### `arcade_cache` - `v0.0.2`

 - **REFACTOR**: fix samples and examples.
 - **FEAT**: redis implementation.
 - **FEAT**: make ready for publishing.
 - **FEAT**: export BaseCacheManager.
 - **FEAT**: rename to arcade.

#### `arcade_cache_redis` - `v0.0.2`

 - **FEAT**: redis implementation.

#### `arcade_config` - `v0.0.4`

 - **FEAT**: match wildcard routes on any sub path segment.

#### `arcade_logger` - `v0.0.4`

 - **FEAT**: match wildcard routes on any sub path segment.
 - **FEAT**: update logger.


## 2023-11-12

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.1+1`](#arcade---v0111)
 - [`arcade_cli` - `v0.0.3+1`](#arcade_cli---v0031)
 - [`arcade_config` - `v0.0.3+1`](#arcade_config---v0031)
 - [`arcade_logger` - `v0.0.3+1`](#arcade_logger---v0031)
 - [`arcade_views` - `v0.0.6+1`](#arcade_views---v0061)

---

#### `arcade` - `v0.1.1+1`

 - **REFACTOR**: fix samples and examples.
 - **FIX**(server_helper): process signal empty stream for platform windows.

#### `arcade_cli` - `v0.0.3+1`

 - **REFACTOR**: fix samples and examples.

#### `arcade_config` - `v0.0.3+1`

 - **REFACTOR**: fix samples and examples.

#### `arcade_logger` - `v0.0.3+1`

 - **REFACTOR**: fix samples and examples.

#### `arcade_views` - `v0.0.6+1`

 - **REFACTOR**: fix samples and examples.


## 2023-09-26

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`arcade` - `v0.1.1`](#arcade---v011)
 - [`arcade_cli` - `v0.0.3`](#arcade_cli---v003)
 - [`arcade_config` - `v0.0.3`](#arcade_config---v003)
 - [`arcade_logger` - `v0.0.3`](#arcade_logger---v003)
 - [`arcade_views` - `v0.0.6`](#arcade_views---v006)

---

#### `arcade` - `v0.1.1`

 - **FEAT**: rename to arcade.

#### `arcade_cli` - `v0.0.3`

 - **FIX**(arcade_cli): command printed prints arcade.
 - **FEAT**: rename to arcade.

#### `arcade_config` - `v0.0.3`

 - **FEAT**: rename to arcade.

#### `arcade_logger` - `v0.0.3`

 - **FEAT**: rename to arcade.

#### `arcade_views` - `v0.0.6`

 - **FEAT**: rename to arcade.


## 2023-08-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.1.0+1`](#dartseid---v0101)
 - [`dartseid_cli` - `v0.0.2+2`](#dartseid_cli---v0022)

---

#### `dartseid` - `v0.1.0+1`

 - **FIX**: dartseid_cli will hot restart the app instead of hot reload for more reliability.

#### `dartseid_cli` - `v0.0.2+2`

 - **FIX**: dartseid_cli will hot restart the app instead of hot reload for more reliability.


## 2023-08-16

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid_cli` - `v0.0.2+1`](#dartseid_cli---v0021)

---

#### `dartseid_cli` - `v0.0.2+1`

 - **FIX**(dartseid_cli): fix create command does not rename imports.


## 2023-08-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.1.0`](#dartseid---v010)

---

#### `dartseid` - `v0.1.0`

- **FEAT**(dartseid): add support for web sockets

## 2023-07-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid_cli` - `v0.0.2`](#dartseid_cli---v002)

---

#### `dartseid_cli` - `v0.0.2`

 - **FIX**(dartseid_cli): pipe stderr.
 - **FEAT**(dartseid_cli): add create command.
 - **FEAT**(cli): add serve command.
## 2023-07-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid_cli` - `v0.0.2`](#dartseid_cli---v002)

---

#### `dartseid_cli` - `v0.0.2`

 - **FIX**(dartseid_cli): pipe stderr.
 - **FEAT**(dartseid_cli): add create command.
 - **FEAT**(cli): add serve command.


## 2023-07-23

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid_cli` - `v0.0.1+1`](#dartseid_cli---v0011)

---

#### `dartseid_cli` - `v0.0.1+1`

 - **FIX**(dartseid_cli): pipe stderr.
 - **FIX**(cli): pipe stderr.


## 2023-07-17

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid_views` - `v0.0.5`](#dartseid_views---v005)

---

#### `dartseid_views` - `v0.0.5`

 - **FEAT**(views): add support for absolute partials.


## 2023-07-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.0.9+2`](#dartseid---v0092)
 - [`dartseid_logger` - `v0.0.2`](#dartseid_logger---v002)

---

#### `dartseid` - `v0.0.9+2`

 - **FIX**(core): updated to logger dependencies. Need to solve cyclic deps.
 - **FIX**(all): Licenses copyright.

#### `dartseid_logger` - `v0.0.2`

 - **FIX**(all): Licenses copyright.
 - **FEAT**(logger): copy logger code to new package.
 - **FEAT**(logger): Initial commit.


## 2023-07-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.0.9+1`](#dartseid---v0091)

---

#### `dartseid` - `v0.0.9+1`

 - **FIX**(dartseid): update imports for config dependency.


## 2023-07-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.0.9`](#dartseid---v009)
 - [`dartseid_config` - `v0.0.2`](#dartseid_config---v002)
 - [`dartseid_views` - `v0.0.4`](#dartseid_views---v004)

---

#### `dartseid` - `v0.0.9`

 - **FEAT**(config): new configuration package.

#### `dartseid_config` - `v0.0.2`

 - **FIX**(config): description, update(melos): bootstrap with new package.
 - **FIX**(config): rename package.
 - **FEAT**(config): new configuration package.

#### `dartseid_views` - `v0.0.4`

 - **FEAT**(config): new configuration package.


## 2023-07-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`dartseid` - `v0.0.8`](#dartseid---v008)
 - [`dartseid_views` - `v0.0.3+1`](#dartseid_views---v0031)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `dartseid_views` - `v0.0.3+1`

---

#### `dartseid` - `v0.0.8`

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

