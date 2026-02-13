# Tooler - MVC Architecture Documentation

## Overview

The Tooler application has been refactored from a monolithic 7,295-line `main.dart` file into a well-organized MVC (Model-View-Controller) architecture. The new structure reduces `main.dart` to just 496 lines (93% reduction) and organizes code into logical, maintainable modules.

## Directory Structure

```
lib/
├── main.dart                    # App initialization and configuration (496 lines)
├── firebase_options.dart        # Firebase configuration (generated)
│
├── config/                      # Configuration and Constants
│   ├── constants.dart           # App-wide constants (HiveBoxNames, AppConstants)
│   └── firebase_config.dart     # Firebase configuration options
│
├── models/                      # Data Models
│   ├── construction_object.dart # Construction object model
│   ├── location_history.dart    # Location history model
│   ├── sync_item.dart          # Sync queue item model
│   └── tool.dart               # Tool model
│
├── controllers/                 # State Management (Providers)
│   ├── auth_provider.dart      # Authentication state management
│   ├── objects_provider.dart   # Construction objects state management
│   └── tools_provider.dart     # Tools state management
│
├── services/                    # Business Logic Services
│   ├── error_handler.dart      # Error handling and dialogs
│   ├── image_service.dart      # Image upload and picker
│   ├── local_database.dart     # Hive local database management
│   └── report_service.dart     # PDF report generation
│
├── utils/                       # Utilities and Helpers
│   ├── hive_adapters.dart      # Hive type adapters for models
│   ├── id_generator.dart       # ID generation utilities
│   └── navigator_key.dart      # Global navigator key
│
└── views/                       # UI Components
    ├── screens/                 # Screen Widgets
    │   ├── add_edit_object_screen.dart
    │   ├── add_edit_tool_screen.dart
    │   ├── auth_screen.dart
    │   ├── favorites_screen.dart
    │   ├── garage_screen.dart
    │   ├── main_screen.dart
    │   ├── move_tools_screen.dart
    │   ├── object_details_screen.dart
    │   ├── objects_list_screen.dart
    │   ├── onboarding_screen.dart
    │   ├── profile_screen.dart
    │   ├── search_screen.dart
    │   ├── tool_details_screen.dart
    │   ├── tools_list_screen.dart
    │   └── welcome_screen.dart
    │
    └── widgets/                 # Reusable Widgets
        ├── object_card.dart
        └── selection_tool_card.dart
```

## Architecture Layers

### 1. Configuration Layer (`lib/config/`)

**Purpose**: Centralize all configuration and constant values.

**Files**:
- `constants.dart`: Defines `HiveBoxNames` for database box names and `AppConstants` for app-wide constants
- `firebase_config.dart`: Contains Firebase initialization options

**Usage**:
```dart
import 'package:tooler/config/constants.dart';
final toolsBox = HiveBoxNames.toolsBox;
```

### 2. Model Layer (`lib/models/`)

**Purpose**: Define data structures and their serialization logic.

**Files**:
- `tool.dart`: Tool model with JSON serialization, copyWith, and display methods
- `construction_object.dart`: Construction object model
- `location_history.dart`: Location history tracking model
- `sync_item.dart`: Sync queue item model

**Key Features**:
- JSON serialization (`toJson`, `fromJson`)
- Immutable-style updates with `copyWith`
- Business logic methods (e.g., `displayImage` getter)

**Usage**:
```dart
import 'package:tooler/models/tool.dart';
final tool = Tool(
  id: '123',
  title: 'Hammer',
  // ...
);
```

### 3. Controller Layer (`lib/controllers/`)

**Purpose**: Manage application state using the Provider pattern.

**Files**:
- `auth_provider.dart`: User authentication state (login, signup, profile)
- `tools_provider.dart`: Tools CRUD operations, filtering, sorting
- `objects_provider.dart`: Construction objects CRUD operations

**Key Features**:
- Extends `ChangeNotifier` for reactive state management
- Handles Firebase and local database synchronization
- Provides business logic for UI components

**Usage**:
```dart
import 'package:tooler/controllers/tools_provider.dart';
final toolsProvider = Provider.of<ToolsProvider>(context);
await toolsProvider.loadTools();
```

### 4. Service Layer (`lib/services/`)

**Purpose**: Encapsulate business logic and external integrations.

**Files**:
- `local_database.dart`: Hive database operations and cache management
- `image_service.dart`: Image upload (Firebase) and picker functionality
- `report_service.dart`: PDF report generation, sharing, and printing
- `error_handler.dart`: Centralized error handling and user notifications

**Key Features**:
- Static methods for easy access
- Separation of concerns from controllers
- Integration with external services (Firebase, file system)

**Usage**:
```dart
import 'package:tooler/services/local_database.dart';
await LocalDatabase.init();
final tools = LocalDatabase.tools.values.toList();
```

