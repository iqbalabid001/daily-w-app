// Daily W – Cloud Functions
// Runs every 30 minutes, checks which users want a notification right now
// (based on their local time + timezone offset), and sends their W via FCM.
// Uses per-user message rotation: tracks seen message IDs per slot so the
// same message is never repeated until all messages for that slot are seen.

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { logger } = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

// ─── Helpers ────────────────────────────────────────────────────────────────

/** Returns today's UTC date as 'YYYY-MM-DD'. */
function todayUTC() {
  return new Date().toISOString().slice(0, 10);
}

/** Fetches ALL active messages for [slot]. */
async function getAllMessages(slot) {
  const snap = await db.collection('messages')
    .where('slot', '==', slot)
    .where('active', '==', true)
    .get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

/**
 * Picks a random unseen message from [allMessages].
 * If all messages have been seen, resets the seen list and picks from the full pool.
 * Returns { msg, newSeenIds }.
 */
function pickUnseen(allMessages, seenIds = []) {
  let pool = allMessages.filter((m) => !seenIds.includes(m.id));
  const didReset = pool.length === 0;
  if (didReset) pool = [...allMessages];
  const msg = pool[Math.floor(Math.random() * pool.length)];
  const newSeenIds = didReset ? [msg.id] : [...seenIds, msg.id];
  return { msg, newSeenIds };
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
  const localRaw = (utcMinutes + offsetMinutes + 1440 * 4) % 1440;
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
    const today = todayUTC();
    const slots = ['morning', 'afternoon', 'evening'];

    // Pre-fetch ALL active messages for each slot.
    const allMessages = {};
    await Promise.all(
      slots.map(async (slot) => {
        allMessages[slot] = await getAllMessages(slot);
      })
    );

    logger.info(
      `sendScheduledNotifications fired at UTC ${pad(now.getUTCHours())}:${pad(now.getUTCMinutes())}`,
      { messageCounts: Object.fromEntries(slots.map((s) => [s, allMessages[s].length])) }
    );

    const usersSnap = await db.collection('users')
      .where('fcmToken', '!=', null)
      .get();

    if (usersSnap.empty) {
      logger.info('No users with FCM tokens found.');
      return;
    }

    // Per-user: determine which message to send for each slot firing now.
    // Group by (slot, messageId) so users getting the same message are multicasted together.
    const groups = {}; // `${slot}:${msgId}` → { slot, msg, tokens: [] }
    const userDocUpdates = []; // { docRef, data } — flushed to Firestore in batches

    for (const doc of usersSnap.docs) {
      const user = doc.data();
      const token = user.fcmToken;
      if (!token) continue;

      const offsetMinutes = user.timezoneOffsetMinutes ?? 0;
      const localTime = localTimeString(utcTotalMinutes, offsetMinutes);
      const notifTimes = user.notificationTimes ?? {};

      // Work with mutable copies of the user's rotation state.
      const seenMessageIds = { ...( user.seenMessageIds ?? {}) };
      const todayAssigned = { ...(user.todayAssigned ?? {}) };

      for (const slot of slots) {
        // Free tier: morning W only.
        if (slot !== 'morning' && !user.isPremium) continue;
        if (notifTimes[slot] !== localTime) continue;
        if (allMessages[slot].length === 0) continue;

        let msg;
        let needsFirestoreUpdate = false;

        if (todayAssigned.date === today && todayAssigned[slot]) {
          // Already assigned today — reuse the same message (idempotent).
          msg = allMessages[slot].find((m) => m.id === todayAssigned[slot]);
          if (!msg) {
            // Assigned ID no longer active — pick a fresh one.
            const result = pickUnseen(allMessages[slot], seenMessageIds[slot] ?? []);
            msg = result.msg;
            seenMessageIds[slot] = result.newSeenIds;
            todayAssigned.date = today;
            todayAssigned[slot] = msg.id;
            needsFirestoreUpdate = true;
          }
        } else {
          // New day or first assignment for this slot — pick an unseen message.
          if (todayAssigned.date !== today) {
            // Clear stale slot assignments from yesterday.
            Object.keys(todayAssigned).forEach((k) => { if (k !== 'date') delete todayAssigned[k]; });
            todayAssigned.date = today;
          }
          const result = pickUnseen(allMessages[slot], seenMessageIds[slot] ?? []);
          msg = result.msg;
          seenMessageIds[slot] = result.newSeenIds;
          todayAssigned[slot] = msg.id;
          needsFirestoreUpdate = true;
        }

        if (needsFirestoreUpdate) {
          userDocUpdates.push({ docRef: doc.ref, data: { seenMessageIds, todayAssigned } });
        }

        const groupKey = `${slot}:${msg.id}`;
        if (!groups[groupKey]) groups[groupKey] = { slot, msg, tokens: [] };
        groups[groupKey].tokens.push(token);

        break; // one notification per firing
      }
    }

    // ── Flush Firestore updates in batches of 500 ────────────────────────
    for (let i = 0; i < userDocUpdates.length; i += 500) {
      const batch = db.batch();
      userDocUpdates.slice(i, i + 500).forEach(({ docRef, data }) => {
        batch.update(docRef, data);
      });
      await batch.commit();
    }

    // ── Send FCM multicast per (slot, message) group ─────────────────────
    const sendPromises = [];

    for (const { slot, msg, tokens } of Object.values(groups)) {
      if (tokens.length === 0) continue;

      const slotLabel = slot.charAt(0).toUpperCase() + slot.slice(1);
      const title = `${slotLabel} W 💪`;
      const body = msg.text;

      logger.info(`Sending ${slot} W to ${tokens.length} device(s) (msg: ${msg.id}).`);

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
