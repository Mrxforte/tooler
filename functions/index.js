const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

// Initialize Firebase Admin SDK
admin.initializeApp();

// Configure email service
// NOTE: Update these environment variables in your Firebase Cloud Functions configuration
const emailUser = process.env.EMAIL_USER || "your-email@gmail.com";
const emailPassword = process.env.EMAIL_PASSWORD || "your-app-password";

// Create transporter for sending emails
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: emailUser,
    pass: emailPassword,
  },
});

/**
 * Cloud Function: Sends password recovery email notification
 * Triggered when password reset email is sent via Firebase Authentication
 * 
 * Usage:
 * POST /sendPasswordRecoveryEmail
 * Body: {
 *   email: "user@example.com",
 *   resetLink: "https://..." // optional, can be omitted if using Firebase default
 * }
 */
exports.sendPasswordRecoveryEmail = functions.https.onCall(
  async (data, context) => {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Request must be authenticated"
      );
    }

    const { email, userName } = data;

    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email address is required"
      );
    }

    try {
      // Verify user exists in Auth
      const userRecord = await admin.auth().getUserByEmail(email);

      // Prepare email content
      const mailOptions = {
        from: emailUser,
        to: email,
        subject: "🔐 Запрос на восстановление пароля - Tooler App",
        html: `
          <!DOCTYPE html>
          <html lang="ru">
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #0E639C 0%, #1e7bc7 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .button { display: inline-block; background: #0E639C; color: white; padding: 12px 30px; border-radius: 5px; text-decoration: none; margin: 20px 0; font-weight: bold; }
              .info-box { background: #e3f2fd; border-left: 4px solid #0E639C; padding: 15px; margin: 15px 0; border-radius: 4px; }
              .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; }
              .warning { color: #d32f2f; font-weight: bold; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔐 Восстановление пароля</h1>
                <p>Tooler App</p>
              </div>
              <div class="content">
                <h2>Привет${userName ? ", " + userName : ""}!</h2>
                
                <p>Мы получили запрос на восстановление пароля для вашего аккаунта.</p>
                
                <div class="info-box">
                  <p><strong>📧 Email:</strong> ${email}</p>
                  <p><strong>⏰ Время запроса:</strong> ${new Date().toLocaleString("ru-RU", {
                    timeZone: "UTC",
                  })}</p>
                </div>
                
                <h3>Что делать дальше:</h3>
                <ol>
                  <li>Откройте приложение Tooler</li>
                  <li>На экране входа нажмите "Забыли пароль?"</li>
                  <li>Введите ваш email: <strong>${email}</strong></li>
                  <li>Следуйте инструкциям в письме восстановления пароля</li>
                  <li>Создайте новый безопасный пароль</li>
                </ol>
                
                <div class="info-box">
                  <p class="warning">⚠️ Важно:</p>
                  <p>Если <strong>вы</strong> не запрашивали восстановление пароля, немедленно смените пароль или свяжитесь с администратором!</p>
                </div>
                
                <h3>Рекомендации по безопасности:</h3>
                <ul>
                  <li>✓ Используйте пароль не менее 8 символов</li>
                  <li>✓ Включите заглавные буквы, цифры и специальные символы</li>
                  <li>✓ Не используйте личную информацию в пароле</li>
                  <li>✓ Храните пароль в безопасном месте</li>
                </ul>
                
                <p style="margin-top: 30px; font-size: 14px; color: #888;">
                  Это автоматическое письмо. Пожалуйста, не отвечайте на него.
                </p>
              </div>
              <div class="footer">
                <p>© 2026 Tooler App. Все права защищены.</p>
                <p>Если у вас есть вопросы, обратитесь в службу поддержки.</p>
              </div>
            </div>
          </body>
          </html>
        `,
      };

      // Send email
      const info = await transporter.sendMail(mailOptions);

      console.log(
        `Password recovery email sent to ${email}. Message ID: ${info.messageId}`
      );

      return {
        success: true,
        message: "Password recovery email sent successfully",
        messageId: info.messageId,
      };
    } catch (error) {
      console.error("Error sending password recovery email:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to send email: ${error.message}`
      );
    }
  }
);

/**
 * Cloud Function: Sends password backup reminder email
 * Called when user wants to receive password backup via email
 * 
 * Usage:
 * POST /sendPasswordBackupEmail
 * Body: {
 *   email: "user@example.com",
 *   userName: "John Doe", // optional
 *   backupContent: "Email: ..., Password: ...", // optional content preview
 * }
 */
