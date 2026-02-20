# Firebase Cloud Functions - Email Services

This directory contains Firebase Cloud Functions for the Tooler App that handle email notifications for password recovery and password backups.

## Functions Overview

### 1. `sendPasswordRecoveryEmail`
**Purpose:** Sends a professional password recovery email notification when a user requests password reset.

**Trigger:** Called from `password_recovery_screen.dart` via Callable HTTP Function

**Parameters:**
- `email` (required): User's email address
- `userName` (optional): User's display name for personalization

**Response:**
```json
{
  "success": true,
  "message": "Password recovery email sent successfully",
  "messageId": "email-message-id"
}
```

### 2. `sendPasswordBackupEmail`
**Purpose:** Sends a password recovery link reminder to the user's registered email.

**Trigger:** Called from `password_backup_screen.dart` via Callable HTTP Function

**Parameters:**
- `email` (required): User's email address
- `userName` (optional): User's display name
- `createdAt` (optional): Timestamp when the backup was created

**Response:**
```json
{
  "success": true,
  "message": "Password backup email sent successfully",
  "messageId": "email-message-id"
}
```

## Installation & Deployment

### Prerequisites
- Node.js 18 or higher
- Firebase CLI installed (`npm install -g firebase-tools`)
- Active Firebase project configured in your Flutter app
- Gmail account or email service configured for sending

### Step 1: Install Dependencies

```bash
cd functions
npm install
```

This installs:
- `firebase-functions` - Firebase Cloud Functions SDK
- `firebase-admin` - Firebase Admin SDK
- `nodemailer` - Email sending library

### Step 2: Configure Email Service

The functions currently use Gmail with App Passwords. You need to:

1. **Enable 2-Factor Authentication** on your Gmail account (required for App Passwords)
2. **Generate an App Password:**
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" and "Windows Computer"
   - Google will generate a 16-character password
   - Copy this password

3. **Set Environment Variables in Firebase:**

```bash
firebase functions:config:set gmail.email="your-email@gmail.com" gmail.password="your-16-char-app-password"
```

Or manually via Firebase Console:
- Go to Firebase Console → Project Settings → Cloud Functions
- Set the environment variables in the configuration

### Step 3: Deploy Functions

```bash
firebase deploy --only functions
```

Or deploy specific function:
```bash
firebase deploy --only functions:sendPasswordRecoveryEmail
```

### Step 4: Verify Deployment

```bash
firebase functions:list
```

You should see both functions listed:
- `sendPasswordRecoveryEmail`
- `sendPasswordBackupEmail`

## Testing

### Using Firebase Emulator

1. Start the emulator:
```bash
firebase emulators:start --only functions
```

2. The functions will run locally for testing

### Manual Testing with cURL

```bash
# Requires Firebase Authentication token
curl -X POST https://region-projectid.cloudfunctions.net/sendPasswordRecoveryEmail \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{
    "data": {
      "email": "user@example.com",
      "userName": "John Doe"
    }
  }'
```

## Email Configuration

### Using Different Email Services

The current implementation uses Gmail with Nodemailer. To use other services:

#### SendGrid
```javascript
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

// Then use sgMail.send() instead of nodemailer
```

#### Mailgun
```javascript
const mailgun = require('mailgun.js');
const FormData = require('form-data');
```

#### Firebase Cloud Email Service (recommended for production)
```javascript
// Use Firebase Extensions for professional email service
// https://firebase.google.com/products/extensions
```

## Security Considerations

1. **Sensitive Data:**
   - Environment variables are stored securely in Firebase
   - Email content uses HTTPS transport
   - No credentials are logged or exposed

2. **Rate Limiting:**
   - Consider adding rate limiting to prevent abuse
   - Firebase Cloud Functions have built-in quotas

3. **Authentication:**
   - Functions check for authenticated users (context.auth)
   - Only authenticated requests are processed

4. **Email Content:**
   - HTML emails are structured properly
   - Links are secure and authenticated

## Troubleshooting

### Email Not Sending

1. **Check Function Logs:**
```bash
firebase functions:log
```

2. **Verify Gmail App Password:**
   - Re-generate the App Password
   - Ensure 2FA is enabled on Gmail account

3. **Check Environment Variables:**
```bash
firebase functions:config:get
```

4. **Verify Function Execution:**
   - Check Firebase Console → Cloud Functions
   - Review execution logs

### Common Errors

| Error | Solution |
|-------|----------|
| `401 Invalid email` | Check email/password in environment variables |
| `timeout` | Functions are slow; increase timeout settings |
| `auth/unauthenticated` | Ensure user is logged in when calling function |

## Local Development

```bash
# Test functions locally
npm run serve

# Run shell for interactive testing
npm run shell

# View logs
npm run logs
```

## Production Deployment

1. **Use environment management:**
```bash
firebase functions:config:set gmail.email="..." gmail.password="..."
```

2. **Monitor function metrics:**
   - Firebase Console → Cloud Functions → Metrics
   - Monitor invocation count, duration, errors

3. **Set up alerting:**
   - Cloud Monitoring → Alerting Policies
   - Alert on function errors

4. **Update function code:**
```bash
# Make changes to index.js, then redeploy
firebase deploy --only functions
```

## References

- [Firebase Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/)
- [Firebase Callable Functions](https://firebase.google.com/docs/functions/callable)
- [Gmail App Passwords](https://support.google.com/accounts/answer/185833)

## Support

For issues or questions:
1. Check Firebase Cloud Functions logs
2. Review email service configuration
3. Consult official Firebase documentation
4. Verify network connectivity and firewall rules
