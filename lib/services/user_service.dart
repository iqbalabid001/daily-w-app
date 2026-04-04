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

  /// Signs in anonymously if no user is signed in yet.
  Future<User> signInAnonymously() async {
    if (_auth.currentUser != null) return _auth.currentUser!;
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  /// Returns the current user's profile from Firestore, or null.
  Future<UserProfile?> getCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!, uid);
  }

  /// Creates or fully overwrites the user's Firestore document.
  Future<void> saveProfile(UserProfile profile) async {
    await _users.doc(profile.uid).set(profile.toMap(), SetOptions(merge: true));
  }

  /// Adds or removes [messageId] from the user's favoriteMessageIds array.
  Future<void> toggleFavorite(String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _users.doc(uid).get();
    final favorites =
        List<String>.from(doc.data()?['favoriteMessageIds'] ?? []);

    final update = favorites.contains(messageId)
        ? FieldValue.arrayRemove([messageId])
        : FieldValue.arrayUnion([messageId]);

    await _users.doc(uid).update({'favoriteMessageIds': update});
  }

  /// Increments the user's streak counter by 1.
  Future<void> incrementStreak() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _users
        .doc(uid)
        .update({'streakCount': FieldValue.increment(1)});
  }
}
