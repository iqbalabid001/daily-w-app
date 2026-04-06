import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_w_message.dart';

class MessageService {
  final FirebaseFirestore _db;

  MessageService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('messages');

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

  /// Returns today's active message for [slot].
  /// Picks the most recently scheduled active document for that slot.
  Future<DailyWMessage?> getTodaysMessage(String slot) async {
    final snap = await _messages
        .where('slot', isEqualTo: slot)
        .where('active', isEqualTo: true)
        .orderBy('scheduledDate', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return DailyWMessage.fromMap(doc.data(), doc.id);
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