exports.sendPasswordBackupEmail = functions.https.onCall(
  async (data, context) => {
    // Check authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Request must be authenticated"
      );
    }

    const { email, userName, createdAt } = data;

    if (!email) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Email address is required"
      );
    }

    try {
      // Verify user exists in Auth
      await admin.auth().getUserByEmail(email);

      // Prepare email content
      const mailOptions = {
        from: emailUser,
        to: email,
        subject: "📋 Ссылка восстановления пароля - Tooler App",
        html: `
          <!DOCTYPE html>
          <html lang="ru">
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #06B6D4 0%, #0891B2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; text-align: center; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
              .info-box { background: #cffafe; border-left: 4px solid #06B6D4; padding: 15px; margin: 15px 0; border-radius: 4px; }
              .footer { text-align: center; font-size: 12px; color: #888; margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; }
              .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 15px 0; border-radius: 4px; color: #856404; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>📋 Ссылка восстановления пароля</h1>
                <p>Tooler App</p>
              </div>
              <div class="content">
                <h2>Привет${userName ? ", " + userName : ""}!</h2>
                
                <p>Вы запросили отправку ссылки восстановления пароля на этот адрес электронной почты.</p>
                
                <div class="info-box">
                  <p><strong>📧 Email:</strong> ${email}</p>
                  <p><strong>⏰ Дата создания:</strong> ${
                    createdAt
                      ? new Date(createdAt).toLocaleString("ru-RU")
                      : "В ходе сеанса"
                  }</p>
                </div>
                
                <h3>Инструкции по восстановлению:</h3>
                <ol>
                  <li>Откройте приложение Tooler на дорогом устройстве</li>
                  <li>На экране входа выберите "Забыли пароль?"</li>
                  <li>Введите ваш email адрес: <strong>${email}</strong></li>
                  <li>Проверьте на этом адресе письмо восстановления</li>
                  <li>Кликните ссылку в письме и создайте новый пароль</li>
                </ol>
                
                <div class="warning">
                  <strong>🔒 Помните о безопасности:</strong>
                  <ul>
                    <li>Никогда не делитесь этим письмом с другими</li>
                    <li>Используйте уникальный сильный пароль</li>
                    <li>Не сохраняйте пароль в открытом виде</li>
                    <li>Если вы не запрашивали это письмо - пожалуйста, смените пароль немедленно</li>
                  </ul>
                </div>
                
                <p style="margin-top: 30px; font-size: 14px; color: #888;">
                  Это автоматическое письмо. Пожалуйста, не отвечайте на него.
                </p>
              </div>
              <div class="footer">
                <p>© 2026 Tooler App. Все права защищены.</p>
                <p>Если у вас есть вопросы, обратитесь в службу поддержки.</p>
              </div>
            </div>
          </body>
          </html>
        `,
      };

      // Send email
      const info = await transporter.sendMail(mailOptions);

      console.log(
        `Password backup email sent to ${email}. Message ID: ${info.messageId}`
      );

      return {
        success: true,
        message: "Password backup email sent successfully",
        messageId: info.messageId,
      };
    } catch (error) {
      console.error("Error sending password backup email:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to send email: ${error.message}`
      );
    }
  }
);

/**
 * Cloud Function: Lists all users in Firebase Auth
 * Returns all authentication users with their metadata
 * 
 * Usage:
 * POST /listAllAuthUsers
 * Returns: { users: { uid, email, lastSignInTime, createdTime, disabled }[] }
 */
exports.listAllAuthUsers = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Request must be authenticated"
    );
  }

  try {
    const result = [];
    let pageToken = undefined;

    // List all users in batches
    while (true) {
      const batch = await admin.auth().listUsers(1000, pageToken);

      for (const userRecord of batch.users) {
        result.push({
          uid: userRecord.uid,
          email: userRecord.email || "No email",
          disabled: userRecord.disabled,
          createdTime: userRecord.metadata?.creationTime || null,
          lastSignInTime: userRecord.metadata?.lastSignInTime || null,
        });
      }

      pageToken = batch.pageToken;
      if (!pageToken) {
        break;
      }
    }

    console.log(`Listed ${result.length} users from Firebase Auth`);

    return {
      success: true,
      userCount: result.length,
      users: result,
    };
  } catch (error) {
    console.error("Error listing auth users:", error);
    throw new functions.https.HttpsError(
      "internal",
      `Failed to list users: ${error.message}`
    );
  }
});

