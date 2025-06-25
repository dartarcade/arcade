---
title: Dependency Injection Guide
description: Structuring larger Arcade applications with dependency injection
---

While Arcade's core is minimal and doesn't require dependency injection, using DI frameworks like Injectable can greatly improve code organization and testability in larger applications. This guide shows how to structure Arcade applications using the popular Injectable package.

## Why Dependency Injection?

As your Arcade application grows, you'll face challenges like:
- Managing dependencies between services
- Testing components in isolation
- Configuring different implementations for different environments
- Avoiding global state and singletons

Dependency injection helps solve these problems by:
- Centralizing dependency configuration
- Making dependencies explicit
- Enabling easy mocking for tests
- Supporting different configurations per environment

## Setting Up Injectable

Add Injectable to your project:

```yaml
dependencies:
  arcade: ^0.3.1
  injectable: ^2.3.0
  get_it: ^7.6.0

dev_dependencies:
  build_runner: ^2.4.0
  injectable_generator: ^2.4.0
```

## Basic Project Structure

Organize your project for dependency injection:

```
my_app/
├── bin/
│   └── server.dart              # Entry point
├── lib/
│   ├── core/
│   │   ├── di/
│   │   │   ├── injection.dart  # DI configuration
│   │   │   └── injection.config.dart  # Generated
│   │   ├── env/
│   │   │   └── env.dart        # Environment config
│   │   └── routes.dart          # Route definitions
│   ├── features/
│   │   ├── auth/
│   │   │   ├── controllers/
│   │   │   │   └── auth_controller.dart
│   │   │   ├── services/
│   │   │   │   └── auth_service.dart
│   │   │   └── repositories/
│   │   │       └── user_repository.dart
│   │   └── todos/
│   │       ├── controllers/
│   │       ├── services/
│   │       └── repositories/
│   └── shared/
│       ├── database/
│       ├── hooks/
│       └── utils/
└── pubspec.yaml
```

## Configuring Dependency Injection

Set up Injectable configuration:

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies({String? environment}) async {
  await getIt.init(environment: environment);
}
```

## Creating Injectable Services

Define services with Injectable annotations:

```dart
// lib/features/auth/services/auth_service.dart
import 'package:injectable/injectable.dart';

abstract class AuthService {
  Future<User?> validateToken(String token);
  Future<String> generateToken(User user);
  Future<User?> authenticate(String email, String password);
}

@LazySingleton(as: AuthService)
class AuthServiceImpl implements AuthService {
  final UserRepository userRepository;
  final HashService hashService;
  final JwtService jwtService;
  
  AuthServiceImpl({
    required this.userRepository,
    required this.hashService,
    required this.jwtService,
  });
  
  @override
  Future<User?> authenticate(String email, String password) async {
    final user = await userRepository.findByEmail(email);
    if (user == null) return null;
    
    final isValid = await hashService.verify(password, user.passwordHash);
    if (!isValid) return null;
    
    return user;
  }
  
  @override
  Future<String> generateToken(User user) async {
    return jwtService.sign({'userId': user.id, 'email': user.email});
  }
  
  @override
  Future<User?> validateToken(String token) async {
    try {
      final payload = jwtService.verify(token);
      return userRepository.findById(payload['userId']);
    } catch (e) {
      return null;
    }
  }
}
```

## Environment-Specific Implementations

Use Injectable environments for different configurations:

```dart
// lib/shared/database/database_connection.dart
abstract class DatabaseConnection {
  Future<void> connect();
  Future<Database> get database;
}

@dev
@LazySingleton(as: DatabaseConnection)
class DevDatabaseConnection implements DatabaseConnection {
  @override
  Future<void> connect() async {
    // Connect to local development database
  }
  
  @override
  Future<Database> get database => _devDatabase;
}

@prod
@LazySingleton(as: DatabaseConnection)
class ProdDatabaseConnection implements DatabaseConnection {
  final EnvConfig config;
  
  ProdDatabaseConnection(this.config);
  
  @override
  Future<void> connect() async {
    // Connect to production database using config
  }
  
  @override
  Future<Database> get database => _prodDatabase;
}
```

## Controllers with Dependency Injection

Create controllers that use injected services:

```dart
// lib/features/auth/controllers/auth_controller.dart
import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';

@injectable
class AuthController {
  final AuthService authService;
  
  AuthController(this.authService);
  
