# SCREEN EXTRACTION GUIDE
## Complete List of 22 Screens to Extract from main_backup.dart

### ✅ COMPLETED (4 screens):
1. **welcome_screen.dart** - lib/views/screens/auth/welcome_screen.dart
   - Source: Lines 8224-8273
   - Status: ✅ Created

2. **onboarding_screen.dart** - lib/views/screens/auth/onboarding_screen.dart
   - Source: Lines 8275-8407
   - Status: ✅ Created

3. **auth_screen.dart** - lib/views/screens/auth/auth_screen.dart
   - Source: Lines 8409-8708
   - Status: ✅ Created

4. **add_edit_tool_screen.dart** - lib/views/screens/tools/add_edit_tool_screen.dart
   - Source: Lines 3903-4214
   - Status: ✅ Created

### 🔨 TOOL SCREENS (4 remaining):
5. **garage_screen.dart** - lib/views/screens/tools/garage_screen.dart
   - Source: Lines 4215-4602
   - Class: EnhancedGarageScreen → GarageScreen
   - Key Imports: Tool, ToolsProvider, AuthProvider, ObjectsProvider, ReportService
   - Status: ⏳ PENDING

6. **tool_details_screen.dart** - lib/views/screens/tools/tool_details_screen.dart
   - Source: Lines 4603-5078
   - Class: EnhancedToolDetailsScreen → ToolDetailsScreen
   - Key Imports: Tool, ToolsProvider, ObjectsProvider, AuthProvider, ReportService
   - Status: ⏳ PENDING

7. **move_tools_screen.dart** - lib/views/screens/tools/move_tools_screen.dart
   - Source: Lines 5926-6038
   - Class: MoveToolsScreen
   - Key Imports: Tool, ToolsProvider, ObjectsProvider
   - Status: ⏳ PENDING

8. **favorites_screen.dart** - lib/views/screens/tools/favorites_screen.dart
   - Source: Lines 6039-6115
   - Class: FavoritesScreen
   - Key Imports: Tool, ConstructionObject, ToolsProvider, ObjectsProvider, widgets
   - Status: ⏳ PENDING

### 🏗️ OBJECT SCREENS (3 screens):
9. **add_edit_object_screen.dart** - lib/views/screens/objects/add_edit_object_screen.dart
   - Source: Lines 5299-5569
   - Class: AddEditObjectScreen
   - Key Imports: ConstructionObject, ObjectsProvider, AuthProvider, ImageService
   - Status: ⏳ PENDING

10. **object_details_screen.dart** - lib/views/screens/objects/object_details_screen.dart
    - Source: Lines 5570-5703
    - Class: ObjectDetailsScreen
    - Key Imports: ConstructionObject, ToolsProvider, ObjectsProvider, AuthProvider
    - Status: ⏳ PENDING

11. **objects_list_screen.dart** - lib/views/screens/objects/objects_list_screen.dart
    - Source: Lines 5704-5925
    - Class: EnhancedObjectsListScreen → ObjectsListScreen
    - Key Imports: ConstructionObject, ObjectsProvider, ToolsProvider, AuthProvider
    - Status: ⏳ PENDING

### 👷 WORKER SCREENS (4 screens):
12. **workers_list_screen.dart** - lib/views/screens/workers/workers_list_screen.dart
    - Source: Lines 6391-6791
    - Class: WorkersListScreen
    - Key Imports: Worker, WorkerProvider, ObjectsProvider, SalaryProvider, AuthProvider
    - Status: ⏳ PENDING

13. **add_edit_worker_screen.dart** - lib/views/screens/workers/add_edit_worker_screen.dart
    - Source: Lines 6902-7048
    - Class: AddEditWorkerScreen
    - Key Imports: Worker, WorkerProvider, ObjectsProvider
    - Status: ⏳ PENDING

