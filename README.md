# tooler

A Modern Flutter Construction Tool Management Application with MVC Architecture.

## Project Structure

This project follows a clean MVC (Model-View-Controller) architecture for better maintainability and scalability.

```
lib/
├── main.dart              # App initialization and configuration
├── config/                # Configuration and constants
├── models/                # Data models
├── controllers/           # State management (Providers)
├── services/              # Business logic services
├── utils/                 # Utilities and helpers
└── views/                 # UI components
    ├── screens/           # App screens
    └── widgets/           # Reusable widgets
```

For detailed architecture documentation, see [ARCHITECTURE.md](ARCHITECTURE.md).

## Features

- **Tool Management**: Add, edit, delete, and track construction tools
- **Construction Objects**: Manage construction sites and projects
- **Location Tracking**: Track tool locations and movement history
- **Offline Support**: Full offline functionality with local Hive database
- **Cloud Sync**: Firebase integration for data synchronization
- **PDF Reports**: Generate and share detailed reports
- **Image Support**: Upload and manage tool images
- **Favorites**: Mark frequently used tools as favorites
- **Search**: Quick search across tools and objects
- **Modern UI**: GitHub-inspired light and dark themes

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase project (optional, for cloud features)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Mrxforte/tooler.git
cd tooler
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Architecture

The app follows the MVC pattern with clear separation of concerns:

- **Models** (`lib/models/`): Data structures and serialization
- **Views** (`lib/views/`): UI components and screens
- **Controllers** (`lib/controllers/`): State management using Provider pattern
- **Services** (`lib/services/`): Business logic and external integrations
- **Config** (`lib/config/`): App configuration and constants
- **Utils** (`lib/utils/`): Helper functions and utilities

## Development

### Adding a New Feature

1. Define the model in `lib/models/`
2. Create/update service in `lib/services/`
3. Implement controller logic in `lib/controllers/`
4. Build UI in `lib/views/screens/`
5. Add reusable widgets in `lib/views/widgets/`

### Code Style

- Follow Dart style guide
- Use `flutter analyze` to check for issues
- Format code with `flutter format .`

## Testing

```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building

```bash
# Android
flutter build apk

# iOS
flutter build ios

# Web
flutter build web
```

## Dependencies

Key dependencies include:
- `provider`: State management
- `hive_flutter`: Local database
- `firebase_core`, `firebase_auth`, `cloud_firestore`: Firebase integration
- `pdf`, `printing`: PDF generation
- `image_picker`: Image selection
- `share_plus`: Content sharing

See `pubspec.yaml` for the complete list.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the architecture guidelines
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
