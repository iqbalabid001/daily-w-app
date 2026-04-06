import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.cardFg, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Icon + title ────────────────────────────────────────────
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.35),
                      width: 1.5),
                ),
                child: const Center(
                  child: Icon(Icons.workspace_premium,
                      color: Color(0xFFFFC107), size: 34),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Daily W Premium',
                style: TextStyle(
                  color: AppTheme.cardFg,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock the full W experience.',
                style: TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 36),

              // ── Feature list ────────────────────────────────────────────
              ..._features.map((f) => _FeatureRow(
                    icon: f.$1,
                    title: f.$2,
                    subtitle: f.$3,
                  )),

              const Spacer(),

              // ── CTA ─────────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFC107).withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Coming Soon',
                      style: TextStyle(
                        color: Color(0xFFFFC107),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Premium subscriptions are launching soon. Stay tuned for the full unlock.',
                      style: TextStyle(
                        color: AppTheme.mutedText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null, // disabled until RevenueCat ships
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          disabledBackgroundColor:
                              const Color(0xFFFFC107).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Notify Me When It Drops',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const _features = [
  (
    Icons.history,
    'Full Message History',
    'Free users get 3 days. Premium unlocks everything, forever.',
  ),
  (
    Icons.star_outline,
    'Unlimited Saved W\'s',
    'Save as many bangers as you want.',
  ),
  (
    Icons.tune,
    'More Tone Options',
    'Unlock extra archetypes beyond the core three.',
  ),
  (
    Icons.notifications_active_outlined,
    'Custom Notification Schedules',
    'Fine-tune delivery times down to the minute.',
  ),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.cardFg,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
