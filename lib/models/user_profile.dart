class UserProfile {
  final String uid;
  final String? nickname;
  final String tonePreference; // 'sarcastic' | 'tough_love' | 'chill'
  final bool isPremium;
  final int streakCount;
  final List<String> favoriteMessageIds;
  final bool onboardingComplete;
  // Per-slot notification times stored as 'HH:mm' strings (24-hour)
  final Map<String, String> notificationTimes;

  const UserProfile({
    required this.uid,
    this.nickname,
    this.tonePreference = 'sarcastic',
    this.isPremium = false,
    this.streakCount = 0,
    this.favoriteMessageIds = const [],
    this.onboardingComplete = false,
    this.notificationTimes = const {
      'morning': '08:00',
      'afternoon': '13:00',
      'evening': '20:00',
    },
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    final rawTimes = map['notificationTimes'];
    final times = rawTimes is Map
        ? Map<String, String>.from(rawTimes)
        : const <String, String>{
            'morning': '08:00',
            'afternoon': '13:00',
            'evening': '20:00',
          };

    return UserProfile(
      uid: uid,
      nickname: map['nickname'] as String?,
      tonePreference: map['tonePreference'] as String? ?? 'sarcastic',
      isPremium: map['isPremium'] as bool? ?? false,
      streakCount: map['streakCount'] as int? ?? 0,
      favoriteMessageIds:
          List<String>.from(map['favoriteMessageIds'] ?? const []),
      onboardingComplete: map['onboardingComplete'] as bool? ?? false,
      notificationTimes: times,
    );
  }

  Map<String, dynamic> toMap() => {
        'nickname': nickname,
        'tonePreference': tonePreference,
        'isPremium': isPremium,
        'streakCount': streakCount,
        'favoriteMessageIds': favoriteMessageIds,
        'onboardingComplete': onboardingComplete,
        'notificationTimes': notificationTimes,
      };

  UserProfile copyWith({
    String? nickname,
    String? tonePreference,
    bool? isPremium,
    int? streakCount,
    List<String>? favoriteMessageIds,
    bool? onboardingComplete,
    Map<String, String>? notificationTimes,
  }) {
    return UserProfile(
      uid: uid,
      nickname: nickname ?? this.nickname,
      tonePreference: tonePreference ?? this.tonePreference,
      isPremium: isPremium ?? this.isPremium,
      streakCount: streakCount ?? this.streakCount,
      favoriteMessageIds: favoriteMessageIds ?? this.favoriteMessageIds,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      notificationTimes: notificationTimes ?? this.notificationTimes,
    );
  }
}
