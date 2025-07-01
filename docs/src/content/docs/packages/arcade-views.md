---
title: Arcade Views
description: Template rendering engine for Arcade applications using Jinja2 syntax
---

The `arcade_views` package provides a powerful template rendering engine for Arcade applications, supporting Jinja2 syntax for dynamic HTML generation. It includes features like template inheritance, filters, and package-based views for reusable components.

## Installation

Add `arcade_views` to your `pubspec.yaml`:

```yaml
dependencies:
  arcade_views: ^<latest-version>
```

## Features

- **Jinja2 Syntax**: Familiar and powerful template syntax
- **Template Inheritance**: Create base layouts and extend them
- **Auto-reload**: Templates reload automatically in development
- **Package Views**: Load templates from Dart packages
- **Custom Filters**: Add custom template filters
- **Configurable**: Customize directories and extensions
- **Performance**: Template caching for production

## Quick Start

```dart
import 'package:arcade/arcade.dart';
import 'package:arcade_views/arcade_views.dart';

void main() async {
  await runServer(
    port: 3000,
    init: () {
      route.get('/').handle((context) async {
        return view('home', {
          'title': 'Welcome',
          'user': {'name': 'John Doe'},
        });
      });
    },
  );
}
```

Create `views/home.jinja`:

```jinja
<!DOCTYPE html>
<html>
<head>
    <title>{{ title }}</title>
</head>
<body>
    <h1>Hello, {{ user.name }}!</h1>
</body>
</html>
```

## Template Syntax

### Variables

```jinja
{# Simple variable #}
<p>Welcome, {{ username }}!</p>

{# Object properties #}
<p>Email: {{ user.email }}</p>

{# Array/List access #}
<p>First item: {{ items[0] }}</p>

{# Default values #}
<p>Name: {{ name | default('Guest') }}</p>
```

### Control Structures

```jinja
{# If statements #}
{% if user.isAdmin %}
    <p>Admin Panel</p>
{% elif user.isModerator %}
    <p>Moderator Panel</p>
{% else %}
    <p>User Dashboard</p>
{% endif %}

{# For loops #}
<ul>
{% for product in products %}
    <li>{{ product.name }} - ${{ product.price }}</li>
{% endfor %}
</ul>

{# Loop variables #}
{% for item in items %}
    <div class="{% if loop.first %}first{% endif %}">
        {{ loop.index }}: {{ item }}
    </div>
{% endfor %}
```

### Template Inheritance

Base template (`views/layouts/base.jinja`):

```jinja
<!DOCTYPE html>
<html>
<head>
    <title>{% block title %}My Site{% endblock %}</title>
    <link rel="stylesheet" href="/css/style.css">
    {% block head %}{% endblock %}
</head>
<body>
    <nav>
        {% include 'partials/navigation.jinja' %}
    </nav>

    <main>
        {% block content %}{% endblock %}
    </main>

    <footer>
        {% block footer %}
            <p>&copy; 2024 My Company</p>
        {% endblock %}
    </footer>

    {% block scripts %}{% endblock %}
</body>
</html>
```

Child template (`views/pages/about.jinja`):

```jinja
{% extends 'layouts/base.jinja' %}

{% block title %}About Us - {{ super() }}{% endblock %}

{% block content %}
    <h1>About Us</h1>
    <p>{{ company.description }}</p>
{% endblock %}

{% block scripts %}
    <script src="/js/about.js"></script>
{% endblock %}
```

### Includes

Partial template (`views/partials/card.jinja`):

```jinja
<div class="card">
    <h3>{{ card.title }}</h3>
    <p>{{ card.description }}</p>
    <a href="{{ card.link }}">Learn more</a>
</div>
```

Using includes:

```jinja
<div class="cards-grid">
    {% for item in cards %}
        {% include 'partials/card.jinja' with card=item %}
    {% endfor %}
</div>
```

## Configuration

### View Directories

```dart
import 'package:arcade_config/arcade_config.dart';

void configureViews() {
  // Change views directory
  ArcadeConfig.viewsDirectory = 'templates';

  // Change file extension
  ArcadeConfig.viewsExtension = '.html';
}
```

### Package Views

Load views from Dart packages:

```dart
route.get('/email/preview').handle((context) async {
  // Load view from a package
  return view('welcome', {
    'user': currentUser,
    'activationLink': 'https://example.com/activate',
  }, (packagePath: 'package:email_templates/', viewsPath: 'views'));
});
```

Package structure:

```console
email_templates/
├── lib/
├── views/
│   ├── welcome.jinja
│   ├── reset-password.jinja
│   └── layouts/
│       └── email-base.jinja
└── pubspec.yaml
```

### Error Pages

Create custom error pages:

```dart
overrideErrorHandler((context, error, stackTrace) async {
  final statusCode = error.statusCode;

  try {
    return view('errors/${statusCode}', {
      'error': error,
      'message': error.toString(),
      'isDevelopment': AppConfig.isDevelopment,
      'stackTrace': AppConfig.isDevelopment ? stackTrace : null,
    });
  } catch (_) {
    // Fallback if error template doesn't exist
    return view('errors/generic', {
      'statusCode': statusCode,
      'message': 'An error occurred',
    });
  }
});
```

Error template (`views/errors/404.jinja`):

