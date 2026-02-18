# Admin Setup Guide

This guide explains how to set up admin users in the Tooler application.

## Overview

The Tooler app now supports admin users who have special privileges:
- **View all tools and objects** from all users (not just their own)
- **Delete and add any tools/objects** 
- **Change the secret word** used for administrative purposes

## Setting Up an Admin User

To make a user an administrator, you need to update their document in Firebase Firestore:

### Method 1: Using Firebase Console

1. Open your Firebase Console
2. Navigate to Firestore Database
3. Go to the `users` collection
4. Find the user document (by their user ID)
5. Add or update the field:
   - Field name: `isAdmin`
   - Field type: `boolean`
   - Value: `true`

### Method 2: Using Firebase Admin SDK (Node.js example)

```javascript
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

async function makeUserAdmin(userId) {
  await db.collection('users').doc(userId).update({
    isAdmin: true
  });
  console.log(`User ${userId} is now an admin`);
}

// Replace with actual user ID
makeUserAdmin('USER_ID_HERE');
```

### Method 3: Manually in Firestore

When a user signs up, their document is created in the `users` collection. You can manually edit this document to add:

```json
{
  "email": "admin@example.com",
  "createdAt": "2024-01-01T00:00:00.000Z",
  "userId": "abc123xyz",
  "isAdmin": true
}
```

## Admin Features

### 1. Secret Word Management
- Default secret word: `admin123`
- Admins can change this through the Profile screen
- The secret word is stored locally in SharedPreferences
- To change it: Profile → Admin Panel → Secret Word

### 2. View All Data
- Admins automatically see all tools and objects from all users
- Regular users only see their own data
- This is enforced in the Firebase sync methods

### 3. Delete Permissions
- Admins can delete any tool or object
- Regular users can only delete their own items

### 4. Add Permissions
- Both admins and regular users can add tools and objects
- Items are still tagged with the creator's userId

## Admin UI Features

When logged in as an admin, users will see:

1. **Profile Header**: 
   - Title changes to "Администратор" (Administrator)
   - Yellow "ADMIN" badge displayed
   - Text color changes to amber

2. **Admin Panel** (in Profile screen):
   - Secret word management
   - Admin permissions information
   - Only visible to admin users

## Security Considerations

1. **Admin status is checked on each sync** to ensure proper data access
2. **Secret word changes require the current word** for verification
3. **Admin status is cleared on logout** for security
4. **Firebase rules should also enforce admin permissions** (not implemented in this code)

## Testing

To test admin functionality:

1. Create a test user account
2. Set `isAdmin: true` in Firestore for that user
3. Log in with that account
4. Verify you can:
   - See the ADMIN badge in profile
   - Access the Admin Panel
   - Change the secret word
   - See all tools/objects (if other users have created any)

## Troubleshooting

**Admin status not appearing after setting in Firestore:**
- Log out and log back in to refresh the status
- Check that the field name is exactly `isAdmin` (case-sensitive)
- Verify the value is a boolean `true`, not a string

**Can't change secret word:**
- Ensure you're entering the current secret word correctly
- Default is `admin123` unless changed
- The field is case-sensitive

**Not seeing all data:**
- Ensure there are other users with tools/objects in the system
- Check Firebase connection
- Try refreshing the data (pull down to refresh)
