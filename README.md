# NekoComic

A modern comic reader built with Flutter, featuring a modular architecture with reusable packages.

## Architecture

This project is organized as a monorepo with the following packages:

| Package | Description |
|---------|-------------|
| [neko_core](./packages/neko_core/) | Core data models, storage, and network layer |
| [neko_source_js](./packages/neko_source_js/) | JavaScript-based comic source system |
| [neko_image](./packages/neko_image/) | Image loading and caching |
| [neko_reader](./packages/neko_reader/) | Comic reader component |
| [neko_ui](./packages/neko_ui/) | Reusable UI components |

## Getting Started

### Prerequisites

- Flutter SDK 3.41.4+
- Dart SDK 3.8.0+
- Rust (for some native dependencies)

### Setup

```bash
# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Or use flutter directly
flutter pub get
```

### Development

```bash
# Analyze all packages
melos analyze

# Run tests
melos test

# Build the app
melos build:app
```

## Documentation

- [Architecture Design](./doc/architecture.md)
- [Development Guide](./doc/development.md)
- [Package Specifications](./doc/packages/)

## License

See [LICENSE](./LICENSE)