```jinja
{% extends 'layouts/base.jinja' %}

{% block title %}Page Not Found{% endblock %}

{% block content %}
    <div class="error-page">
        <h1>404</h1>
        <h2>Page Not Found</h2>
        <p>The page you're looking for doesn't exist.</p>
        <a href="/" class="btn">Go Home</a>
    </div>
{% endblock %}
```

### Caching Strategies

```dart
class ViewCache {
  static final _cache = <String, String>{};
  static final _timestamps = <String, DateTime>{};

  static Future<String> renderCached(
    String template,
    Map<String, dynamic> data, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final key = '$template:${data.hashCode}';
    final cached = _cache[key];
    final timestamp = _timestamps[key];

    if (cached != null &&
        timestamp != null &&
        DateTime.now().difference(timestamp) < ttl) {
      return cached;
    }

    final rendered = await view(template, data);
    _cache[key] = rendered;
    _timestamps[key] = DateTime.now();

    return rendered;
  }
}

// Usage
route.get('/products').handle((context) async {
  final products = await getProducts();

  return ViewCache.renderCached('products/list', {
    'products': products,
  });
});
```

## Integration Examples

### With Authentication

```dart
// Hook to add user to context for later use in views
route.before((context) async {
  final user = await getCurrentUser(context);
  context.setData('currentUser', user);
  context.setData('isAuthenticated', user != null);
  return context;
});

// In route handlers, pass data to view
route.get('/dashboard').handle((context) async {
  return view('dashboard', {
    'currentUser': context.getData('currentUser'),
    'isAuthenticated': context.getData('isAuthenticated'),
    'stats': await getDashboardStats(),
  });
});

// In templates
{% if isAuthenticated %}
    <p>Welcome, {{ currentUser.name }}!</p>
    <a href="/logout">Logout</a>
{% else %}
    <a href="/login">Login</a>
{% endif %}
```

### With Status Messages

```dart
// Simple status message handling
route.post('/users').handle((context) async {
  try {
    final user = await createUser(context.body);

    return view('users/created', {
      'user': user,
      'message': {'type': 'success', 'text': 'User created successfully!'},
    });
  } catch (e) {
    return view('users/new', {
      'error': {'type': 'error', 'text': 'Failed to create user: ${e.toString()}'},
      'formData': context.body,
    });
  }
});
```

Status message template:

```jinja
{% if message %}
    <div class="alert alert-{{ message.type }}">
        {{ message.text }}
    </div>
{% endif %}

{% if error %}
    <div class="alert alert-{{ error.type }}">
        {{ error.text }}
    </div>
{% endif %}
```

### With Pagination

```dart
class PaginationHelper {
  static Map<String, dynamic> paginate({
    required int currentPage,
    required int totalItems,
    required int itemsPerPage,
    required String baseUrl,
  }) {
    final totalPages = (totalItems / itemsPerPage).ceil();

    return {
      'currentPage': currentPage,
      'totalPages': totalPages,
      'totalItems': totalItems,
      'itemsPerPage': itemsPerPage,
      'hasPrevious': currentPage > 1,
      'hasNext': currentPage < totalPages,
      'previousUrl': currentPage > 1 ? '$baseUrl?page=${currentPage - 1}' : null,
      'nextUrl': currentPage < totalPages ? '$baseUrl?page=${currentPage + 1}' : null,
      'pages': List.generate(totalPages, (i) => {
        'number': i + 1,
        'url': '$baseUrl?page=${i + 1}',
        'isCurrent': i + 1 == currentPage,
      }),
    };
  }
}
```

Pagination template:

```jinja
{% if pagination.totalPages > 1 %}
<nav class="pagination">
    {% if pagination.hasPrevious %}
        <a href="{{ pagination.previousUrl }}">Previous</a>
    {% endif %}

    {% for page in pagination.pages %}
        {% if page.isCurrent %}
            <span class="current">{{ page.number }}</span>
        {% else %}
            <a href="{{ page.url }}">{{ page.number }}</a>
        {% endif %}
    {% endfor %}

    {% if pagination.hasNext %}
        <a href="{{ pagination.nextUrl }}">Next</a>
    {% endif %}
</nav>
{% endif %}
```

## Performance Optimization

## Best Practices

1. **Organize Templates**: Use folders for layouts, partials, and pages
2. **Use Inheritance**: Create reusable base layouts
3. **Keep Logic Simple**: Move complex logic to controllers
4. **Escape Output**: Always escape user input
5. **Cache in Production**: Enable template caching
6. **Use Partials**: Break down complex templates
7. **Document Variables**: Comment expected template variables

## Troubleshooting

### Template Not Found

```dart
// Check configured paths
print('Views directory: ${ArcadeConfiguration.viewsDirectory.path}');
print('View extension: ${ArcadeConfiguration.viewsExtension}');
```

### Variable Not Defined

```jinja
{# Safe variable access #}
{{ user.name | default('Guest') }}

{# Check if variable exists #}
{% if user is defined %}
    {{ user.name }}
{% endif %}
```

## Next Steps

- Learn about [Static Files](/guides/static-files/) for assets
- Explore [Request Handling](/guides/request-handling/) for view data
- See [Configuration](/packages/arcade-config/) for view settings
- Read about [Error Handling](/core/error-handling/) for error pages
