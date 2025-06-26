---
title: Arcade CLI
description: Command-line interface for managing Arcade applications
---

The `arcade_cli` package provides a powerful command-line interface for creating, developing, and managing Arcade applications. It includes tools for project scaffolding, development server with hot reload, and route inspection.

## Installation

Install the CLI globally:

```bash
dart pub global activate arcade_cli
```

Or add it as a dev dependency:

```yaml
dev_dependencies:
  arcade_cli: ^0.0.6
```

## Available Commands

### create - Project Scaffolding

Create a new Arcade project from a starter template:

```bash
# Create a new project
arcade create my-app

# Create in current directory
arcade create .

# Specify custom template (coming soon)
arcade create my-app --template api
```

The `create` command:
- Clones the official Arcade starter template
- Customizes the project name throughout the codebase
- Runs initial setup (`dart pub get`, `dart fix`, `dart format`)
- Creates a ready-to-run Arcade application

#### Project Structure

The `create` command generates a comprehensive starter template:

```
my-app/
├── bin/                    # Application entry points
├── lib/
│   ├── core/              # Core application setup
│   ├── modules/           # Feature modules
│   │   └── todos/         # Example Todo API (can be deleted)
│   └── shared/            # Shared utilities
├── docker-compose.yml     # Development services
├── dpk.yaml              # Development scripts
└── scripts/              # Utility scripts
```

#### What You Get

- **Example Todo API**: Complete CRUD implementation that can be deleted once you understand the pattern
- **Database Setup**: PostgreSQL with Drift ORM
- **Caching**: Redis integration
- **Object Storage**: MinIO for file storage
- **Docker Services**: All dependencies containerized
- **Code Generation**: Build runner configuration
- **API Documentation**: Swagger UI with authentication

### serve - Development Server

Run your application with automatic restart:

```bash
# Start development server
arcade serve
```

Features:
- **Auto Restart**: Automatically restarts on file changes
- **Smart Watching**: Monitors `bin/` and `lib/` directories
- **Fast Compilation**: Uses Dart compilation server for quick restarts
- **Graceful Shutdown**: Handles process signals properly

#### How It Works

1. Automatically finds your server file at `bin/{app_name}.dart`
2. Starts a Dart compilation server for faster restarts
3. Watches for file changes in `bin/` and `lib/`
4. Restarts the server from scratch when changes are detected (with 500ms debounce)

### routes - Route Inspection

List all registered routes in your application:

```bash
arcade routes
```

## Development Workflow

### 1. Create New Project

```bash
# Create project
arcade create todo-api
cd todo-api

# Copy environment configuration
cp .env.example .env

# Generate code (required before first run)
dpk run build

# Start Docker services
dpk run docker

# Start development server
dpk run dev
```

### 2. Inspect Routes

```bash
# During development
arcade routes
```

## Configuration

The CLI works out of the box with no configuration needed. It automatically detects your project structure from `pubspec.yaml`.

## Advanced Usage

### Custom Templates

```bash
# Use custom Git template
arcade create my-app --git-url https://github.com/user/arcade-template
# or
arcade create my-app -g https://github.com/user/arcade-template
```


### Docker Integration

```dockerfile
# Development Dockerfile
FROM dart:stable AS dev

WORKDIR /app

# Install Arcade CLI
RUN dart pub global activate arcade_cli

# Copy project files
COPY pubspec.* ./
RUN dart pub get

COPY . .

# Use arcade serve for development
CMD ["arcade", "serve"]
```

### CI/CD Integration

```yaml
# GitHub Actions
name: Routes Check

on: [push, pull_request]

jobs:
  check-routes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: dart-lang/setup-dart@v1
      
      - name: Install Arcade CLI
        run: dart pub global activate arcade_cli
        
      - name: Generate route metadata
        run: arcade routes --export
        
      - name: Check for uncommitted route changes
        run: |
          if [ -n "$(git status --porcelain)" ]; then
            echo "Route metadata is out of date"
            exit 1
          fi
```


## Troubleshooting

### Command Not Found

```bash
# Ensure pub global bin is in PATH
export PATH="$PATH:$HOME/.pub-cache/bin"

# Or run directly
dart pub global run arcade_cli:arcade create my-app
```

### Port Already in Use

```bash
# Kill the process using the port
lsof -ti:7331 | xargs kill

# Then restart
arcade serve
```

### Auto Restart Not Working

```bash
# Check file watching limits (Linux/macOS)
ulimit -n

# Increase if needed
ulimit -n 8192

# Restart arcade serve
arcade serve
```

### Compilation Errors

```bash
# Clear Dart cache
dart pub cache clean

# Reinstall dependencies
dart pub get

# Try again
arcade serve
```


## Next Steps

- Learn about [Configuration](/packages/arcade-config/) options
- Explore [Logging](/packages/arcade-logger/) for debugging
- See [Basic Routing](/guides/basic-routing/) guide
- Read about [Development Workflow](/guides/development/) best practices