import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays three tone option cards. Tapping one selects it.
/// [selected] is one of: 'sarcastic' | 'tough_love' | 'chill'
class TonePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TonePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _tones = [
    (
      value: 'sarcastic',
      label: 'Sarcastic & Witty',
      description: 'Dry humor, reverse psychology,\nplayful jabs',
      icon: Icons.sentiment_very_satisfied_outlined,
    ),
    (
      value: 'tough_love',
      label: 'Tough Love',
      description: 'Direct, no-nonsense,\nchallenges your excuses',
      icon: Icons.fitness_center_outlined,
    ),
    (
      value: 'chill',
      label: 'Chill & Calm',
      description: 'Gentle nudges, quiet confidence,\nlow pressure',
      icon: Icons.self_improvement_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _tones.map((t) {
        final isSelected = t.value == selected;
        return GestureDetector(
          onTap: () => onSelected(t.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withValues(alpha: 0.15)
                  : AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.accent
                    : AppTheme.accent.withValues(alpha: 0.15),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  t.icon,
                  color: isSelected ? AppTheme.accent : AppTheme.mutedText,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.label,
                        style: const TextStyle(
                          color: AppTheme.cardFg,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.description,
                        style: const TextStyle(
                          color: AppTheme.mutedText,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: AppTheme.accent, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
