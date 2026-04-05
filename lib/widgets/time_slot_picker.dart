import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays a single labelled time slider for a notification slot.
/// [hour] is a double (e.g. 8.5 = 8:30 AM). The range and 30-min
/// divisions are configured per slot by the caller.
class TimeSlotPicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final double hour;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const TimeSlotPicker({
    super.key,
    required this.icon,
    required this.label,
    required this.hour,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.cardFg,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                hourToDisplay(hour),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accent,
              inactiveTrackColor: AppTheme.accent.withValues(alpha: 0.18),
              thumbColor: AppTheme.accent,
              overlayColor: AppTheme.accent.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: hour,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared time helpers ───────────────────────────────────────────────────────

/// Converts a fractional hour (e.g. 13.5) to a display string ("1:30 PM").
String hourToDisplay(double hour) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  final period = h < 12 ? 'AM' : 'PM';
  final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$displayH:${m.toString().padLeft(2, '0')} $period';
}

/// Converts a fractional hour to a 24-hour storage string ("13:30").
String hourToStorage(double hour) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// Converts a storage string ("13:30") back to a fractional hour (13.5).
double storageToHour(String stored) {
  final parts = stored.split(':');
  if (parts.length != 2) return 0;
  final h = int.tryParse(parts[0]) ?? 0;
  final m = int.tryParse(parts[1]) ?? 0;
  return h + m / 60.0;
}
