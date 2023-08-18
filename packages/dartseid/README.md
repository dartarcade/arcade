# Dartseid

Read the [documentation](https://dartseid.ex3.dev) for detailed guides.

Dartseid is a no-code-gen, simple Dart backend framework.

## Features

- No code generation
- No reflection
- No annotations
- No boilerplate
- No magic

## Getting Started

### 1. Install the CLI

The Dartseid CLI is used to create new projects and run the development server.
The development server automatically reloads when you make changes to your code.

```sh
dart pub global activate dartseid_cli
```

### 2. Create a new project

```sh
dartseid create my_project
cd my_project
```

The following files will be created:

```
my_project
├── CHANGELOG.md
├── README.md
├── analysis_options.yaml
├── bin
│   └── my_project.dart
├── lib
│   ├── core
│   │   ├── env.dart
│   │   ├── env.g.dart
│   │   ├── init.config.dart
│   │   └── init.dart
│   └── modules
│       └── home
│           ├── controllers
│           │   └── home_controller.dart
│           └── services
│               └── home_service.dart
├── pubspec.lock
└── pubspec.yaml
```

The recommended project does use code generation for the environment variables 
via `envied`, and dependency injection via `injectable`. If you truly want a
no-code-gen project, you can start from scratch, and create a new Dart console app:

```sh
dart create my_project
cd my_project
```

Then add the `dartseid` package to your `pubspec.yaml`:

```sh
dart pub add dartseid
```

Then modify your `main.dart` file to look like this:

```dart
import 'package:dartseid/dartseid.dart';

Future<void> main() {
  return runServer(port: 7331, init: () {
    // Define your routes here
  });
}
```

### 3. Run the development server

```bash
dartseid serve
```

## Routing

Dartseid routing is simple to use, but very powerful.

### Defining routes

Routes are defined in the `init` function of your `main.dart` file.

```dart
import 'package:dartseid/dartseid.dart';

Future<void> main() {
  return runServer(port: 7331, init: () {
    Route.get('/').handle((RequestContext context) => 'Hello, World!');
  });
}
```

### Route parameters

Route parameters are defined by prefixing a path segment with a colon.

```dart
import 'package:dartseid/dartseid.dart';

Future<void> main() {
  return runServer(port: 7331, init: () {
    Route.get('/users/:id').handle((RequestContext context) {
      return 'User ID: ${context.pathParameters['id']}';
    });
  });
}
```

### Route hooks

Route hooks are functions that are executed before or after a route handler.

```dart
import 'package:dartseid/dartseid.dart';

Future<void> main() {
  return runServer(port: 7331, init: () {
    Route.get('/users/:id').before((RequestContext context) {
      // Executed before the route handler
    }).handle((RequestContext context) {
      return 'User ID: ${context.pathParameters['id']}';
    }).after((RequestContext context) {
      // Executed after the route handler
    });
  });
}
```

Before hooks can be used to validate the request, 
or to add data to the context using custom a `RequestContext`.

```dart
import 'package:dartseid/dartseid.dart';

class IsAuthedRequestContext extends RequestContext {
  final int userId;

  IsAuthedRequestContext({
    required super.route,
    required super.request,
    required this.userId,
  });
}

Future<IsAuthedRequestContext> authHook(RequestContext context) async {
  final token = context.requestHeaders['authorization'];
  if (token == null) {
    throw UnauthorizedException(message: 'Missing authorization header');
  }
  final userId = await getUserIdFromToken(token);
  return IsAuthedRequestContext(
    route: context.route,
    request: context.rawRequest,
    userId: userId,
  );
}

String publicHandler(RequestContext context) {
  return 'Hello, World!';
}

String privateHandler(covariant IsAuthedRequestContext context) {
  return 'Hello, User ${context.userId}!';
}

Future<void> main() {
  return runServer(port: 7331, init: () {
    Route.get('/').handle(publicHandler);
    Route.get('/private').before(authHook).handle(privateHandler);
  });
}
```

## Exceptions

Dartseid has a built-in exception handler that will return a JSON response.
All exceptions thrown in a route handler will be caught and handled by the exception handler,
returning a 500 response by default.

Dartseid does have exceptions for common HTTP status codes.
All these extend the `DartseidHttpException` exception class,
which means you can also throw your own exceptions that extend `DartseidHttpException`.

The following exceptions are available:

- `BadRequestException`
- `UnauthorizedException`
- `ForbiddenException`
- `NotFoundException`
- `MethodNotAllowedException`
- `ConflictException`
- `ImATeapotException`
- `UnprocessableEntityException`
- `InternalServerErrorException`
- `ServiceUnavailableException`

To create your own exception, extend `DartseidHttpException`:

```dart
import 'package:dartseid/dartseid.dart';

class PayloadTooLargeException extends DartseidHttpException {
  const PayloadTooLargeException({
    String? message,
    Map<String, dynamic>? errors,
  }) : super('Uploaded file too large', 413, errors: errors);
}
```
