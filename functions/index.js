// Daily W – Cloud Functions
// Runs every 30 minutes, checks which users want a notification right now
// (based on their local time + timezone offset), and sends their W via FCM.

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * Returns today's active message for the given slot, or null if none exists.
 * Mirrors MessageService.getTodaysMessage() in Dart.
 */
async function getTodaysMessage(slot) {
  const snap = await db.collection('messages')
    .where('slot', '==', slot)
    .where('active', '==', true)
    .orderBy('scheduledDate', 'desc')
    .limit(1)
    .get();

  if (snap.empty) return null;
  const doc = snap.docs[0];
  return { id: doc.id, ...doc.data() };
}

/**
 * Rounds total minutes to the nearest 30 (e.g. 481 → 480 = "08:00").
 * Handles schedule jitter so a function that fires at 8:01 still matches 8:00.
 */
function roundToNearest30(totalMinutes) {
  return Math.round(totalMinutes / 30) * 30;
}

/** Zero-pads a number to 2 digits. */
function pad(n) {
  return String(n).padStart(2, '0');
}

/**
 * Given UTC total minutes and a timezone offset in minutes, returns the
 * user's local time as "HH:MM" rounded to nearest 30 min.
 */
function localTimeString(utcMinutes, offsetMinutes) {
  const localRaw = (utcMinutes + offsetMinutes + 1440 * 4) % 1440; // keep positive
  const localMinutes = roundToNearest30(localRaw) % 1440;
  const hh = Math.floor(localMinutes / 60);
  const mm = localMinutes % 60;
  return `${pad(hh)}:${pad(mm)}`;
}

// ─── Scheduled function ──────────────────────────────────────────────────────

exports.sendScheduledNotifications = onSchedule(
  {
    schedule: 'every 30 minutes',
    timeZone: 'UTC',
    memory: '256MiB',
    timeoutSeconds: 300,
  },
  async (_event) => {
    const now = new Date();
    const utcTotalMinutes = now.getUTCHours() * 60 + now.getUTCMinutes();

    // Pre-fetch all three slot messages — avoids redundant Firestore reads.
    const slots = ['morning', 'afternoon', 'evening'];
    const messages = {};
    await Promise.all(
      slots.map(async (slot) => {
        messages[slot] = await getTodaysMessage(slot);
      })
    );

    logger.info(
      `sendScheduledNotifications fired at UTC ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`,
      { messages: Object.fromEntries(slots.map((s) => [s, !!messages[s]])) }
    );

    // ── Batch through all users with an FCM token ────────────────────────
    // For initial launch scale this is fine; paginate at ~1 k+ active users.
    const usersSnap = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    if (usersSnap.empty) {
      logger.info('No users with FCM tokens found.');
      return;
    }

    // Build per-slot send batches: Map<slot, string[]> of tokens to message
    const tokensBySlot = { morning: [], afternoon: [], evening: [] };

    for (const doc of usersSnap.docs) {
      const user = doc.data();
      const token = user.fcmToken;
      if (!token) continue;

      const offsetMinutes = user.timezoneOffsetMinutes ?? 0;
      const localTime = localTimeString(utcTotalMinutes, offsetMinutes);
      const notifTimes = user.notificationTimes ?? {};

      for (const slot of slots) {
        // Free tier: morning W only. Afternoon + evening require Daily W Pro.
        if (slot !== 'morning' && !user.isPremium) continue;

        if (notifTimes[slot] === localTime && messages[slot]) {
          tokensBySlot[slot].push(token);
          break; // one notification per firing, even if times coincidentally match two slots
        }
      }
    }

    // ── Send FCM multicast for each slot ─────────────────────────────────
    const sendPromises = [];

    for (const slot of slots) {
      const tokens = tokensBySlot[slot];
      if (tokens.length === 0) continue;

      const msg = messages[slot];
      const slotLabel = slot.charAt(0).toUpperCase() + slot.slice(1);
      const title = `${slotLabel} W 💪`;
      const body = msg.text;

      logger.info(`Sending ${slot} W to ${tokens.length} device(s).`);

      // FCM allows max 500 tokens per multicast call.
      for (let i = 0; i < tokens.length; i += 500) {
        const chunk = tokens.slice(i, i + 500);
        sendPromises.push(
          messaging.sendEachForMulticast({
            tokens: chunk,
            notification: { title, body },
            android: {
              notification: {
                channelId: 'daily_w_channel',
                priority: 'high',
                // Show full message text without truncation on lock screen.
                notificationCount: 0,
              },
              priority: 'high',
            },
            data: {
              slot,
              messageId: msg.id,
            },
          }).then((response) => {
            // Clean up invalid tokens from Firestore so future sends stay lean.
            const staleTokens = [];
            response.responses.forEach((resp, idx) => {
              if (
                !resp.success &&
                (resp.error?.code === 'messaging/invalid-registration-token' ||
                  resp.error?.code === 'messaging/registration-token-not-registered')
              ) {
                staleTokens.push(chunk[idx]);
              }
            });

            if (staleTokens.length > 0) {
              logger.info(`Removing ${staleTokens.length} stale token(s).`);
              // Batch-remove stale tokens from user docs.
              const batch = db.batch();
              return db.collection('users')
                .where('fcmToken', 'in', staleTokens)
                .get()
                .then((snap) => {
                  snap.docs.forEach((d) =>
                    batch.update(d.ref, { fcmToken: admin.firestore.FieldValue.delete() })
                  );
                  return batch.commit();
                });
            }
          })
        );
      }
    }

    await Promise.allSettled(sendPromises);
    logger.info('sendScheduledNotifications complete.');
  }
);