14. **worker_salary_screen.dart** - lib/views/screens/workers/worker_salary_screen.dart
    - Source: Lines 7049-7401
    - Class: WorkerSalaryScreen
    - Key Imports: Worker, SalaryEntry, Advance, Penalty, SalaryProvider, ReportService
    - Status: ⏳ PENDING

15. **brigadier_screen.dart** - lib/views/screens/workers/brigadier_screen.dart
    - Source: Lines 7402-7680
    - Class: BrigadierScreen
    - Key Imports: Worker, Attendance, DailyWorkReport, WorkerProvider, ToolsProvider, ObjectsProvider, SalaryProvider
    - Status: ⏳ PENDING

### 👨‍💼 ADMIN SCREENS (4 screens):
16. **admin_move_requests_screen.dart** - lib/views/screens/admin/admin_move_requests_screen.dart
    - Source: Lines 6116-6192
    - Class: AdminMoveRequestsScreen
    - Key Imports: MoveRequest, MoveRequestProvider, ToolsProvider, NotificationProvider
    - Status: ⏳ PENDING

17. **admin_batch_move_requests_screen.dart** - lib/views/screens/admin/admin_batch_move_requests_screen.dart
    - Source: Lines 6193-6282
    - Class: AdminBatchMoveRequestsScreen
    - Key Imports: BatchMoveRequest, BatchMoveRequestProvider, ToolsProvider, NotificationProvider
    - Status: ⏳ PENDING

18. **admin_users_screen.dart** - lib/views/screens/admin/admin_users_screen.dart
    - Source: Lines 6283-6352
    - Class: AdminUsersScreen
    - Key Imports: AppUser, UsersProvider, AuthProvider
    - Status: ⏳ PENDING

19. **admin_daily_reports_screen.dart** - lib/views/screens/admin/admin_daily_reports_screen.dart
    - Source: Lines 7681-7730
    - Class: AdminDailyReportsScreen
    - Key Imports: DailyWorkReport, SalaryProvider
    - Status: ⏳ PENDING

### 📣 OTHER SCREENS (3 screens):
20. **notifications_screen.dart** - lib/views/screens/notifications/notifications_screen.dart
    - Source: Lines 6353-6390
    - Class: NotificationsScreen
    - Key Imports: AppNotification, NotificationProvider
    - Status: ⏳ PENDING

21. **profile_screen.dart** - lib/views/screens/profile/profile_screen.dart
    - Source: Lines 7731-8128
    - Class: ProfileScreen
    - Key Imports: AuthProvider, ToolsProvider, ObjectsProvider, NotificationProvider, WorkerProvider, ReportService
    - Status: ⏳ PENDING

22. **search_screen.dart** - lib/views/screens/search/search_screen.dart
    - Source: Lines 8129-8223
    - Class: SearchScreen
    - Key Imports: Tool, ToolsProvider, widgets
    - Status: ⏳ PENDING

## Common Imports Needed:
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Models
import '../../../data/models/tool.dart';
import '../../../data/models/construction_object.dart';
import '../../../data/models/worker.dart';
import '../../../data/models/salary.dart';
import '../../../data/models/move_request.dart';
import '../../../data/models/notification.dart';

// Services
import '../../../core/services/image_service.dart';
import '../../../core/services/report_service.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/id_generator.dart';

// Providers
import '../../../viewmodels/tools_provider.dart';
import '../../../viewmodels/objects_provider.dart';
import '../../../viewmodels/auth_provider.dart';
import '../../../viewmodels/worker_provider.dart';
import '../../../viewmodels/salary_provider.dart';
import '../../../viewmodels/notification_provider.dart';
import '../../../viewmodels/move_request_provider.dart';
import '../../../viewmodels/users_provider.dart';
```

## Notes:
- Some screens use "Enhanced" prefix (e.g., EnhancedGarageScreen) - drop this in file names
- All screens need proper imports added at the top
- StatefulWidget screens need both the widget class and the State class
- Some screens reference widget components (SelectionToolCard, ObjectCard, WorkerCard) which also need to be extracted

## Total Progress: 4/22 Complete (18%)
