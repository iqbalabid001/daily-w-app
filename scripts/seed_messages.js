/**
 * Daily W — Firestore seed script
 *
 * Prerequisites:
 *   1. Download a service account key from Firebase Console:
 *      Project Settings → Service Accounts → Generate new private key
 *   2. Save the downloaded JSON as:
 *      daily_w/scripts/serviceAccountKey.json
 *   3. Run: node scripts/seed_messages.js
 *
 * The script is idempotent — re-running with RESET=true clears existing
 * messages first. Each slot gets 10 messages. The first message in each
 * slot gets today's date so it is selected immediately by the app query;
 * the remaining 9 are backlogged on earlier dates.
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  projectId: 'daily-w-f4cf6',
});

const db = admin.firestore();

// ── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Returns an ISO date string for [daysAgo] days before today at [hour] UTC.
 */
function scheduleDate(daysAgo, hour) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - daysAgo);
  d.setUTCHours(hour, 0, 0, 0);
  return d.toISOString();
}

// ── Message bank ──────────────────────────────────────────────────────────────
// daysAgo: 0 = today (shows in app), 1–9 = backlog (older, won't show yet)

const MESSAGES = [

  // ── MORNING (slot: morning, UTC hour: 8) ──────────────────────────────────
  {
    text: "Yeah, skip it. You've skipped harder things before.",
    slot: 'morning', archetype: 'reverse_psychology',
    tone: 'sarcastic', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(0, 8),   // today → shows now
  },
  {
    text: 'Look at you. Functioning. Iconic.',
    slot: 'morning', archetype: 'mock_confidence',
    tone: 'playful', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(1, 8),
  },
  {
    text: "Today's still open. Not forever though.",
    slot: 'morning', archetype: 'deadline_reminder',
    tone: 'calm', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(2, 8),
  },
  {
    text: 'Stay comfortable. Growth can wait.',
    slot: 'morning', archetype: 'reverse_psychology',
    tone: 'sarcastic', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(3, 8),
  },
  {
    text: "You could give up now. No one's stopping you.",
    slot: 'morning', archetype: 'fake_permission',
    tone: 'sarcastic', humor_style: 'dark',
    active: true, scheduledDate: scheduleDate(4, 8),
  },
  {
    text: 'Wow. Effort. We love to see it.',
    slot: 'morning', archetype: 'mock_confidence',
    tone: 'playful', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(5, 8),
  },
  {
    text: "Do it. Or don't. I'm not your life coach.",
    slot: 'morning', archetype: 'anti_motivation',
    tone: 'indifferent', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(6, 8),
  },
  {
    text: "You've handled worse days than this.",
    slot: 'morning', archetype: 'quiet_confidence',
    tone: 'sincere', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(7, 8),
  },
  {
    text: 'Not perfect. Still showed up. Annoyingly impressive.',
    slot: 'morning', archetype: 'backhanded_compliment',
    tone: 'playful', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(8, 8),
  },
  {
    text: "Go ahead. Lower the bar. It's fine.",
    slot: 'morning', archetype: 'fake_permission',
    tone: 'sarcastic', humor_style: 'dark',
    active: true, scheduledDate: scheduleDate(9, 8),
  },

  // ── AFTERNOON (slot: afternoon, UTC hour: 13) ─────────────────────────────
  {
    text: "Interesting choice. Let's see how this plays out.",
    slot: 'afternoon', archetype: 'gentle_callout',
    tone: 'dry', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(0, 13),  // today → shows now
  },
  {
    text: "You don't have all day. You have some time.",
    slot: 'afternoon', archetype: 'deadline_reminder',
    tone: 'calm', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(1, 13),
  },
  {
    text: 'No pressure. Just your future quietly watching.',
    slot: 'afternoon', archetype: 'anti_motivation',
    tone: 'indifferent', humor_style: 'dark',
    active: true, scheduledDate: scheduleDate(2, 13),
  },
  {
    text: "This isn't everything. It's just today.",
    slot: 'afternoon', archetype: 'reality_check',
    tone: 'grounded', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(3, 13),
  },
  {
    text: "That's one way to handle it, I guess.",
    slot: 'afternoon', archetype: 'gentle_callout',
    tone: 'dry', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(4, 13),
  },
  {
    text: 'Somehow still standing. Respect.',
    slot: 'afternoon', archetype: 'backhanded_compliment',
    tone: 'playful', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(5, 13),
  },
  {
    text: 'One decent choice is enough right now.',
    slot: 'afternoon', archetype: 'reality_check',
    tone: 'grounded', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(6, 13),
  },
  {
    text: "You know what to do. You're just waiting for permission. Granted.",
    slot: 'afternoon', archetype: 'fake_permission',
    tone: 'playful', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(7, 13),
  },
  {
    text: 'Half the day gone. Half still yours.',
    slot: 'afternoon', archetype: 'deadline_reminder',
    tone: 'calm', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(8, 13),
  },
  {
    text: "Keep going. Or don't. Results may vary.",
    slot: 'afternoon', archetype: 'anti_motivation',
    tone: 'indifferent', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(9, 13),
  },

  // ── EVENING (slot: evening, UTC hour: 20) ────────────────────────────────
  {
    text: 'You can stop for today. Tomorrow still exists.',
    slot: 'evening', archetype: 'permission_to_rest',
    tone: 'soft', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(0, 20),  // today → shows now
  },
  {
    text: "Rest isn't quitting. It's reloading.",
    slot: 'evening', archetype: 'permission_to_rest',
    tone: 'calm', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(1, 20),
  },
  {
    text: 'This isn\'t new. You know how to do hard.',
    slot: 'evening', archetype: 'quiet_confidence',
    tone: 'sincere', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(2, 20),
  },
  {
    text: 'Not perfect. Still showed up. That counts.',
    slot: 'evening', archetype: 'backhanded_compliment',
    tone: 'warm', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(3, 20),
  },
  {
    text: 'You made it through. Quietly impressive.',
    slot: 'evening', archetype: 'backhanded_compliment',
    tone: 'warm', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(4, 20),
  },
  {
    text: 'Today happened. You were in it. W.',
    slot: 'evening', archetype: 'mock_confidence',
    tone: 'playful', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(5, 20),
  },
  {
    text: 'Close enough. Try again tomorrow.',
    slot: 'evening', archetype: 'reality_check',
    tone: 'grounded', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(6, 20),
  },
  {
    text: "You did some things. That's more than nothing.",
    slot: 'evening', archetype: 'gentle_callout',
    tone: 'dry', humor_style: 'deadpan',
    active: true, scheduledDate: scheduleDate(7, 20),
  },
  {
    text: 'Recharge. Tomorrow needs you slightly less tired.',
    slot: 'evening', archetype: 'permission_to_rest',
    tone: 'soft', humor_style: 'dry',
    active: true, scheduledDate: scheduleDate(8, 20),
  },
  {
    text: 'Good enough is good enough today. Rest.',
    slot: 'evening', archetype: 'permission_to_rest',
    tone: 'warm', humor_style: 'none',
    active: true, scheduledDate: scheduleDate(9, 20),
  },
];

