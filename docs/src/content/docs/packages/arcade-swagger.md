---
title: Arcade Swagger
description: OpenAPI/Swagger documentation generation for Arcade APIs
---

The `arcade_swagger` package provides automatic OpenAPI/Swagger documentation generation for your Arcade APIs. It integrates seamlessly with your routes and schemas to create interactive API documentation.

## Installation

Add `arcade_swagger` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_swagger: ^0.0.6
```

## Features

- **Automatic Documentation**: Generates OpenAPI spec from your routes
- **Swagger UI**: Interactive API documentation interface
- **Schema Integration**: Works with Luthor validation schemas
- **Security Definitions**: Support for various authentication methods
- **Try It Out**: Test API endpoints directly from the documentation
- **Customizable**: Full control over OpenAPI specification

## Quick Start

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_swagger/arcade_swagger.dart';

void main() async {
  await runServer(
    port: 3000,
    init: () {
      // Set up Swagger UI
      setupSwagger(
        path: '/docs',
        title: 'My API',
        version: '1.0.0',
        description: 'My awesome API documentation',
      );
      
      // Define your routes
      route.get('/users').handle((context) async {
        return [
          {'id': 1, 'name': 'John'},
          {'id': 2, 'name': 'Jane'},
        ];
      });
      
      // Visit http://localhost:3000/docs to see the documentation
    },
  );
}
```

## Basic Configuration

### OpenAPI Specification

```dart
setupSwagger(
  path: '/api-docs',
  title: 'E-Commerce API',
  version: '2.1.0',
  description: 'RESTful API for our e-commerce platform',
  servers: [
    OpenApiServer(
      url: 'https://api.example.com',
      description: 'Production server',
    ),
    OpenApiServer(
      url: 'https://staging-api.example.com',
      description: 'Staging server',
    ),
    OpenApiServer(
      url: 'http://localhost:3000',
      description: 'Development server',
    ),
  ],
  contact: OpenApiContact(
    name: 'API Support',
    email: 'api@example.com',
    url: 'https://support.example.com',
  ),
  license: OpenApiLicense(
    name: 'MIT',
    url: 'https://opensource.org/licenses/MIT',
  ),
);
```

### Route Documentation

Use the `route.swagger()` method to add OpenAPI documentation to your routes:

```dart
route.swagger(
  summary: 'List all products',
  description: 'Returns a paginated list of products with optional filtering',
  tags: ['Products'],
  parameters: [
    Parameter.query(name: 'page', schema: Schema.integer(), description: 'Page number'),
    Parameter.query(name: 'limit', schema: Schema.integer(), description: 'Items per page'),
    Parameter.query(name: 'category', schema: Schema.string(), description: 'Filter by category'),
  ],
  responses: {
    '200': ProductListSchema,
    '400': ErrorResponseSchema,
  },
).get('/products').handle((context) async {
  // Implementation
});
```

## Schema Integration

### With Luthor Schemas

```dart
import 'package:luthor/luthor.dart';
import 'package:openapi_spec/openapi_spec.dart';

final ProductSchema = l.schema({
  'id': l.int().required(),
  'name': l.string().min(1).max(255).required(),
  'price': l.double().min(0).required(),
  'category': l.string().required(),
  'inStock': l.boolean().required(),
});

final CreateProductSchema = l.schema({
  'name': l.string().min(1).max(255).required(),
  'price': l.double().min(0).required(),
  'category': l.string().required(),
});

final ProductListSchema = l.schema({
  'products': l.list(validators: [ProductSchema]).required(),
  'total': l.int().required(),
  'page': l.int().required(),
});

final ErrorResponseSchema = l.schema({
  'error': l.string().required(),
  'message': l.string().required(),
});

final NotFoundErrorSchema = l.schema({
  'error': l.string().required(),
  'message': l.string().required(),
});

final ValidationErrorSchema = l.schema({
  'errors': l.list().required(),
});

final UserSchema = l.schema({
  'id': l.int().required(),
  'name': l.string().required(),
  'email': l.string().required(),
});

final UploadResponseSchema = l.schema({
  'filename': l.string().required(),
  'size': l.int().required(),
  'url': l.string().required(),
});

route.swagger(
  summary: 'Create a new product',
  tags: ['Products'],
  request: CreateProductSchema,
  responses: {
    '201': ProductSchema,
    '400': ErrorResponseSchema,
  },
).post('/products')
  .handle((context) async {
    final result = await context.validateBody(CreateProductSchema);
    
    if (result.isValid) {
      final product = await createProduct(result.value);
      return Response.created(product);
    }
    
    return Response.badRequest(result.errors);
  });
```

