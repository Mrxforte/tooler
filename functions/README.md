# Firebase Cloud Functions (Email)

This folder contains the Cloud Functions used for password-related emails in Tooler.

## What Is Here

### sendPasswordRecoveryEmail
- Used by the password recovery screen.
- Sends a recovery notification email.
- Inputs:
  - `email` (required)
  - `userName` (optional)

### sendPasswordBackupEmail
- Used by the password backup screen.
- Sends a backup/recovery reminder email.
- Inputs:
  - `email` (required)
  - `userName` (optional)
  - `createdAt` (optional)

Both functions return a payload like:

```json
{
  "success": true,
  "message": "...",
  "messageId": "..."
}
```

## Setup

Requirements:
- Node.js 18+
- Firebase CLI
- Configured Firebase project
- Email provider credentials (current setup uses Gmail App Password)

Install dependencies:

```bash
cd functions
npm install
```

Set Gmail config values:

```bash
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-app-password"
```

Deploy:

```bash
firebase deploy --only functions
```

Check deployed functions:

```bash
firebase functions:list
```

## Local Testing

Run emulator:

```bash
firebase emulators:start --only functions
```

Or use npm scripts:

```bash
npm run serve
npm run shell
npm run logs
```

## Troubleshooting

Check logs:

```bash
firebase functions:log
```

Check config:

```bash
firebase functions:config:get
```

Common issues:
- `auth/unauthenticated`: user is not signed in when calling the function.
- `timeout`: function is taking too long.
- Email auth errors: verify Gmail App Password and 2FA.

## Notes

- Credentials should stay in Firebase config, not in source files.
- If you switch email providers, update `functions/index.js` accordingly.

## References

- https://firebase.google.com/docs/functions
- https://firebase.google.com/docs/functions/callable
- https://nodemailer.com/
