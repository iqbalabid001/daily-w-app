import 'package:flutter/material.dart';

/// Small badge showing the current time slot (Morning / Afternoon / Evening W).
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
        _ => Icons.star_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, size: 14, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(_label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
