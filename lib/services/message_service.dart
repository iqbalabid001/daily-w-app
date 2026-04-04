import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/daily_w_message.dart';

class MessageService {
  final FirebaseFirestore _db;

  MessageService({FirebaseFirestore? db})
      : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _messages =>
      _db.collection('messages');

  /// Returns today's active message for [timeSlot] ('morning'|'afternoon'|'evening').
  Future<DailyWMessage?> getTodaysMessage(String timeSlot) async {
    final snap = await _messages
        .where('slot', isEqualTo: timeSlot)
        .where('active', isEqualTo: true)
        .orderBy('scheduledDate', descending: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return DailyWMessage.fromMap(doc.data(), doc.id);
  }

  /// Returns the last [days] days of messages for the history view (free: 3 days).
  Future<List<DailyWMessage>> getHistory({int days = 3}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _messages
        .where('active', isEqualTo: true)
        .where('scheduledDate',
            isGreaterThanOrEqualTo: cutoff.toIso8601String())
        .orderBy('scheduledDate', descending: true)
        .get();

    return snap.docs
        .map((d) => DailyWMessage.fromMap(d.data(), d.id))
        .toList();
  }
}