// ── Seed ──────────────────────────────────────────────────────────────────────

async function clearMessages() {
  console.log('Clearing existing messages...');
  const snap = await db.collection('messages').get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.docs.forEach(d => batch.delete(d.ref));
  await batch.commit();
  console.log(`  Deleted ${snap.size} existing documents.`);
}

async function seed() {
  if (process.env.RESET === 'true') await clearMessages();

  // Firestore batch limit is 500; 30 messages is well within that.
  const batch = db.batch();
  for (const msg of MESSAGES) {
    const ref = db.collection('messages').doc();
    batch.set(ref, msg);
  }
  await batch.commit();

  const bySlot = MESSAGES.reduce((acc, m) => {
    acc[m.slot] = (acc[m.slot] || 0) + 1;
    return acc;
  }, {});

  console.log(`\nSeeded ${MESSAGES.length} messages:`);
  Object.entries(bySlot).forEach(([slot, count]) =>
    console.log(`  ${slot}: ${count}`)
  );
  const slotHour = { morning: 8, afternoon: 13, evening: 20 };
  console.log('\nToday\'s active messages (will show in app now):');
  MESSAGES.filter(m => m.scheduledDate === scheduleDate(0, slotHour[m.slot]))
    .forEach(m => console.log(`  [${m.slot}] "${m.text.slice(0, 55)}"`));
  console.log('\nDone.');
}

seed()
  .then(() => process.exit(0))
  .catch(e => { console.error(e); process.exit(1); });
