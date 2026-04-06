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

  /// Signs in anonymously if no session exists, then creates the Firestore
  /// user document if this is a first-time user. Returns the resolved profile.
  Future<UserProfile> signInAndLoad() async {
    // 1. Ensure we have a Firebase Auth user
    final authUser = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;

    // 2. Try to load existing profile
    final doc = await _users.doc(authUser.uid).get();
    if (doc.exists && doc.data() != null) {
      // Returning user — touch lastOpenedAt and return
      await _users.doc(authUser.uid).update({
        'lastOpenedAt': FieldValue.serverTimestamp(),
      });
      return UserProfile.fromMap(doc.data()!, authUser.uid);
    }

    // 3. First-time user — create profile with defaults
    final newProfile = UserProfile(uid: authUser.uid);
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

  /// Increments the streak counter by 1.
  Future<void> incrementStreak(String uid) async {
    await _users.doc(uid).update({'streakCount': FieldValue.increment(1)});
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
