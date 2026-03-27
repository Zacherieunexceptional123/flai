# Contributing to FlAI

Thank you for your interest in contributing to FlAI! This guide will help you get started.

## Getting Started

1. Fork the repository
2. Clone your fork
3. Install dependencies:
   ```bash
   melos bootstrap
   ```

## Development Workflow

1. Create a branch from `main`
2. Make your changes
3. Ensure code quality:
   ```bash
   melos run analyze    # Static analysis
   melos run format     # Code formatting
   melos run test       # Run tests
   ```
4. Open a pull request against `main`

### Working with Bricks

Bricks are Mason templates in `bricks/`. Each has a `brick.yaml` and `__brick__/` directory.

- When modifying a brick, update the corresponding files in `example/lib/flai/`
- When modifying the example app, sync changes back to the brick
- Test bricks: `mason make <brick_name> --output-dir _test_output`

### Working with the CLI

```bash
cd packages/flai_cli
dart analyze
dart test
dart run bin/flai.dart <command>
```

### Working with the Example App

```bash
cd example
flutter pub get
flutter analyze
flutter run
```

## Code Standards

### Dart

- Dart 3.11+ features (sealed classes, pattern matching, records)
- `dart format` with default line length
- `dart analyze --fatal-infos` with zero warnings
- `const` constructors where possible
- `///` doc comments on all public APIs

### Naming

- Widget classes: `Flai` prefix (e.g., `FlaiChatScreen`, `FlaiTypingIndicator`)
- Data classes: no prefix (e.g., `Message`, `ChatEvent`)
- Files: `snake_case.dart`

### Components

- Access theme via `FlaiTheme.of(context)` — never hardcode colors/sizes
- Complex components: Widget + Controller + State pattern
- Simple components: `StatelessWidget` or single `StatefulWidget`

### Commits

- Use conventional commits: `type(scope): description`
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- Example: `feat(chat_experience): add voice recording waveform`

## Pull Request Process

1. Ensure CI passes (analyze + format + test)
2. Update documentation if adding new features
3. Keep PRs focused — one feature or fix per PR
4. Link related issues with "Fixes #123" in the PR body

## Questions?

Open an issue or start a discussion on [GitHub Discussions](https://github.com/getflai-dev/flai/discussions).
