import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SlotBadge extends StatelessWidget {
  final String timeSlot; // 'morning' | 'afternoon' | 'evening'

  const SlotBadge({super.key, required this.timeSlot});

  String get _label => switch (timeSlot) {
        'morning' => 'Morning W',
        'afternoon' => 'Afternoon W',
        'evening' => 'Evening W',
        _ => 'Daily W',
      };

  IconData get _icon => switch (timeSlot) {
        'morning' => Icons.wb_sunny_outlined,
        'afternoon' => Icons.bolt_outlined,
        'evening' => Icons.nightlight_outlined,
        _ => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: AppTheme.accent),
          const SizedBox(width: 5),
          Text(
            _label,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
