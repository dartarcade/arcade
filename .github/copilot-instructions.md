# Arcade Project - Copilot Instructions

This document provides comprehensive instructions for setting up, developing, and contributing to the Arcade framework.

## Overview

Arcade is a backend framework for Dart developers, focused on simplicity and a streamlined developer experience. This project is organized as a Dart workspace monorepo containing multiple packages.

**Repository:** <https://github.com/dartarcade/arcade>  
**Documentation:** <https://arcade.ex3.dev>

## Project Structure

```text
arcade/
├── .github/              # GitHub workflows and configuration
├── bin/                  # Project-level executables
├── docs/                 # Documentation site (Astro-based)
├── lib/                  # Project-level library code
├── packages/            # Workspace packages
│   ├── arcade/          # Core framework package
│   ├── arcade_cache/    # Caching abstraction
│   ├── arcade_cache_redis/  # Redis cache implementation
│   ├── arcade_cli/      # CLI tool for Arcade
│   ├── arcade_config/   # Configuration management
│   ├── arcade_logger/   # Logging utilities
│   ├── arcade_storage/  # Storage abstraction
│   ├── arcade_storage_minio/  # MinIO storage implementation
│   ├── arcade_swagger/  # Swagger/OpenAPI support
│   ├── arcade_test/     # Testing utilities
│   └── arcade_views/    # View/templating support
├── samples/             # Example applications
│   └── todo_api/        # Sample TODO API application
├── dpk.yaml            # DPK workspace configuration
├── pubspec.yaml        # Workspace pubspec
└── docker-compose.yml  # Docker services (Redis, MinIO)
```

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Dart SDK** (3.8.3)
   - **Recommended Installation (Linux)**: Use `asdf` to install a specific version
     ```bash
     # Install Homebrew
     /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
     # Follow post-install steps in the output of the install command
     
     # Install asdf
     brew install asdf
     
     # Add the Dart plugin
     asdf plugin add dart
     
     # Install specific Dart version
     asdf set -u dart 3.8.3
     asdf install
     
     # Add asdf shim path to PATH
     export PATH="$PATH:$HOME/.asdf/shims"
     ```
   - Alternative: <https://dart.dev/get-dart>
   - Verify: `dart --version`

2. **DPK (Dartpack)** - Workspace management tool
   - Installation: `dart pub global activate dpk`
   - Verify: `dpk --version`

3. **Docker & Docker Compose** (for services like Redis)
   - Installation: <https://docs.docker.com/get-docker/>
   - Required for: arcade, arcade_cache_redis tests

4. **Git** (for version control)
   - Installation: <https://git-scm.com/downloads>

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/dartarcade/arcade.git
cd arcade
```

### 2. Install Dependencies

```bash
# Install all workspace dependencies
dpk get
```

This command will:
- Resolve dependencies for all packages in the workspace
- Create a single `pubspec.lock` file at the root (Dart pub workspace)
- Download required packages

### 3. Start Docker Services (Optional, but required for some tests)

```bash
# Start Redis and other services
docker compose up -d

# Or use the dpk script
dpk run docker
```

To stop services:

```bash
docker compose down
# Or
dpk run docker:down
```

## Development Workflow

### Running Code Quality Checks

The project uses three main quality checks:

#### 1. Fix (Apply automated fixes)

```bash
dpk run fix
```

This runs `dart fix --apply` across all packages to automatically fix common issues.

#### 2. Format (Code formatting)

```bash
dpk run format
```

This runs `dart format --set-exit-if-changed .` to ensure consistent code style. The CI will fail if code is not properly formatted.

#### 3. Analyze (Static analysis)

```bash
dpk run analyze
```

This runs `dart analyze --fatal-infos --fatal-warnings` to catch potential issues. All warnings and infos must be resolved.

#### Combined FFA (Fix, Format, Analyze)

```bash
dpk run ffa
```

This runs all three checks in sequence - recommended before committing.

### Building

#### Example Application Build

The arcade package includes an example app that requires code generation:

```bash
dpk run example:build
```

This runs `build_runner` in the `packages/arcade/example` directory.

### Testing

Each package has its own test suite. Tests are run individually:

```bash
# Test arcade core package
dpk run test:arcade

# Test arcade_cache package
dpk run test:cache

# Test arcade_cache_redis (requires Redis)
dpk run test:redis

# Test arcade_views
dpk run test:views

# Test arcade_test
dpk run test:test

# Test arcade_swagger
dpk run test:swagger
```

**Important Notes:**
- Some tests require Docker services (Redis) to be running
- Tests use `-j 1` flag to run serially (prevents race conditions)
- Redis tests flush the database before running

### Working with Samples

#### TODO API Sample

The TODO API sample demonstrates a complete Arcade application:

```bash
# Navigate to the sample
cd samples/todo_api

# Clean build artifacts
dpk run todo:brc

# Run build_runner in watch mode
dpk run todo:br

