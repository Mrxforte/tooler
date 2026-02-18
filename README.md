# Tooler

A Flutter-based Construction Tool Management application for tracking and managing construction tools across multiple locations.

## Features

- **Tool Management**: Add, edit, delete, and track construction tools
- **Location Tracking**: Move tools between garage and construction sites
- **Object Management**: Organize tools by construction objects/sites
- **Offline Support**: Works offline with local Hive database and syncs when online
- **User Authentication**: Firebase-based email/password authentication
- **Admin System**: Special admin users can view and manage all tools and objects
- **Reports & Backup**: Generate PDF reports and create data backups

## Admin Features

This application supports administrator accounts with enhanced privileges:

- **View All Data**: Admins can see all tools and objects from all users
- **Full Management**: Admins can delete and add any tools/objects
- **Secret Word**: Admins can manage a configurable secret word
- **Admin Panel**: Special UI section for admin controls

For information on setting up admin users, see [ADMIN_SETUP.md](ADMIN_SETUP.md).

## Getting Started

This project is a Flutter application. To run it:

1. Install Flutter SDK
2. Run `flutter pub get` to install dependencies
3. Set up Firebase project with your credentials
4. Run `flutter run` to start the application

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
