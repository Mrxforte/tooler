# MVVM Refactoring Guide

## ✅ What's Been Done

Your 9,500-line `main.dart` has been refactored into a proper MVVM architecture:

### 1. **Core Layer** (`lib/core/`)
- ✅ `constants/app_constants.dart` - App-wide constants
- ✅ `utils/id_generator.dart` - ID generation utilities
- ✅ `utils/error_handler.dart` - Error handling utilities

### 2. **Data Layer** (`lib/data/`)
- ✅ **Models** (`models/`)
  - `tool.dart` - Tool and LocationHistory models
  - `construction_object.dart` - ConstructionObject model
  - `worker.dart` - Worker model
  - `notification.dart` - AppNotification model
  - `move_request.dart` - MoveRequest and BatchMoveRequest models
  - `salary.dart` - SalaryEntry, Advance, Penalty models
  - `attendance.dart` - Attendance and DailyWorkReport models
  - `app_user.dart` - AppUser model
  - `sync_item.dart` - SyncItem model

- ✅ **Adapters** (`adapters/`)
  - `hive_adapters.dart` - All Hive TypeAdapters

- ✅ **Repositories** (`repositories/`)
  - `local_database.dart` - Hive database management

- ✅ **Services** (`services/`)
  - `image_service.dart` - Image upload/pick functionality
  - `report_service.dart` - PDF/report generation (needs full extraction)

### 3. **ViewModels Layer** (`lib/viewmodels/`)
- ✅ `theme_provider.dart` - Theme management (COMPLETE)
- ✅ `notification_provider.dart` - Notifications logic (COMPLETE)
- ⚠️ `auth_provider.dart` - Authentication (SKELETON - needs extraction)
- ⚠️ `tools_provider.dart` - Tools management (SKELETON - needs extraction)
- ⚠️ `objects_provider.dart` - Objects management (SKELETON - needs extraction)
- ⚠️ `worker_provider.dart` - Worker management (SKELETON - needs extraction)
- ⚠️ `salary_provider.dart` - Salary management (SKELETON - needs extraction)
- ⚠️ `move_request_provider.dart` - Move requests (SKELETON - needs extraction)
- ⚠️ `batch_move_request_provider.dart` - Batch moves (SKELETON - needs extraction)
- ⚠️ `users_provider.dart` - User management (SKELETON - needs extraction)

### 4. **Views Layer** (`lib/views/`)
- 📋 **TODO**: Extract 20+ screens from `main.dart`:
  - `screens/auth/` - WelcomeScreen, OnboardingScreen, AuthScreen
  - `screens/tools/` - ToolsListScreen, AddEditToolScreen, ToolDetailsScreen, etc.
  - `screens/objects/` - ObjectsListScreen, AddEditObjectScreen, ObjectDetailsScreen
  - `screens/workers/` - WorkersListScreen, AddEditWorkerScreen, WorkerSalaryScreen
  - `screens/admin/` - AdminUsersScreen, AdminMoveRequestsScreen, AdminDailyReportsScreen
  - `screens/main/` - MainScreen
  - etc.
  
- 📋 **TODO**: Extract widgets:
  - `widgets/tool_card.dart`
  - `widgets/object_card.dart`
  - `widgets/worker_card.dart`
  - etc.

---

## 🔧 What You Need To Do

### Step 1: Complete the Providers
Each provider file marked with ⚠️ contains:
- Line references to the original code in `main.dart`
- Method stubs showing what needs to be implemented
- Comments explaining functionality

**Extract them one by one:**
1. Open the provider file (e.g., `auth_provider.dart`)
2. Find the referenced lines in your original `main.dart`
3. Copy the implementation into the new file
4. Add necessary imports

Example for `auth_provider.dart`:
- Open `main.dart` lines 2302-2481
- Copy the full `AuthProvider` class
- Replace the skeleton in `lib/viewmodels/auth_provider.dart`
- Add imports for Firebase, models, etc.

### Step 2: Extract ReportService
The `report_service.dart` is a large file (~800 lines).
- Find lines 1147-2006 in `main.dart`
- Replace the skeleton methods in `lib/data/services/report_service.dart`

