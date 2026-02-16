# Tooler App - Advanced Worker & Tool Management System

## Summary of Enhancements

This document outlines all the new features, models, providers, dialogs, and screens added to implement an advanced worker and tool management system with admin controls, bonuses tracking, location history, and brigadier request workflows.

---

## 1. New Data Models

### 1.1 BonusEntry Model
**Location:** `lib/data/models/bonus_model.dart`

Tracks individual bonus transactions for workers.

**Fields:**
- `id`: Unique identifier
- `workerId`: Worker receiving the bonus
- `amount`: Bonus amount
- `reason`: Reason for the bonus
- `date`: When the bonus was given
- `givenBy`: Admin or Brigadier who gave the bonus
- `notes`: Optional additional notes

**Usage:** Used by WorkerProvider to manage bonus history and auditing.

---

### 1.2 LocationHistoryEntry Model
**Location:** `lib/data/models/location_history_model.dart`

Tracks movement history for workers and tools between locations (home, object, garage).

**Fields:**
- `id`: Unique identifier
- `resourceId`: Worker or Tool ID
- `resourceType`: 'worker' or 'tool'
- `fromLocation`: Starting location
- `toLocation`: Destination location
- `date`: When the move occurred
- `movedBy`: Admin or Brigadier who made the move
- `reason`: Reason for the move
- `objectId`: If moved to/from an object

**Enumerations:**
- `WorkerLocation`: home, object, garage
- `ToolLocation`: home, object, garage

**Usage:** Automatically tracked when workers/tools are moved via WorkerProvider/ToolsProvider.

---

### 1.3 BrigadierRequest Model
**Location:** `lib/data/models/brigadier_request_model.dart`

Manages request/approval workflow for brigadier actions that require admin approval.

**Enumerations:**
- `RequestType`: addWorker, removeWorker, addTool, removeTool, moveWorker, moveTool, changeSalary, giveBonus
- `RequestStatus`: pending, approved, rejected

**Fields:**
- `id`: Unique identifier
- `brigadierId`: Brigadier making the request
- `objectId`: Associated construction object
- `type`: Type of request (enum)
- `status`: Current status (enum)
- `createdAt`: Request creation timestamp
- `resolvedAt`: When admin resolved it
- `resolvedBy`: Admin who resolved the request
- `data`: Custom data map with request details
- `reason`: Why the brigadier is requesting this
- `rejectionReason`: If rejected, why

**Usage:** Used by BrigadierRequestProvider for admin approval workflow.

---

## 2. Enhanced Existing Models

### 2.1 Updated Worker Model
**Location:** `lib/data/models/worker.dart`

Added new fields for bonus tracking:
- `totalBonus: double` - Total bonuses earned by the worker
- `monthlyBonus: double` - Monthly bonus allowance

**Updated Methods:**
- `copyWith()` - Added totalBonus and monthlyBonus parameters

**Usage:** Tracks worker bonuses and allows batch updates.

---

### 2.2 Tool Model (No Changes Required)
**Location:** `lib/data/models/tool.dart`

Already has:
- `locationHistory: List<LocationHistory>` - Automatically populated when tools move
- Location tracking functionality ready to use

---

## 3. New Providers

### 3.1 BrigadierRequestProvider
**Location:** `lib/viewmodels/brigadier_request_provider.dart`

Manages the request/approval workflow for brigadier actions.

**Key Methods:**
- `loadRequests()` - Sync requests from Firestore
- `createRequest()` - Create a new request
- `approveRequest()` - Admin approves a request
- `rejectRequest()` - Admin rejects a request
- `getRequest()` - Get a specific request
- `getRequestsByBrigadier()` - Filter by brigadier
- `getRequestsByObject()` - Filter by object

**Properties:**
- `requests` - All requests
- `pendingRequests` - Awaiting approval
- `approvedRequests` - Approved requests
- `rejectedRequests` - Rejected requests
- `isLoading` - Loading state

**Usage:** Integrates with Firestore to manage approval workflow.

---

### 3.2 Enhanced WorkerProvider
**Location:** `lib/viewmodels/worker_provider.dart`

Added bonus management methods.

