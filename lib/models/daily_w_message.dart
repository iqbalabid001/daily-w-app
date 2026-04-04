class DailyWMessage {
  final String id;
  final String text;
  final String slot;        // 'morning' | 'afternoon' | 'evening'
  final String archetype;   // e.g. 'reverse_psychology', 'fake_permission'
  final String tone;        // 'sarcastic' | 'chill' | 'chaotic'
  final String humorStyle;  // e.g. 'dry', 'absurd', 'deadpan'
  final bool active;
  final DateTime scheduledDate;

  const DailyWMessage({
    required this.id,
    required this.text,
    required this.slot,
    required this.archetype,
    required this.tone,
    required this.humorStyle,
    required this.active,
    required this.scheduledDate,
  });

  factory DailyWMessage.fromMap(Map<String, dynamic> map, String id) {
    return DailyWMessage(
      id: id,
      text: map['text'] as String,
      slot: map['slot'] as String,
      archetype: map['archetype'] as String,
      tone: map['tone'] as String,
      humorStyle: map['humor_style'] as String? ?? '',
      active: map['active'] as bool? ?? true,
      scheduledDate: DateTime.parse(map['scheduledDate'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
        'text': text,
        'slot': slot,
        'archetype': archetype,
        'tone': tone,
        'humor_style': humorStyle,
        'active': active,
        'scheduledDate': scheduledDate.toIso8601String(),
      };
}
