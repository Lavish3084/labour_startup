const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
let serviceAccount;
try {
    serviceAccount = require('../serviceAccountKey.json');
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('Firebase Admin Initialized');
} catch (error) {
    console.warn('WARNING: serviceAccountKey.json not found or invalid.');
    console.warn('Push notifications will NOT work until this file is added to the backend directory.');
}

const sendNotification = async (fcmToken, title, body, data = {}) => {
    if (!serviceAccount) {
        console.warn('Skipping notification: Firebase Admin not initialized.');
        return;
    }
    if (!fcmToken) {
        console.warn('Skipping notification: No FCM Token provided.');
        return;
    }

    console.log(`[Notification] Attempting to send to: ${fcmToken.substring(0, 10)}...`);
    console.log(`[Notification] Title: ${title}, Body: ${body}, Data:`, data);

    try {
        const response = await admin.messaging().send({
            token: fcmToken,
            notification: {
                title: title,
                body: body
            },
            data: data
        });
        console.log(`[Notification] Successfully sent message: ${response}`);
    } catch (error) {
        console.error('[Notification] Error sending notification:', error);
    }
};

const sendBroadcastNotification = async (tokens, title, body, data = {}) => {
    if (!serviceAccount) {
        console.warn('Skipping broadcast: Firebase Admin not initialized.');
        return;
    }
    if (!tokens || tokens.length === 0) {
        console.warn('Skipping broadcast: No tokens provided.');
        return;
    }

    console.log(`[Notification] Broadcasting to ${tokens.length} tokens.`);
    console.log(`[Notification] Title: ${title}, Body: ${body}, Data:`, data);

    try {
        const response = await admin.messaging().sendEachForMulticast({
            tokens: tokens,
            notification: {
                title: title,
                body: body
            },
            data: data
        });
        console.log(`[Notification] Broadcast results: ${response.successCount} successes, ${response.failureCount} failures.`);

        if (response.failureCount > 0) {
            const failedTokens = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    failedTokens.push(tokens[idx]);
                    console.error(`[Notification] Failure for token ${tokens[idx].substring(0, 10)}...: ${resp.error}`);
                }
            });
        }
    } catch (error) {
        console.error('[Notification] Error sending broadcast notification:', error);
    }
}

module.exports = { sendNotification, sendBroadcastNotification };