### Reusable Schema Patterns

Define reusable Luthor validators that are automatically converted to OpenAPI schemas:

```dart
// Base schemas for common patterns
final PaginationSchema = l.schema({
  'page': l.int().min(1).required(),
  'limit': l.int().min(1).max(100).required(),
  'total': l.int().required(),
});

final TimestampSchema = l.schema({
  'createdAt': l.string().required(),
  'updatedAt': l.string().required(),
});

// Compose schemas using existing ones
final ProductWithTimestampsSchema = l.schema({
  'id': l.int().required(),
  'name': l.string().min(1).max(255).required(),
  'price': l.double().min(0).required(),
  'category': l.string().required(),
  'inStock': l.boolean().required(),
  'createdAt': l.string().required(),
  'updatedAt': l.string().required(),
});

// Use in routes - schemas are automatically registered
route.swagger(
  summary: 'Get products with pagination',
  responses: {
    '200': l.schema({
      'data': l.list(validators: [ProductWithTimestampsSchema]).required(),
      'pagination': PaginationSchema.required(),
    }),
  },
).get('/products').handle((context) async {
  // Implementation
});
```

## Authentication

### API Key Authentication

```dart
setupSwagger(
  title: 'My API',
  version: '1.0.0',
  securitySchemes: {
    'apiKey': SecurityScheme.apiKey(
      name: 'X-API-Key',
      location: ApiKeyLocation.header,
      description: 'API key for authentication',
    ),
  },
);

// Apply to specific routes
route.swagger(
  summary: 'Get admin users',
  security: [
    Security(name: 'apiKey'),
  ],
).get('/admin/users').handle((context) async {
  // Route requires API key
});
```

### Bearer Token (JWT)

```dart
setupSwagger(
  title: 'My API',
  version: '1.0.0',
  securitySchemes: {
    'bearerAuth': SecurityScheme.http(
      scheme: HttpSecurityScheme.bearer,
      bearerFormat: 'JWT',
      description: 'JWT authorization token',
    ),
  },
);

// Apply to routes
route.swagger(
  summary: 'Get user profile',
  security: [
    Security(name: 'bearerAuth'),
  ],
).get('/profile').handle((context) async {
  // Route requires JWT token
});
```

### OAuth2

```dart
setupSwagger(
  title: 'My API', 
  version: '1.0.0',
  securitySchemes: {
    'oauth2': SecurityScheme.oauth2(
      description: 'OAuth2 authentication',
      flows: OAuthFlows(
        authorizationCode: OAuthFlow(
          authorizationUrl: 'https://auth.example.com/oauth/authorize',
          tokenUrl: 'https://auth.example.com/oauth/token',
          scopes: {
            'read:users': 'Read user information',
            'write:users': 'Modify user information',
            'admin': 'Admin access',
          },
        ),
      ),
    ),
  },
);

// Apply with specific scopes
route.swagger(
  summary: 'Update user',
  security: [
    Security(name: 'oauth2', scopes: ['write:users']),
  ],
).put('/users/:id').handle((context) async {
  // Requires write:users scope
});
```


## Troubleshooting

### Swagger UI Not Loading

```dart
// Check route conflicts
route.get('/docs').handle((context) {
  // This would override Swagger UI
});
```

### Missing Route Documentation

```dart
// Routes must be defined before setupSwagger
route.get('/users').handle(getUsers);  // Define first
setupSwagger();  // Then setup Swagger
```

## Next Steps

- Learn about [Route Documentation](/core/routing/) patterns
- Explore [Validation](/guides/validation/) with schemas
- See [Authentication](/guides/authentication/) setup
- Read about [API Best Practices](/guides/api-design/)