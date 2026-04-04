class UserProfile {
  final String uid;
  final String? nickname;
  final String tonePreference; // 'sarcastic' | 'chill' | 'chaotic'
  final TimeOfDayPreference notificationTime;
  final bool isPremium;
  final int streakCount;
  final List<String> favoriteMessageIds;

  const UserProfile({
    required this.uid,
    this.nickname,
    this.tonePreference = 'sarcastic',
    this.notificationTime = TimeOfDayPreference.morning,
    this.isPremium = false,
    this.streakCount = 0,
    this.favoriteMessageIds = const [],
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      nickname: map['nickname'] as String?,
      tonePreference: map['tonePreference'] as String? ?? 'sarcastic',
      notificationTime: TimeOfDayPreference.values.firstWhere(
        (e) => e.name == (map['notificationTime'] as String? ?? 'morning'),
        orElse: () => TimeOfDayPreference.morning,
      ),
      isPremium: map['isPremium'] as bool? ?? false,
      streakCount: map['streakCount'] as int? ?? 0,
      favoriteMessageIds: List<String>.from(map['favoriteMessageIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'tonePreference': tonePreference,
        'notificationTime': notificationTime.name,
        'isPremium': isPremium,
        'streakCount': streakCount,
        'favoriteMessageIds': favoriteMessageIds,
      };

  UserProfile copyWith({
    String? nickname,
    String? tonePreference,
    TimeOfDayPreference? notificationTime,
    bool? isPremium,
    int? streakCount,
    List<String>? favoriteMessageIds,
  }) {
    return UserProfile(
      uid: uid,
      nickname: nickname ?? this.nickname,
      tonePreference: tonePreference ?? this.tonePreference,
      notificationTime: notificationTime ?? this.notificationTime,
      isPremium: isPremium ?? this.isPremium,
      streakCount: streakCount ?? this.streakCount,
      favoriteMessageIds: favoriteMessageIds ?? this.favoriteMessageIds,
    );
  }
}

enum TimeOfDayPreference { morning, afternoon, evening }
