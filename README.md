# Tooler

Tooler is a Flutter app for managing construction inventory. It helps teams track tools and objects, move items between locations, and keep reports and backups in one place.

## Features

- Firebase authentication (email/password, password reset, remember me)
- Role and permission system (`admin`, `brigadir`, `user`, plus custom flags)
- Tool management:
  - Create, edit, and delete tools
  - Search, sort, and filter by location, brand, and favorites
  - Upload tool photos from camera or gallery
  - Keep location history for each tool
  - Single-select and multi-select actions
- Object management:
  - Create, edit, and delete objects/sites
  - Search and sorting
  - Favorites support
  - Link tools to objects
- Favorites tab for quick access to saved tools and objects
- Profile actions:
  - Export reports (PDF/text/share)
  - Create and share JSON backups
  - Admin shortcuts (users, settings, move requests)
- In-app notifications state (read/unread)
- Local notifications and daily background task init
- Light, dark, and system theme support

## Tech Stack

- Flutter + Dart
- Firebase Auth, Firestore, Storage, App Check
- Provider for state management
- `pdf`, `printing`, `share_plus` for reports and sharing
- `workmanager` for background tasks

## Project Layout

- `lib/main.dart`: app setup, providers, routing, theme
- `lib/viewmodels/`: state and business logic
- `lib/views/`: screens, dialogs, widgets
- `lib/data/models/`: domain models
- `lib/data/services/`: services (reports, image upload, etc.)

## Run Locally

1. Install Flutter SDK.
2. Configure Firebase for Android/iOS/Web as needed.
3. Make sure these files are present:
   - `android/app/google-services.json`
   - `lib/firebase_options.dart` (from FlutterFire)
4. Install dependencies:

```bash
flutter pub get
```

5. Start the app:

```bash
flutter run
```

## Notes

- Most UI text is currently in Russian.
- Move-request providers are scaffolded and can be expanded with full workflow logic.