### Step 3: Extract Screens
Create screen files in `lib/views/screens/`:

```
lib/views/screens/
├── auth/
│   ├── welcome_screen.dart
│   ├── onboarding_screen.dart
│   └── auth_screen.dart
├── tools/
│   ├── tools_list_screen.dart
│   ├── add_edit_tool_screen.dart
│   ├── tool_details_screen.dart
│   ├── garage_screen.dart
│   ├── move_tools_screen.dart
│   └── favorites_screen.dart
├── objects/
│   ├── objects_list_screen.dart
│   ├── add_edit_object_screen.dart
│   └── object_details_screen.dart
├── workers/
│   ├── workers_list_screen.dart
│   ├── add_edit_worker_screen.dart
│   ├── worker_salary_screen.dart
│   └── brigadier_screen.dart
├── admin/
│   ├── admin_users_screen.dart
│   ├── admin_move_requests_screen.dart
│   ├── admin_batch_move_requests_screen.dart
│   └── admin_daily_reports_screen.dart
└── main/
    ├── main_screen.dart
    ├── search_screen.dart
    ├── profile_screen.dart
    └── notifications_screen.dart
```

Search for each class in `main.dart` and extract to separate files.

### Step 4: Extract Widgets
Create reusable widgets in `lib/views/widgets/`:
- `tool_card.dart`
- `selection_tool_card.dart`
- `object_card.dart`
- `worker_card.dart`
- etc.

### Step 5: Update main.dart
Replace your old `main.dart` with the new structure (see `main.dart.new` if created).

---

## 📂 Final Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   └── utils/
│       ├── id_generator.dart
│       └── error_handler.dart
├── data/
│   ├── models/
│   │   ├── tool.dart
│   │   ├── construction_object.dart
│   │   ├── worker.dart
│   │   ├── notification.dart
│   │   ├── move_request.dart
│   │   ├── salary.dart
│   │   ├── attendance.dart
│   │   ├── app_user.dart
│   │   └── sync_item.dart
│   ├── adapters/
│   │   └── hive_adapters.dart
│   ├── repositories/
│   │   └── local_database.dart
│   └── services/
│       ├── image_service.dart
│       └── report_service.dart
├── viewmodels/
│   ├── auth_provider.dart
│   ├── tools_provider.dart
│   ├── objects_provider.dart
│   ├── worker_provider.dart
│   ├── salary_provider.dart
│   ├── notification_provider.dart
│   ├── move_request_provider.dart
│   ├── batch_move_request_provider.dart
│   ├── users_provider.dart
│   └── theme_provider.dart
├── views/
│   ├── screens/
│   │   ├── auth/
│   │   ├── tools/
│   │   ├── objects/
│   │   ├── workers/
│   │   ├── admin/
│   │   └── main/
│   └── widgets/
│       ├── tool_card.dart
│       ├── object_card.dart
│       └── worker_card.dart
└── main.dart
```

---

## 🎯 Benefits of This Architecture

✅ **Separation of Concerns** - Each layer has a clear responsibility
✅ **Testability** - ViewModels can be tested independently
✅ **Maintainability** - Easy to find and modify specific features
✅ **Scalability** - Add new features without touching unrelated code
✅ **Reusability** - Models and services can be reused across the app
✅ **Team Collaboration** - Multiple developers can work on different layers

---

## 💡 Tips

1. **Work incrementally** - Extract one provider/screen at a time and test
2. **Keep original main.dart** - Rename it to `main.dart.backup` for reference
3. **Test frequently** - Run the app after each extraction to catch errors early
4. **Use IDE refactoring** - Let your IDE help with imports and renames
5. **Follow the pattern** - Once you extract one screen, others follow the same pattern

---

## 🐛 Common Issues

**Import errors**: Make sure to add all necessary imports to each file
**Provider not found**: Ensure providers are registered in `main.dart` MultiProvider
**Navigator context issues**: Use `navigatorKey.currentContext` or pass context properly

---

Good luck with the refactoring! 🚀