**New Methods:**
- `giveBonus()` - Give bonus to a single worker
- `giveBonusToSelected()` - Give bonus to multiple selected workers
- `setMonthlyBonus()` - Set monthly bonus allowance
- `clearSelection()` - Clear all selections and exit selection mode

**Usage:** Called from bonus dialogs to manage worker bonuses.

---

### 3.3 Enhanced ToolsProvider
**Location:** `lib/viewmodels/tools_provider.dart`

Enhanced to track location history when tools move.

**Updated Methods:**
- `moveTool()` - Now adds entry to locationHistory
- `moveSelectedTools()` - Now adds entries to locationHistory for each tool
- `clearSelection()` - New method to clear selections

**Location History Tracking:**
- Creates `LocationHistory` entry whenever tool is moved
- Stores fromLocation, toLocation, date, movedBy info
- Maintains audit trail of all tool movements

**Usage:** Automatically called when tools are moved between locations.

---

## 4. New Dialogs

### 4.1 BonusDialog
**Location:** `lib/views/dialogs/bonus_dialog.dart`

Dialog for giving bonus to a single worker.

**Fields:**
- Amount input field (required)
- Reason input field (required)
- Notes input field (optional)

**Features:**
- Input validation
- Displays worker name
- Stores bonus in worker model
- Shows success confirmation

**Usage:**
```dart
showDialog(
  context: context,
  builder: (_) => BonusDialog(worker: worker, onBonusAdded: () => reload()),
);
```

---

### 4.2 BatchBonusDialog
**Location:** `lib/views/dialogs/batch_bonus_dialog.dart`

Dialog for giving bonus to multiple selected workers.

**Fields:**
- Amount input field (required) - Same amount for all workers
- Reason input field (required)

**Features:**
- Shows count of selected workers
- Applies same bonus to all selected
- Shows total bonus amount to be distributed
- Input validation

**Usage:**
```dart
showDialog(
  context: context,
  builder: (_) => BatchBonusDialog(
    selectedCount: selectedWorkers.length,
    onBonusAdded: () => reload(),
  ),
);
```

---

### 4.3 BrigadierRequestDialog
**Location:** `lib/views/dialogs/brigadier_request_dialog.dart`

Dialog for brigadiers to request admin approval.

**Fields:**
- Request type (fixed, passed in constructor)
- Reason input field (optional)

**Features:**
- Shows pending approval status
- Explains request will be sent to admin
- Info card with orange warning color
- Stores request in Firestore

**Usage:**
```dart
showDialog(
  context: context,
  builder: (_) => BrigadierRequestDialog(
    objectId: objectId,
    requestType: RequestType.addWorker,
    title: 'Request to Add Worker',
    description: 'Admin approval required',
    onRequestCreated: () => refresh(),
  ),
);
```

---

## 5. New Screens

### 5.1 AdminBrigadierRequestsScreen
**Location:** `lib/views/screens/admin/admin_brigadier_requests_screen.dart`

Comprehensive admin panel for managing brigadier requests.

**Features:**
- **Three Tabs:**
  - Ожидающие (Pending) - Awaiting approval
  - Одобрено (Approved) - Already approved
  - Отклонено (Rejected) - Rejected requests

- **For Each Request:**
  - Status badge (pending/approved/rejected)
  - Brigadier ID
  - Object ID
  - Creation date
  - Request reason if provided
  - Approval/Rejection information

- **Admin Actions (Pending Tab):**
  - Approve button - Marks as approved
  - Reject button - Shows rejection reason dialog

- **Visual Indicators:**
  - Orange for pending (hourglass icon)
  - Green for approved (check circle icon)
  - Red for rejected (cancel icon)
  - Color-coded cards for easy scanning

**Integration:**
- Add to admin menu/navigation
- Shows list of all brigadier requests
- Auto-loads requests on screen init

---

## 6. Implementation Details

### 6.1 Bonus System
**How It Works:**
1. Admin opens worker details screen or workers list
2. Selects "Give Bonus" option
3. BonusDialog or BatchBonusDialog appears
4. Admin enters amount and reason
5. WorkerProvider.giveBonus() updates worker.totalBonus
6. Change persisted to LocalDatabase and Firestore
7. Worker can view bonus history in WorkerDetailsScreen

