import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_w_message.dart';

class MessageService {
  final FirebaseFirestore _db;

  MessageService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('messages');

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Returns the time slot name for the current hour.
  ///   06:00–11:59 → 'morning'
  ///   12:00–17:59 → 'afternoon'
  ///   18:00–05:59 → 'evening'
  static String getCurrentSlot() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    return 'evening';
  }

  static String _todayLocal() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Returns today's W for [slot] for the given user, using per-user rotation.
  ///
  /// Tracks seen message IDs in the user's Firestore doc under `seenMessageIds.{slot}`.
  /// Once all messages for a slot are seen, resets and starts over.
  /// Stores today's assignment under `todayAssigned.{slot}` so repeated calls
  /// within the same day return the same message.
  Future<DailyWMessage?> getOrAssignTodaysMessage(
      String slot, String uid) async {
    final today = _todayLocal();
    final userRef = _users.doc(uid);

    final userDoc = await userRef.get();
    final userData = userDoc.data() ?? {};

    final todayAssigned =
        Map<String, dynamic>.from(userData['todayAssigned'] as Map? ?? {});
    final seenMessageIds =
        Map<String, dynamic>.from(userData['seenMessageIds'] as Map? ?? {});
    final seenForSlot =
        List<String>.from(seenMessageIds[slot] as List? ?? []);

    // If already assigned today, return that message.
    if (todayAssigned['date'] == today && todayAssigned[slot] != null) {
      final msg = await getMessageById(todayAssigned[slot] as String);
      if (msg != null) return msg;
      // Assigned message no longer active — fall through to pick a new one.
    }

    // Fetch all active messages for this slot.
    final snap = await _messages
        .where('slot', isEqualTo: slot)
        .where('active', isEqualTo: true)
        .get();
    if (snap.docs.isEmpty) return null;

    final allMessages =
        snap.docs.map((d) => DailyWMessage.fromMap(d.data(), d.id)).toList();

    // Filter out seen ones; reset if all have been seen.
    var pool = allMessages.where((m) => !seenForSlot.contains(m.id)).toList();
    final didReset = pool.isEmpty;
    if (didReset) pool = List<DailyWMessage>.from(allMessages);

    pool.shuffle();
    final picked = pool.first;
    final newSeenIds = didReset ? [picked.id] : [...seenForSlot, picked.id];

    // Clear stale slot keys when it's a new day.
    final newAssigned = <String, dynamic>{};
    if (todayAssigned['date'] == today) {
      newAssigned.addAll(todayAssigned);
    }
    newAssigned['date'] = today;
    newAssigned[slot] = picked.id;

    seenMessageIds[slot] = newSeenIds;

    await userRef.update({
      'todayAssigned': newAssigned,
      'seenMessageIds': seenMessageIds,
    });

    return picked;
  }

  /// Records a like or dislike reaction on a message.
  Future<void> recordReaction(String messageId, bool isLike) async {
    final field = isLike ? 'likeCount' : 'dislikeCount';
    try {
      await _messages
          .doc(messageId)
          .update({field: FieldValue.increment(1)});
    } catch (_) {
      // Silently swallow — reaction counts are non-critical.
    }
  }

  /// Fetches a single message by its Firestore document ID.
  /// Returns null if the document doesn't exist.
  Future<DailyWMessage?> getMessageById(String id) async {
    final doc = await _messages.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return DailyWMessage.fromMap(doc.data()!, doc.id);
  }

  /// Fetches full message documents for a list of [ids] (used for favorites).
  Future<List<DailyWMessage>> getFavorites(List<String> ids) async {
    if (ids.isEmpty) return [];
    final docs = await Future.wait(ids.map((id) => _messages.doc(id).get()));
    return docs
        .where((d) => d.exists && d.data() != null)
        .map((d) => DailyWMessage.fromMap(d.data()!, d.id))
        .toList();
  }

  /// Returns messages from the last [days] days (free tier: 3, premium: unlimited).
  Future<List<DailyWMessage>> getHistory({int days = 3}) async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .toUtc()
        .toIso8601String();

    final snap = await _messages
        .where('active', isEqualTo: true)
        .where('scheduledDate', isGreaterThanOrEqualTo: cutoff)
        .orderBy('scheduledDate', descending: true)
        .get();

    return snap.docs
        .map((d) => DailyWMessage.fromMap(d.data(), d.id))
        .toList();
  }
}
