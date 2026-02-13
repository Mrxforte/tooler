# 🔧 Tooler - Construction Tool Management App

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

**A modern, cross-platform mobile application for managing construction tools and inventory tracking**

[Features](#-features) • [Installation](#-installation) • [Usage](#-usage) • [Architecture](#-architecture) • [Contributing](#-contributing)

</div>

---

## 📖 About

**Tooler** is a comprehensive mobile application designed for construction professionals to efficiently manage their tool inventory. Whether you're tracking tools in your garage or across multiple construction sites, Tooler provides an intuitive interface with powerful features including offline support, location history, and Firebase cloud synchronization.

## ✨ Features

### 🏗️ Tool Management
- **Complete Tool Inventory**: Track all your construction tools with detailed information
  - Tool name, brand, and unique identification
  - Detailed descriptions and notes
  - Multiple photo attachments per tool
  - Favorite marking for quick access
  
### 📍 Location Tracking
- **Real-time Location Management**: Know where every tool is at all times
  - Store tools in garage or assign to construction sites
  - Track location history for each tool
  - Visual indicators for tool status
  - Quick location updates

### 🏢 Construction Object Management
- **Site Organization**: Organize tools by construction projects
  - Create and manage multiple construction sites
  - Assign tools to specific objects/projects
  - View all tools at a specific location
  - Track project-specific inventory

### 📊 Reporting & Sharing
- **Professional Reports**: Generate and share inventory reports
  - PDF report generation with tool details
  - Text-based export options
  - Share reports via any sharing app
  - Print-ready formatting

### ☁️ Cloud Synchronization
- **Firebase Integration**: Seamless cloud backup and multi-device support
  - Real-time Firebase Firestore sync
  - Image storage in Firebase Storage
  - User authentication with Firebase Auth
  - Automatic background synchronization

### 📱 Offline Support
- **Work Anywhere**: Full functionality without internet connection
  - Local database using Hive
  - Offline-first architecture
  - Automatic sync when connection restored
  - Queued updates for reliability

### 👤 User Management
- **Secure Authentication**: Multi-user support with secure login
  - Email/password authentication
  - User profiles with customization
  - Data isolation per user
  - Sign up and login flows

### 🎨 Modern UI/UX
- **Beautiful Interface**: Intuitive and responsive design
  - Material Design 3 components
  - Smooth animations and transitions
  - Russian language support
  - Custom icons and theming
  - Portrait-optimized layout

## 🏗️ Architecture

### Technology Stack

- **Framework**: Flutter 3.x
- **Language**: Dart 3.10.4+
- **State Management**: Provider
- **Local Database**: Hive
- **Backend Services**: 
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **PDF Generation**: pdf & printing packages
- **Image Handling**: image_picker
- **Connectivity**: connectivity_plus

### Project Structure

```
tooler/
├── lib/
│   ├── main.dart              # Main application entry point
│   │                          # Contains all app logic including:
│   │                          # - Data models (Tool, LocationHistory, etc.)
│   │                          # - Providers (AuthProvider, ToolsProvider, etc.)
│   │                          # - Services (ImageService, ReportService, etc.)
│   │                          # - UI screens (Login, Garage, Tools, etc.)
│   └── firebase_options.dart  # Firebase configuration
├── assets/
│   ├── images/               # App images and icons
│   └── fonts/                # Custom fonts
├── test/
│   └── widget_test.dart      # Integration tests
├── android/                  # Android platform code
├── ios/                      # iOS platform code
├── web/                      # Web platform code
└── pubspec.yaml             # Dependencies configuration
```

### Key Components

1. **Data Models**: Tool, LocationHistory, ConstructionObject, SyncItem
2. **Providers**: State management for auth, tools, and objects
3. **Services**: 
   - LocalDatabase: Hive-based local storage
   - ImageService: Image picking and management
   - ReportService: PDF and text report generation
   - ErrorHandler: Centralized error handling
4. **UI Screens**: 
   - Authentication (Login/Signup)
   - Garage (tool storage)
   - Tools List (inventory overview)
   - Tool Details (view/edit tools)
   - Construction Objects (site management)
   - Favorites, Profile, Settings

## 📦 Installation

### Prerequisites

- Flutter SDK (3.x or higher)
- Dart SDK (3.10.4 or higher)
- Firebase account and project
- iOS/Android development environment (for mobile builds)

### Setup Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Mrxforte/tooler.git
   cd tooler
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   
   Create a Firebase project at [Firebase Console](https://console.firebase.google.com/):
   
   - Enable Authentication (Email/Password)
   - Create a Firestore Database
   - Set up Firebase Storage
   - Download configuration files:
     - `google-services.json` for Android → `android/app/`
     - `GoogleService-Info.plist` for iOS → `ios/Runner/`
   
   Update Firebase configuration in `lib/main.dart`:
   ```dart
   await Firebase.initializeApp(
     options: FirebaseOptions(
       apiKey: 'YOUR_API_KEY',
       appId: 'YOUR_APP_ID',
       messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
       projectId: 'YOUR_PROJECT_ID',
       storageBucket: 'YOUR_STORAGE_BUCKET',
     ),
   );
   ```

4. **Firestore Security Rules** (recommended)
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /tools/{userId}/{toolId=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /objects/{userId}/{objectId=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

5. **Run the app**
   ```bash
   # For development
   flutter run
   
   # For specific platform
   flutter run -d chrome      # Web
   flutter run -d android     # Android
   flutter run -d ios         # iOS
   ```

## 🚀 Usage

### First Time Setup

1. **Launch the app** - You'll see the welcome/onboarding screen
2. **Sign up** - Create a new account with email and password
3. **Login** - Use your credentials to access the app

### Managing Tools

**Add a Tool:**
1. Navigate to the Garage or Tools screen
2. Tap the "+" (Add) button
3. Fill in tool details (name, brand, description)
4. Add photos if desired
5. Assign to garage or construction site
6. Save

**Edit a Tool:**
1. Tap on any tool to view details
2. Tap the edit icon
3. Update information
4. Save changes

**Track Location:**
1. Open tool details
2. Use location controls to move between garage and construction sites
3. View location history to see past movements

### Managing Construction Sites

1. Navigate to Construction Objects screen
2. Add new sites with name and description
3. Assign tools to specific sites
4. View all tools at each location

### Generating Reports

1. Go to the Garage or Tools screen
2. Tap the report/share icon
3. Choose PDF or text format
4. Share via any app or save to device

## 🧪 Testing

Run the test suite:

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

## 📱 Supported Platforms

- ✅ Android (5.0+)
- ✅ iOS (11.0+)
- ✅ Web (modern browsers)
- ⚠️ Desktop (Windows/macOS/Linux) - Experimental

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Guidelines

- Follow Dart/Flutter style guidelines
- Write tests for new features
- Update documentation as needed
- Ensure all tests pass before submitting PR
- Keep commits focused and atomic

## 📄 License

This project is private and proprietary. All rights reserved.

## 👨‍💻 Author

**Mrxforte**

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors and testers

## 📞 Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact the development team

---

<div align="center">

**Built with ❤️ using Flutter**

</div>
