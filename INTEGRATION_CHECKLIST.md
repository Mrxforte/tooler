# Quick Integration Checklist

## Step 1: Register Providers in main.dart

```dart
// Add this provider to your MultiProvider in main.dart
ChangeNotifierProvider(create: (_) => BrigadierRequestProvider()),
```

Location: Around line 110-120 in main.dart with other providers

---

## Step 2: Add AdminBrigadierRequestsScreen to Navigation

### Option A: Add to Admin Menu (if you have admin navigation)
```dart
import 'package:tooler/views/screens/admin/admin_brigadier_requests_screen.dart';

// In your admin menu or navigation:
ElevatedButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AdminBrigadierRequestsScreen()),
  ),
  child: const Text('Запросы от бригадиров'),
),
```

### Option B: Add as Menu Item in AdminUsersScreen
Location: `lib/views/screens/admin/admin_users_screen.dart`

Add button near top of screen for quick access.

---

## Step 3: Add Bonus Feature to Workers Screen

### In workers_list_screen.dart, add method to fab menu:

```dart
// Add this button to the selection actions menu
SimpleDialogOption(
  onPressed: () {
    Navigator.pop(context);
    _giveBonusToSelected();
  },
  child: const Text('💰 Выдать бонус'),
),

// Add this method to the class:
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

### In worker_details_screen.dart, add method to button menu:

```dart
// Add button for giving bonus:
ElevatedButton.icon(
  icon: const Icon(Icons.card_giftcard),
  label: const Text('Выдать бонус'),
  onPressed: () => showDialog(
    context: context,
    builder: (_) => BonusDialog(
      worker: widget.worker,
      onBonusAdded: () => Navigator.pop(context),
    ),
  ),
),
```

---

## Step 4: Display Bonuses in UI

### In worker_details_screen.dart, add to financial section:

```dart
// Add these cards to _buildFinancialSection():
StatCard(
  title: 'Бонусы',
  value: '${widget.worker.totalBonus.toStringAsFixed(0)} ₽',
  icon: Icons.card_giftcard,
  color: Colors.purple,
),

StatCard(
  title: 'Ежемесячный бонус',
  value: '${widget.worker.monthlyBonus.toStringAsFixed(0)} ₽',
  icon: Icons.repeat,
  color: Colors.pink,
),
```

---

## Step 5: Test Bonus Functionality

1. **Create a Bonus:**
   - Go to Workers list
   - Select a worker
   - Click "Выдать бонус"
   - Enter amount, reason
   - Click "Выдать"
   - Verify success message

2. **Batch Bonus (Optional):**
   - Select multiple workers
   - Click menu → "Выдать бонус"
   - Enter amount
   - Verify all selected get the same bonus

3. **View Bonus in Details:**
   - Go to worker details
   - Check if bonuses appear in financial section

---

## Step 6: Test Location History

1. **Move a Tool:**
   ```
   - Go to Garage (Tools list)
   - Select a tool
   - Choose "Переместить"
   - Select new location
   - Verify location history entry created
   ```

2. **View Location History:**
   - Go to tool details (if implemented)
   - Should show timeline of locations

---

## Step 7: Test Brigadier Requests (Optional)

### For Testing Admin Approval:

1. **Create a Request:**
   - Login as Brigadier
   - Trigger a BrigadierRequestDialog from appropriate action
   - Fill form and submit
   - Should show success

2. **Admin Reviews:**
   - Login as Admin
   - Go to "Запросы от бригадиров" screen
   - Should see request in "Ожидающие" tab
   - Click Approve or Reject
   - Request should move to appropriate tab

---

## Files to Import

### In your screens where you want bonus features:
```dart
import 'package:tooler/views/dialogs/bonus_dialog.dart';
import 'package:tooler/views/dialogs/batch_bonus_dialog.dart';
```

### In admin screens:
```dart
import 'package:tooler/views/screens/admin/admin_brigadier_requests_screen.dart';
import 'package:tooler/views/dialogs/brigadier_request_dialog.dart';
```

---

## Database Setup (Optional - Only if using Firestore)

Create new Firestore collection:
```
Collection: brigadier_requests
Doc Structure:
{
  "brigadierId": "user_id",
  "objectId": "object_id",
  "type": "addWorker",
  "status": "pending",
  "createdAt": "2024-01-15T10:30:00Z",
  "resolvedAt": null,
  "resolvedBy": null,
  "data": {},
  "reason": "Description of request"
}
```

---

## Troubleshooting

### Provider not found error:
→ Make sure BrigadierRequestProvider is registered in main.dart

### Dialog doesn't appear:
→ Check imports are correct
→ Verify context is passed correctly
→ Check for Navigator errors

### Location history not tracking:
→ Verify ToolsProvider.moveTool() or moveSelectedTools() is being called
→ Check LocationHistory is being added to tool.locationHistory

### Bonuses not saving:
→ Verify WorkerProvider.giveBonus() is being called
→ Check LocalDatabase.workers.put() is saving data
→ Inspect worker model after update

---

## Verification Checklist

- [ ] BrigadierRequestProvider added to providers list
- [ ] AdminBrigadierRequestsScreen accessible from admin menu
- [ ] Bonus button added to workers screen
- [ ] BonusDialog and BatchBonusDialog imports correct
- [ ] Bonus fields showing in worker details
- [ ] Location history auto-tracking on tool moves
- [ ] All dialogs open without errors
- [ ] All screens display without errors
- [ ] Bonus data persists after app restart
- [ ] Request workflow functions correctly

---

## Quick Command Reference

```dart
// Give bonus to single worker
context.read<WorkerProvider>().giveBonus(
  workerId: workerId,
  amount: 5000,
  reason: 'Good work',
  givenBy: adminEmail,
);

// Give bonus to multiple workers
context.read<WorkerProvider>().giveBonusToSelected(
  amount: 5000,
  reason: 'Team bonus',
  givenBy: adminEmail,
);

// Move tool (with location history)
context.read<ToolsProvider>().moveTool(
  toolId,
  'object_123',
  'Object Name',
);

// Create brigadier request
context.read<BrigadierRequestProvider>().createRequest(
  brigadierId: userId,
  objectId: objectId,
  type: RequestType.addWorker,
  data: {'workerId': workerId},
  reason: 'Need this worker on site',
);

// Load requests (in InitState)
WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<BrigadierRequestProvider>().loadRequests();
});
```

---

## Expected Results After Integration

✅ Workers can receive bonuses individually or in batches
✅ Admin can approve/reject brigadier requests
✅ Tools automatically track location history
✅ All data persists to LocalDatabase
✅ Bonus info displays in worker details
✅ Location history accessible in tool details (if implemented)
✅ Request workflow visible in admin panel
✅ All operations logged with timestamps and user info

---

**Integration Difficulty: EASY** ⭐⭐☆☆☆

Average Integration Time: 1-2 hours

All heavy lifting is done. Just wire up navigation and dialogs!