**User Journey:**
- Workers see totalBonus in profile/earnings summary
- Admin can give bonuses individually or in batches
- Each bonus tracked with date, amount, reason, and given by

---

### 6.2 Location Tracking System
**How It Works:**
1. Admin/Brigadier moves tool via ToolsProvider.moveTool()
2. System automatically creates LocationHistoryEntry
3. Entry includes: fromLocation, toLocation, date, movedBy, reason
4. Stored in tool.locationHistory List
5. Persisted to LocalDatabase and Firestore

**Audit Trail Features:**
- Complete history of all movements
- Timestamp for each move
- Who made the move (movedBy)
- Reason for the move (optional)
- Object ID if moved to/from object

**Viewing Location History:**
- Display in tool_details_screen (TabBar view)
- Shows timeline of movements
- Sortable by date

---

### 6.3 Brigadier Request Workflow
**Complete Flow:**

1. **Brigadier Creates Request:**
   - Clicks "Request Permission" button
   - BrigadierRequestDialog appears
   - Selects request type (add worker, remove tool, etc.)
   - Optionally enters reason
   - Submits request

2. **Request Created:**
   - Stored in Firestore collection 'brigadier_requests'
   - Status: pending
   - Assigned unique ID
   - Timestamp recorded

3. **Admin Reviews:**
   - Opens AdminBrigadierRequestsScreen
   - Sees pending requests in first tab
   - Reviews request details and reason

4. **Admin Approves or Rejects:**
   - Approve: Request status changes to approved
   - Reject: Shows dialog for rejection reason
   - System records who resolved it and when

5. **Brigadier Sees Result:**
   - Notified of approval/rejection
   - Can view history of requests
   - Can check status anytime

**Request Types Supported:**
- ADD_WORKER - Request to add worker to object
- REMOVE_WORKER - Request to remove worker
- ADD_TOOL - Request to add tool to object
- REMOVE_TOOL - Request to remove tool
- MOVE_WORKER - Request to move worker to different object
- MOVE_TOOL - Request to move tool to different location
- CHANGE_SALARY - Request to adjust worker salary
- GIVE_BONUS - Request to give worker bonus

---

## 7. Integration Guide

### 7.1 Adding to Main Providers
In `main.dart`, ensure all new providers are registered:

```dart
ChangeNotifierProvider(create: (_) => BrigadierRequestProvider()),
```

### 7.2 Navigation Integration
Add navigation items to admin menu:

```dart
// In AdminUsersScreen or main navigation
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AdminBrigadierRequestsScreen()),
  ),
  child: const Text('Запросы от бригадиров'),
),
```

### 7.3 Using Bonus Dialogs
In workers_list_screen or worker_details_screen:

```dart
// For single worker
void _giveBonusToWorker(Worker worker) {
  showDialog(
    context: context,
    builder: (_) => BonusDialog(
      worker: worker,
      onBonusAdded: () => context.read<WorkerProvider>().loadWorkers(),
    ),
  );
}

// For multiple selected workers
void _giveBonusToSelected() {
  final selectedCount = context.read<WorkerProvider>().selectedWorkers.length;
  showDialog(
    context: context,
    builder: (_) => BatchBonusDialog(
      selectedCount: selectedCount,
      onBonusAdded: () => context.read<WorkerProvider>().loadWorkers(),
    ),
  );
}
```

### 7.4 Tool Movement Integration
Tool movement already integrated in ToolsProvider. Just call existing methods:

```dart
// Move single tool
toolsProvider.moveTool(toolId, newLocationId, newLocationName);

// Move multiple tools
toolsProvider.moveSelectedTools(newLocationId, newLocationName);
```

Location history is automatically tracked.

---

## 8. Database Changes

### 8.1 New Firestore Collections
- `brigadier_requests` - Stores all brigadier requests
  - Fields: brigadierId, objectId, type, status, createdAt, resolvedAt, resolvedBy, data, reason, rejectionReason

### 8.2 Updated Firestore User Documents
- Add field `bonuses: List<BonusEntry>` (optional, for audit trail)

### 8.3 Tool Updates
- `locationHistory` field now actively maintained by ToolsProvider

---

## 9. Future Enhancements

