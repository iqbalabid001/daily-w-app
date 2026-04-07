import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  UserService({FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  /// Returns today's date as 'YYYY-MM-DD' in device local time.
  static String _today() {
    final now = DateTime.now();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}-$m-$d';
  }

  /// Computes the new streak given the stored streak and last-opened date.
  ///
  /// Returns `(newStreak, changed)`.
  /// - Same day → (current, false) — idempotent, no Firestore write needed.
  /// - Yesterday → (current + 1, true) — consecutive day.
  /// - Gap > 1 day / never opened before → (1, true) — reset.
  static (int, bool) _computeStreak(int current, String? lastDate, String today) {
    if (lastDate == null) return (1, true);          // first ever open
    if (lastDate == today) return (current, false);  // already opened today

    final last = DateTime.parse(lastDate);
    final diff = DateTime.parse(today).difference(last).inDays;
    if (diff == 1) return (current + 1, true);       // consecutive day ✓
    return (1, true);                                 // missed ≥ 1 day → reset
  }

  /// Signs in anonymously if no session exists, creates the Firestore user
  /// document for first-time users, and updates the streak on every open.
  /// Returns the fully resolved (and streak-updated) profile.
  Future<UserProfile> signInAndLoad() async {
    // 1. Ensure we have a Firebase Auth user.
    final authUser =
        _auth.currentUser ?? (await _auth.signInAnonymously()).user!;

    final today = _today();

    // 2. Try to load existing profile.
    final doc = await _users.doc(authUser.uid).get();
    if (doc.exists && doc.data() != null) {
      var profile = UserProfile.fromMap(doc.data()!, authUser.uid);

      final (newStreak, changed) =
          _computeStreak(profile.streakCount, profile.lastOpenedDate, today);

      final updates = <String, dynamic>{
        'lastOpenedAt': FieldValue.serverTimestamp(),
      };

      if (changed) {
        updates['streakCount'] = newStreak;
        updates['lastOpenedDate'] = today;
        profile = profile.copyWith(
          streakCount: newStreak,
          lastOpenedDate: today,
        );
      }

      await _users.doc(authUser.uid).update(updates);
      return profile;
    }

    // 3. First-time user — create profile with streak = 1.
    final newProfile = UserProfile(
      uid: authUser.uid,
      streakCount: 1,
      lastOpenedDate: today,
    );
    await _users.doc(authUser.uid).set({
      ...newProfile.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastOpenedAt': FieldValue.serverTimestamp(),
    });
    return newProfile;
  }

  /// Saves (merges) any profile changes back to Firestore.
  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Toggles [messageId] in the user's favoriteMessageIds array.
  /// Returns the updated list of favorites.
  Future<List<String>> toggleFavorite(
      String uid, String messageId, List<String> current) async {
    final isFav = current.contains(messageId);
    await _users.doc(uid).update({
      'favoriteMessageIds': isFav
          ? FieldValue.arrayRemove([messageId])
          : FieldValue.arrayUnion([messageId]),
    });
    return isFav
        ? (List<String>.from(current)..remove(messageId))
        : [...current, messageId];
  }

  /// Saves the FCM token and current device timezone offset.
  /// Called on every app launch so stale tokens and timezone shifts are
  /// caught automatically.
  Future<void> saveToken(
      String uid, String token, int timezoneOffsetMinutes) async {
    try {
      await _users.doc(uid).update({
        'fcmToken': token,
        'timezoneOffsetMinutes': timezoneOffsetMinutes,
      });
    } catch (_) {
      // Non-critical — notifications simply won't fire until next launch.
    }
  }
}