### 5. Utility Layer (`lib/utils/`)

**Purpose**: Provide helper functions and adapters.

**Files**:
- `id_generator.dart`: Generate unique IDs for tools and objects
- `hive_adapters.dart`: Hive TypeAdapters for model serialization
- `navigator_key.dart`: Global navigator key for context-free navigation

**Usage**:
```dart
import 'package:tooler/utils/id_generator.dart';
final toolId = IdGenerator.generateToolId();
```

### 6. View Layer (`lib/views/`)

**Purpose**: Define all UI components (screens and widgets).

**Screens** (`lib/views/screens/`):
- Authentication flow: `welcome_screen.dart`, `onboarding_screen.dart`, `auth_screen.dart`
- Main navigation: `main_screen.dart`, `garage_screen.dart`, `favorites_screen.dart`, `profile_screen.dart`, `search_screen.dart`
- Tools management: `tools_list_screen.dart`, `tool_details_screen.dart`, `add_edit_tool_screen.dart`, `move_tools_screen.dart`
- Objects management: `objects_list_screen.dart`, `object_details_screen.dart`, `add_edit_object_screen.dart`

**Widgets** (`lib/views/widgets/`):
- `selection_tool_card.dart`: Tool card with selection capability
- `object_card.dart`: Construction object card

**Key Features**:
- Separation of stateless and stateful widgets
- Provider consumption for state access
- Reusable widget components

**Usage**:
```dart
import 'package:tooler/views/screens/tools_list_screen.dart';
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ToolsListScreen()),
);
```

## Dependencies and Imports

### Import Guidelines

1. **Use relative imports** for files within the same package
2. **Import only what you need** to keep files focused and maintainable
3. **Follow this order** for imports:
   ```dart
   // 1. Dart core libraries
   import 'dart:io';
   
   // 2. Flutter libraries
   import 'package:flutter/material.dart';
   
   // 3. External packages
   import 'package:provider/provider.dart';
   
   // 4. Internal imports (alphabetically by layer)
   import '../../config/constants.dart';
   import '../../controllers/auth_provider.dart';
   import '../../models/tool.dart';
   import '../../services/error_handler.dart';
   import '../../utils/id_generator.dart';
   import '../widgets/tool_card.dart';
   ```

### Common Import Patterns

**For Controllers/Providers**:
```dart
import '../../models/tool.dart';
import '../../services/local_database.dart';
import '../../services/error_handler.dart';
```

**For Screens**:
```dart
import '../../controllers/tools_provider.dart';
import '../../models/tool.dart';
import '../../services/error_handler.dart';
import '../widgets/selection_tool_card.dart';
```

**For Widgets**:
```dart
import '../../models/tool.dart';
import '../screens/tool_details_screen.dart';
```

## State Management Flow

```
User Interaction (View)
        ↓
    Controller (Provider)
        ↓
    Service Layer
        ↓
Local Database ←→ Firebase
        ↓
    Model Updates
        ↓
Controller notifyListeners()
        ↓
    View Rebuilds
```

## Key Benefits of This Architecture

1. **Maintainability**: Each file has a single responsibility and is easy to locate
2. **Testability**: Services and models can be tested independently
3. **Scalability**: New features can be added without modifying existing files
4. **Readability**: Clear separation of concerns makes code easier to understand
5. **Reusability**: Widgets and services can be reused across the app
6. **Collaboration**: Multiple developers can work on different layers simultaneously

## Development Workflow

### Adding a New Feature

1. **Define the model** (if needed) in `lib/models/`
2. **Create the service** (if needed) in `lib/services/`
3. **Extend the controller** in `lib/controllers/`
4. **Create the UI screen** in `lib/views/screens/`
5. **Create reusable widgets** (if needed) in `lib/views/widgets/`
6. **Add navigation** in relevant screens

### Modifying Existing Features

1. **Locate the component** using the directory structure
2. **Update the model** if data structure changes
3. **Update the service** if business logic changes
4. **Update the controller** if state management changes
5. **Update the view** if UI changes

## Testing Strategy

- **Unit Tests**: Test models, services, and utilities
- **Widget Tests**: Test individual screens and widgets
- **Integration Tests**: Test complete user flows using providers
- **End-to-End Tests**: Test app functionality with real Firebase backend

## Migration Notes

This refactoring was completed without breaking existing functionality:
- All classes and methods remain unchanged
- Import paths have been updated throughout the codebase
- The `main.dart` file now serves as the app entry point and configuration hub
- No changes to external dependencies or pubspec.yaml

## Next Steps

1. Add unit tests for models and services
2. Add widget tests for screens
3. Consider extracting theme configuration to a separate file
4. Add more documentation comments to public APIs
5. Consider using freezed for immutable models
6. Implement repository pattern for data layer abstraction