  Future<dynamic> login(RequestContext context) async {
    final result = await context.jsonMap();
    
    if (result case BodyParseSuccess(:final value)) {
      final email = value['email'] as String?;
      final password = value['password'] as String?;
      
      if (email == null || password == null) {
        throw BadRequestException(message: 'Email and password required');
      }
      
      final user = await authService.authenticate(email, password);
      if (user == null) {
        throw UnauthorizedException(message: 'Invalid credentials');
      }
      
      final token = await authService.generateToken(user);
      
      return {
        'token': token,
        'user': user.toJson(),
      };
    }
    
    throw BadRequestException();
  }
  
  Future<dynamic> me(AuthenticatedContext context) async {
    return context.user.toJson();
  }
}
```

## Authentication Hook with DI

Create reusable authentication hooks:

```dart
// lib/shared/hooks/auth_hook.dart
import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';

class AuthenticatedContext extends RequestContext {
  final User user;
  
  AuthenticatedContext({
    required super.request,
    required super.route,
    required this.user,
  });
}

@injectable
class AuthHooks {
  final AuthService authService;
  
  AuthHooks(this.authService);
  
  BeforeHookHandler<RequestContext, AuthenticatedContext> requireAuth() {
    return (context) async {
      final authHeader = context.requestHeaders.value('authorization');
      
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        throw UnauthorizedException(message: 'Missing authorization header');
      }
      
      final token = authHeader.substring(7);
      final user = await authService.validateToken(token);
      
      if (user == null) {
        throw UnauthorizedException(message: 'Invalid token');
      }
      
      return AuthenticatedContext(
        request: context.rawRequest,
        route: context.route,
        user: user,
      );
    };
  }
  
  BeforeHookHandler<RequestContext, AuthenticatedContext> requireRole(String role) {
    return (context) async {
      // First run regular auth
      final authedContext = await requireAuth()(context);
      
      if (!authedContext.user.roles.contains(role)) {
        throw ForbiddenException(message: 'Insufficient permissions');
      }
      
      return authedContext;
    };
  }
}
```

## Route Registration with DI

Organize routes using injected controllers:

```dart
// lib/core/routes.dart
import 'package:arcade/arcade.dart';
import 'package:injectable/injectable.dart';

@injectable
class Routes {
  final AuthController authController;
  final TodoController todoController;
  final AuthHooks authHooks;
  
  Routes({
    required this.authController,
    required this.todoController,
    required this.authHooks,
  });
  
  void register() {
    _registerAuthRoutes();
    _registerTodoRoutes();
    _registerHealthRoutes();
  }
  
  void _registerAuthRoutes() {
    route.group('/api/auth', defineRoutes: (route) {
      route().post('/login').handle(authController.login);
      route().post('/register').handle(authController.register);
      
      route().get('/me')
        .before(authHooks.requireAuth())
        .handle(authController.me);
    });
  }
  
  void _registerTodoRoutes() {
    route.group('/api/todos',
      before: [authHooks.requireAuth()],
      defineRoutes: (route) {
        route().get('/').handle(todoController.list);
        route().get('/:id').handle(todoController.get);
        route().post('/').handle(todoController.create);
        route().put('/:id').handle(todoController.update);
        route().delete('/:id').handle(todoController.delete);
      },
    );
  }
  
  void _registerHealthRoutes() {
    route.get('/health').handle((context) => {'status': 'ok'});
  }
}
```

## Main Entry Point

Wire everything together in the main function:

```dart
// bin/server.dart
import 'dart:io';
import 'package:arcade/arcade.dart';
import 'package:my_app/core/di/injection.dart';
import 'package:my_app/core/routes.dart';

