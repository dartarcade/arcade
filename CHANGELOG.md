# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