/**
 * Cloud Function: Syncs Firebase Auth users to Firestore
 * Creates missing Firestore user documents for Auth users
 * 
 * Usage:
 * POST /syncAuthUsersToFirestore
 * Returns: { created: number, skipped: number, errors: string[] }
 */
exports.syncAuthUsersToFirestore = functions.https.onCall(
  async (data, context) => {
    // Check authentication & admin status
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Request must be authenticated"
      );
    }

    try {
      // Verify user is admin
      const adminDoc = await admin
        .firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();

      if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only admins can sync users"
        );
      }

      const stats = { created: 0, skipped: 0, errors: [] };
      const db = admin.firestore();

      let pageToken = undefined;

      // List all Auth users and sync to Firestore
      while (true) {
        const batch = await admin.auth().listUsers(1000, pageToken);

        for (const userRecord of batch.users) {
          try {
            const userRef = db.collection("users").doc(userRecord.uid);
            const exists = await userRef.get();

            if (!exists.exists) {
              // Create missing user document with default role
              await userRef.set({
                uid: userRecord.uid,
                email: userRecord.email || "",
                role: "user", // Default role
                canMoveTools: false,
                canControlObjects: false,
                createdAt: userRecord.metadata?.creationTime
                  ? admin.firestore.Timestamp.fromDate(
                      userRecord.metadata.creationTime
                    )
                  : admin.firestore.FieldValue.serverTimestamp(),
              });
              stats.created++;
              console.log(`Created Firestore doc for user: ${userRecord.uid}`);
            } else {
              stats.skipped++;
            }
          } catch (error) {
            stats.errors.push(
              `Error syncing ${userRecord.email}: ${error.message}`
            );
            console.error(
              `Error syncing user ${userRecord.uid}:`,
              error.message
            );
          }
        }

        pageToken = batch.pageToken;
        if (!pageToken) {
          break;
        }
      }

      console.log(
        `Sync complete: Created ${stats.created}, Skipped ${stats.skipped}, Errors: ${stats.errors.length}`
      );

      return {
        success: true,
        stats,
      };
    } catch (error) {
      console.error("Error syncing users:", error);
      throw new functions.https.HttpsError(
        "internal",
        `Failed to sync users: ${error.message}`
      );
    }
  }
);

/**
 * Cloud Function: Deletes a user from Firebase Auth and/or Firestore
 * 
 * Usage:
 * POST /deleteUserCompletely
 * Body: {
 *   uid: "user-id",
 *   deleteFromAuth: boolean,
 *   deleteFromFirestore: boolean
 * }
 */
exports.deleteUserCompletely = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Request must be authenticated"
    );
  }

  const { uid, deleteFromAuth, deleteFromFirestore } = data;

  if (!uid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "User UID is required"
    );
  }

  if (!deleteFromAuth && !deleteFromFirestore) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Must delete from at least Auth or Firestore"
    );
  }

  try {
    // Verify user is admin
    const adminDoc = await admin
      .firestore()
      .collection("users")
      .doc(context.auth.uid)
      .get();

    if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Only admins can delete users"
      );
    }

    const results = {
      authDeleted: false,
      firestoreDeleted: false,
      errors: [],
    };

    // Delete from Auth if requested
    if (deleteFromAuth) {
      try {
        await admin.auth().deleteUser(uid);
        results.authDeleted = true;
        console.log(`Deleted user from Auth: ${uid}`);
      } catch (error) {
        results.errors.push(`Auth deletion failed: ${error.message}`);
        console.error(`Error deleting user from Auth (${uid}):`, error);
      }
    }

    // Delete from Firestore if requested
    if (deleteFromFirestore) {
      try {
        await admin.firestore().collection("users").doc(uid).delete();
        results.firestoreDeleted = true;
        console.log(`Deleted user from Firestore: ${uid}`);
      } catch (error) {
        results.errors.push(`Firestore deletion failed: ${error.message}`);
        console.error(`Error deleting user from Firestore (${uid}):`, error);
      }
    }

    // Fail if nothing was deleted
    if (!results.authDeleted && !results.firestoreDeleted) {
      throw new functions.https.HttpsError(
        "internal",
        `Failed to delete user: ${results.errors.join(", ")}`
      );
    }

    return {
      success: true,
      message: `User ${uid} deleted successfully`,
      results,
    };
  } catch (error) {
    console.error("Error in deleteUserCompletely:", error);
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError(
        "not-found",
        `User ${uid} not found in Firebase Auth`
      );
    }
    throw new functions.https.HttpsError(
      "internal",
      `Failed to delete user: ${error.message}`
    );
  }
});