Future<void> main(List<String> args) async {
  // Determine environment
  final environment = Platform.environment['ENV'] ?? 'dev';
  
  // Configure dependencies
  await configureDependencies(environment: environment);
  
  // Get port
  final port = int.parse(Platform.environment['PORT'] ?? '3000');
  
  await runServer(
    port: port,
    init: () async {
      // Initialize services
      final dbConnection = getIt<DatabaseConnection>();
      await dbConnection.connect();
      
      // Register routes
      final routes = getIt<Routes>();
      routes.register();
      
      // Set up error handler
      overrideErrorHandler(getIt<ErrorHandler>().handle);
    },
  );
}
```

## Testing with Dependency Injection

Write testable code using mocked dependencies:

```dart
// test/features/auth/auth_service_test.dart
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([UserRepository, HashService, JwtService])
void main() {
  late AuthServiceImpl authService;
  late MockUserRepository mockUserRepository;
  late MockHashService mockHashService;
  late MockJwtService mockJwtService;
  
  setUp(() {
    mockUserRepository = MockUserRepository();
    mockHashService = MockHashService();
    mockJwtService = MockJwtService();
    
    authService = AuthServiceImpl(
      userRepository: mockUserRepository,
      hashService: mockHashService,
      jwtService: mockJwtService,
    );
  });
  
  group('authenticate', () {
    test('returns user for valid credentials', () async {
      final user = User(id: '1', email: 'test@example.com');
      
      when(mockUserRepository.findByEmail('test@example.com'))
          .thenAnswer((_) async => user);
      when(mockHashService.verify('password', any))
          .thenAnswer((_) async => true);
      
      final result = await authService.authenticate('test@example.com', 'password');
      
      expect(result, equals(user));
    });
    
    test('returns null for invalid password', () async {
      final user = User(id: '1', email: 'test@example.com');
      
      when(mockUserRepository.findByEmail('test@example.com'))
          .thenAnswer((_) async => user);
      when(mockHashService.verify('wrong', any))
          .thenAnswer((_) async => false);
      
      final result = await authService.authenticate('test@example.com', 'wrong');
      
      expect(result, isNull);
    });
  });
}
```

## Advanced Patterns

### Factory Pattern with Injectable

```dart
@injectable
class ServiceFactory {
  final GetIt getIt;
  
  ServiceFactory(this.getIt);
  
  T create<T extends Object>() => getIt<T>();
  
  EmailService createEmailService(EmailProvider provider) {
    switch (provider) {
      case EmailProvider.sendgrid:
        return getIt<SendGridEmailService>();
      case EmailProvider.mailgun:
        return getIt<MailgunEmailService>();
      case EmailProvider.smtp:
        return getIt<SmtpEmailService>();
    }
  }
}
```

### Scoped Dependencies

```dart
@injectable
class RequestScopedService {
  final String requestId;
  final DateTime startTime;
  
  @factoryMethod
  static RequestScopedService create() {
    return RequestScopedService(
      requestId: Uuid().v4(),
      startTime: DateTime.now(),
    );
  }
  
  RequestScopedService({
    required this.requestId,
    required this.startTime,
  });
}

// Use in before hook
BeforeHookHandler createRequestScope() {
  return (context) {
    // Create new scope for this request
    final scope = getIt.pushNewScope();
    
    // Register request-scoped services
    scope.registerFactory(() => RequestScopedService.create());
    
    // Store scope for cleanup
    context.extra['diScope'] = scope;
    
    return context;
  };
}
```

## Best Practices

1. **Keep controllers thin** - Business logic belongs in services
2. **Use interfaces** - Define contracts for better testability
3. **Avoid circular dependencies** - Structure your code in layers
4. **Lazy load when possible** - Use `@LazySingleton` for expensive services
5. **Environment-specific configs** - Use `@dev`, `@prod` annotations
6. **Test in isolation** - Mock dependencies in unit tests
7. **Generate code frequently** - Run `dart run build_runner build` often

## Common Patterns

### Repository Pattern

```dart
abstract class Repository<T> {
  Future<T?> findById(String id);
  Future<List<T>> findAll();
  Future<T> save(T entity);
  Future<void> delete(String id);
}

@LazySingleton(as: Repository)
class UserRepository implements Repository<User> {
  final DatabaseConnection db;
  
  UserRepository(this.db);
  
  // Implementation...
}
```

### Service Layer

```dart
@injectable
class TodoService {
  final TodoRepository repository;
  final AuthService authService;
  final NotificationService notificationService;
  
  TodoService({
    required this.repository,
    required this.authService,
    required this.notificationService,
  });
  
  Future<Todo> createTodo(CreateTodoDto dto, User user) async {
    final todo = Todo(
      id: Uuid().v4(),
      title: dto.title,
      userId: user.id,
      createdAt: DateTime.now(),
    );
    
    final saved = await repository.save(todo);
    
    await notificationService.notifyNewTodo(user, saved);
    
    return saved;
  }
}
```

## Next Steps

- Explore the [todo_api sample](https://github.com/dartarcade/arcade/tree/main/samples/todo_api) for a complete example
- Learn about [Testing](/guides/testing/) with dependency injection
- See [Project Structure](/guides/project-structure/) for organizing large apps