### 9.1 Worker Availability
- Add `isAvailable: bool` to Worker model
- Create availability toggle in admin panel
- Show only available workers when assigning to objects

### 9.2 Batch Operations UI
- Create dedicated screen for selecting workers and applying operations
- Support: batch salary, batch bonuses, batch movements
- Bulk import/export functionality

### 9.3 Request Automation
- Auto-approve certain request types for trusted brigadiers
- Request templates for common operations
- Notification system for pending approvals

### 9.4 Location Analytics
- Generate location reports
- Track tool utilization by location
- Identify bottlenecks in tool distribution

### 9.5 Permission Levels
- Implement more granular permission system
- Different roles: admin, super-brigadier, brigadier, worker
- Custom permission sets per role

---

## 10. Files Created/Modified

### Created Files:
- `lib/data/models/bonus_model.dart` - BonusEntry model
- `lib/data/models/location_history_model.dart` - LocationHistoryEntry model
- `lib/data/models/brigadier_request_model.dart` - BrigadierRequest model
- `lib/viewmodels/brigadier_request_provider.dart` - Request management provider
- `lib/views/dialogs/bonus_dialog.dart` - Single worker bonus dialog
- `lib/views/dialogs/batch_bonus_dialog.dart` - Multiple workers bonus dialog
- `lib/views/dialogs/brigadier_request_dialog.dart` - Request creation dialog
- `lib/views/screens/admin/admin_brigadier_requests_screen.dart` - Admin request panel

### Modified Files:
- `lib/data/models/worker.dart` - Added totalBonus, monthlyBonus fields and copyWith support
- `lib/viewmodels/worker_provider.dart` - Added bonus methods and clearSelection
- `lib/viewmodels/tools_provider.dart` - Enhanced moveTool/moveSelectedTools with location history, added clearSelection

---

## 11. Testing Checklist

- [ ] Create new BrigadierRequest - verify stored in Firestore
- [ ] Approve request - verify status changes to 'approved'
- [ ] Reject request - verify rejection reason saved
- [ ] Give bonus to single worker - verify totalBonus updated
- [ ] Give bonus to multiple workers - verify all updated with correct amount
- [ ] Move tool - verify locationHistory entry created
- [ ] Move multiple tools - verify all have location history entries
- [ ] AdminBrigadierRequestsScreen loads - verify all requests display
- [ ] Tab filtering works - verify pending/approved/rejected separate correctly
- [ ] BonusDialog validates input - verify empty fields show error
- [ ] All dialogs close properly - verify state cleaned up

---

## 12. API Reference

### BrigadierRequestProvider

```dart
// Load requests from Firestore
Future<void> loadRequests()

// Create a new request
Future<void> createRequest({
  required String brigadierId,
  required String objectId,
  required RequestType type,
  required Map<String, dynamic> data,
  String? reason,
})

// Approve a request
Future<void> approveRequest({
  required String requestId,
  required String adminId,
})

// Reject a request
Future<void> rejectRequest({
  required String requestId,
  required String adminId,
  required String rejectionReason,
})

// Getters
List<BrigadierRequest> get requests
List<BrigadierRequest> get pendingRequests
List<BrigadierRequest> get approvedRequests
List<BrigadierRequest> get rejectedRequests
bool get isLoading
```

### WorkerProvider (New Methods)

```dart
// Give bonus to single worker
Future<void> giveBonus({
  required String workerId,
  required double amount,
  required String reason,
  required String givenBy,
  String? notes,
})

// Give bonus to multiple selected workers
Future<void> giveBonusToSelected({
  required double amount,
  required String reason,
  required String givenBy,
})

// Set monthly bonus allowance
Future<void> setMonthlyBonus({
  required String workerId,
  required double monthlyAmount,
})

// Clear all selections
void clearSelection()
```

### ToolsProvider (Enhanced Methods)

```dart
// Move single tool (with location history)
Future<void> moveTool(
  String toolId,
  String newLocationId,
  String newLocationName,
)

// Move multiple tools (with location history)
Future<void> moveSelectedTools(
  String newLocationId,
  String newLocationName,
)

// Clear all selections
void clearSelection()
```

---

**End of Document**
Version: 1.0
Last Updated: 2024
Status: Ready for Integration