# Start the sample server
dpk run todo:serve
```

## Making Changes

### Modifying a Package

1. Navigate to the package directory:
   ```bash
   cd packages/arcade
   ```

2. Make your changes

3. Run tests:
   ```bash
   cd ../..  # Back to root
   dpk run test:arcade
   ```

4. Run quality checks:
   ```bash
   dpk run ffa
   ```

### Adding Dependencies

To add a dependency to a package:

1. Edit the package's `pubspec.yaml`
2. Run `dpk get` from the root directory
3. Verify the dependency works

### Creating a New Package

When adding a new package to the workspace:

1. Create the package directory under `packages/`
2. Add the package to `pubspec.yaml` workspace list
3. Add appropriate test scripts to `dpk.yaml`
4. Run `dpk get`

## CI/CD Pipeline

The project uses GitHub Actions with two main workflows:

### Code Quality Workflow (`.github/workflows/code-quality.yml`)

Runs on every PR and push to main:
- **Analyze**: Static analysis of all packages
- **Format**: Checks code formatting

Steps:
1. Checkout code
2. Setup Dart SDK
3. Install DPK
4. Run `dpk get`
5. Build example app
6. Run analysis and format checks

### Test Workflow (`.github/workflows/test.yml`)

Runs tests for each package individually:
- arcade (requires Redis)
- arcade_cache
- arcade_cache_redis (requires Redis)
- arcade_test
- arcade_views
- arcade_swagger

Each test job:
1. Checks out code
2. Sets up Dart SDK
3. Installs DPK
4. Starts required services (Redis via Docker Compose if needed)
5. Runs package-specific tests

## Code Style Guidelines

### Formatting

- Use `dart format` for consistent formatting
- Line length: Default Dart (80 characters recommended)
- Follow Dart style guide: <https://dart.dev/guides/language/effective-dart/style>

### Analysis

- Address all analyzer warnings and infos
- Use `--fatal-infos --fatal-warnings` in CI
- See `analysis_options.yaml` for configuration

### Imports

- Order: dart, package, relative
- Group imports logically
- Avoid unused imports

### Documentation

- Use `///` for public API documentation
- Include examples in doc comments where appropriate
- Keep README.md files up-to-date in each package

## Version Management

### Bumping Versions

```bash
# Bump minor version for all packages
dpk run version:minor

# Bump patch version for all packages
dpk run version:patch

# Bump major version for all packages
dpk run version:major
```

### Publishing

**Note:** Package publishing is handled by maintainers. You should not run the `dpk run publish:all` command as it requires authentication and is part of the release process.

## Common Tasks

### Clean Pub Cache

If you encounter dependency issues:

```bash
# Clear pub cache
dart pub cache repair

# Reinstall dependencies
dpk get
```

### Updating Dependencies

```bash
# Update dependencies in all packages
dpk get --upgrade
```

### Debugging Tests

```bash
# Run a specific test file
cd packages/arcade
dart test test/specific_test.dart

# Run with verbose output
dart test -v
```

### Working with Git

```bash
# Create a feature branch
git checkout -b feature/my-feature

# Stage changes
git add .

# Commit with a descriptive message
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/my-feature
```

## Troubleshooting

### DPK Command Not Found

Ensure DPK is in your PATH:

```bash
dart pub global activate dpk
export PATH="$PATH":"$HOME/.pub-cache/bin"
```

### Redis Connection Issues

Ensure Docker services are running:

```bash
docker compose ps
docker compose logs redis
```

### Build Runner Issues

Clean and rebuild:

```bash
cd packages/arcade/example
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Test Failures

1. Ensure Docker services are running (if needed)
2. Check that dependencies are up-to-date: `dpk get`
3. Run tests with detailed stack traces: `dart test --chain-stack-traces`
4. Check CI logs for additional context

## Resources

- **Main Documentation**: <https://arcade.ex3.dev>
- **Getting Started Guide**: [docs/src/content/docs/getting-started.md](../docs/src/content/docs/getting-started.md)
- **API Reference**: Available in package README files
- **Issue Tracker**: <https://github.com/dartarcade/arcade/issues>
- **Dart Language**: <https://dart.dev>
- **DPK Documentation**: <https://pub.dev/packages/dpk>

## Getting Help

1. Check existing documentation in `/docs`
2. Review package-specific README files in `/packages`
3. Look at example applications in `/samples`
4. Search existing issues on GitHub
5. Ask questions by opening a new issue

## GitHub Copilot Instructions

When working with GitHub Copilot on this project:

### Creating Issues

If Copilot is asked to create an issue but cannot do so directly (due to permission limitations), it should provide the complete issue text in a reply comment. The issue text should include:

- **Title**: Clear, concise summary of the issue
- **Description**: Detailed explanation of what needs to be done
- **Context**: Any relevant background information
- **Acceptance Criteria**: Clear definition of when the issue is complete
- **Labels** (suggested): Appropriate labels for categorization

**Example format:**

```markdown
**Title:** Update Dart SDK environment constraint to 3.8.3

**Description:**
Update the Dart SDK environment constraint in all pubspec.yaml files across the workspace to use `^3.8.3`.

**Files to update:**
- Root pubspec.yaml
- All package pubspec.yaml files in packages/*

**Context:**
The project has standardized on Dart SDK 3.8.3 for development.

**Acceptance Criteria:**
- [ ] All pubspec.yaml files have environment.sdk set to '^3.8.3'
- [ ] Dependencies are resolved successfully with dpk get
- [ ] All tests pass

**Labels:** enhancement, dependencies
```

## Contributing

When contributing to Arcade:

1. Fork the repository
2. Create a feature branch
3. Make your changes following the guidelines above
4. Run `dpk run ffa` to ensure code quality
5. Run relevant tests: `dpk run test:<package>`
6. Submit a pull request with a clear description

### Pull Request Checklist

- [ ] Code follows Dart style guidelines
- [ ] All tests pass locally
- [ ] New tests added for new functionality
- [ ] Documentation updated (if applicable)
- [ ] `dpk run ffa` passes without errors
- [ ] Commit messages are clear and descriptive

## Quick Reference

```bash
# Setup
dpk get                    # Install dependencies
dpk run docker             # Start Docker services

# Development
dpk run ffa                # Fix, Format, Analyze
dpk run test:<package>     # Run package tests
dpk run example:build      # Build example app

# Quality
dpk run fix                # Apply automated fixes
dpk run format             # Format code
dpk run analyze            # Run static analysis

# Services
docker compose up -d       # Start services
docker compose down        # Stop services
docker compose logs redis  # View Redis logs
```
