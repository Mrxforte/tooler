# Authentication Flow Diagram

## Before Changes (Broken Flow)

```
App Start
    ↓
MyApp Widget
    ↓
FutureBuilder (SharedPreferences) ← Loading...
    ↓
Create AuthProvider
    ↓
_initializeAuth() sets _isLoading = true
    ↓
Check _rememberMe && currentUser
    ↓
Set _isLoading = false
    ↓
Consumer checks authProvider.isLoading
    ↓
❌ STUCK: isLoading stays true for new users
    ↓
Infinite CircularProgressIndicator
```

## After Changes (Fixed Flow)

```
App Start
    ↓
MyApp Widget
    ↓
FutureBuilder (SharedPreferences) ← Completes properly
    ↓
Create AuthProvider
    ↓
_initializeAuth() sets _isLoading = true
    ↓
try {
    Check currentUser (regardless of _rememberMe)
    Load role from Firestore if user exists
}
finally {
    ✅ Always set _isLoading = false
}
    ↓
Consumer checks authProvider.isLoading
    ↓
✅ isLoading = false, flow continues
    ↓
Check if user logged in
    ↓
    ├─ Yes → MainScreen
    └─ No → AuthScreen
```

## Sign-Up Flow (New Users)

```
AuthScreen (Sign-Up Mode)
    ↓
User fills email + password + confirm password
    ↓
Optional: Profile Image
    ↓
Optional: Click "Есть ключ администратора?"
    ↓
    ├─ Admin Path (with key)
    │   ↓
    │   Enter admin key: TOOLER_ADMIN_2024
    │   ↓
    │   Validate key
    │   ↓
    │   ✅ Key valid → isAdmin = true
    │   ❌ Key invalid → Show error
    │
    └─ Regular User Path (no key)
        ↓
        isAdmin = false
    ↓
Create Firebase Auth account
    ↓
Upload profile image (once)
    ↓
Create Firestore user document
    {
        email: string
        userId: string
        role: 'admin' | 'user'
        isAdmin: boolean
        permissions: ['read', 'write', ...] 
        profileImageUrl: string?
        createdAt: timestamp
    }
    ↓
Navigate to MainScreen
```

## Sign-In Flow (Existing Users)

```
AuthScreen (Login Mode)
    ↓
User enters email + password
    ↓
Optional: Check "Запомнить меня"
    ↓
Authenticate with Firebase
    ↓
Load user role from Firestore
    {
        role: _userRole
        isAdmin: _isAdmin
    }
    ↓
Save email if remember me checked
    ↓
Navigate to MainScreen
```

## Profile Screen (Admin Badge Display)

```
ProfileScreen
    ↓
Display user email
    ↓
Check authProvider.isAdmin
    ↓
    ├─ true → Display:
    │         "Администратор" + [ADMIN] badge (amber)
    │
    └─ false → Display:
              "Менеджер инструментов"
    ↓
Show user stats and settings
```

## Sign-Out Flow

```
User clicks Sign Out
    ↓
AuthProvider.signOut()
    ↓
Firebase sign out
    ↓
Clear user data:
    - _user = null
    - _profileImage = null
    - _userRole = 'user' (reset to default)
    - _isAdmin = false
    ↓
Remove saved profile image URL
    ↓
Navigate to AuthScreen
```

## Key Improvements Visualization

### Loading States
```
BEFORE:                     AFTER:
┌──────────────────┐       ┌──────────────────┐
│  Loading...      │       │  Loading...      │
│  (infinite)      │       │  (completes)     │
│  ∞               │       │  ✓               │
└──────────────────┘       └──────────────────┘
        ↓                          ↓
   STUCK HERE              → AuthScreen or MainScreen
```

### Admin Sign-Up
```
BEFORE:                     AFTER:
┌──────────────────┐       ┌──────────────────┐
│  Sign Up         │       │  Sign Up         │
│  Email: ___      │       │  Email: ___      │
│  Password: ___   │       │  Password: ___   │
│  Confirm: ___    │       │  Confirm: ___    │
│                  │       │  [Photo]         │
│  (No admin)      │       │  [🔐 Admin Key?] │
└──────────────────┘       └──────────────────┘
```

### Profile Display
```
BEFORE:                     AFTER (Admin):
┌──────────────────┐       ┌──────────────────┐
│    [Photo]       │       │    [Photo]       │
│  user@email.com  │       │  admin@email.com │
│  "Менеджер       │       │  "Администратор" │
│  инструментов"   │       │  [ADMIN] 🟨      │
└──────────────────┘       └──────────────────┘

                           AFTER (User):
                           ┌──────────────────┐
                           │    [Photo]       │
                           │  user@email.com  │
                           │  "Менеджер       │
                           │  инструментов"   │
                           └──────────────────┘
```

## Security Architecture

```
Current (Development/Testing):
┌─────────────┐
│   Client    │
│  (Flutter)  │ ← Admin Key Stored Here
│             │ ← Role Validation Here
└─────────────┘
      ↓
┌─────────────┐
│  Firebase   │
│  Auth + DB  │ ← Stores role data
└─────────────┘

Recommended (Production):
┌─────────────┐
│   Client    │
│  (Flutter)  │ ← No sensitive keys
└─────────────┘
      ↓
┌─────────────┐
│  Backend    │
│  API/Cloud  │ ← Admin Key Validation
│  Functions  │ ← Role Assignment
└─────────────┘
      ↓
┌─────────────┐
│  Firebase   │
│  Auth + DB  │ ← Protected by Security Rules
└─────────────┘
```

## Data Structure

### User Document (Firestore)
```json
{
  "userId": "abc123...",
  "email": "user@example.com",
  "role": "admin" | "user",
  "isAdmin": true | false,
  "permissions": [
    "read",
    "write",
    "delete",      // Admin only
    "manage_users" // Admin only
  ],
  "profileImageUrl": "https://...",
  "createdAt": "2024-02-13T00:00:00Z"
}
```

### AuthConstants Class
```dart
class AuthConstants {
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  static const List<String> adminPermissions = [
    'read', 'write', 'delete', 'manage_users'
  ];
  static const List<String> userPermissions = [
    'read', 'write'
  ];
}
```
