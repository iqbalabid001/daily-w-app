import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';
import '../models/user_profile.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile profile;
  const ProfileScreen({super.key, required this.profile});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _messageService = MessageService();
  List<DailyWMessage>? _favorites;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favs = await _messageService
          .getFavorites(widget.profile.favoriteMessageIds);
      if (mounted) setState(() { _favorites = favs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _favorites = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.cardFg, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.cardFg,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + name ───────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          width: 2),
                    ),
                    child: Center(
                      child: Text(
                        profile.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.displayName,
                    style: const TextStyle(
                      color: AppTheme.cardFg,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (profile.isPremium) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.workspace_premium,
                              color: Color(0xFFFFC107), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Stats row ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Streak',
                    value: '${profile.streakCount}',
                    unit: profile.streakCount == 1 ? 'day' : 'days',
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.star_outline,
                    label: 'Saved',
                    value: '${profile.favoriteMessageIds.length}',
                    unit: profile.favoriteMessageIds.length == 1
                        ? 'W'
                        : 'W\'s',
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ── Favorites ───────────────────────────────────────────────
            const _SectionHeader(
                icon: Icons.star_outline, label: 'Saved W\'s'),
            const SizedBox(height: 12),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(
                      color: AppTheme.accent, strokeWidth: 2),
                ),
              )
            else if (_favorites == null || _favorites!.isEmpty)
              _EmptyFavorites()
            else
              Column(
                children: _favorites!
                    .map((msg) => _FavoriteCard(message: msg))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: color,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  final DailyWMessage message;
  const _FavoriteCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: const Color(0xFFFFC107).withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: const TextStyle(
              color: AppTheme.cardFg,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _slotIcon(message.slot),
                size: 12,
                color: AppTheme.mutedText,
              ),
              const SizedBox(width: 4),
              Text(
                '${_capitalize(message.slot)} W',
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _slotIcon(String slot) => switch (slot) {
        'morning' => Icons.wb_sunny_outlined,
        'afternoon' => Icons.bolt_outlined,
        _ => Icons.nightlight_outlined,
      };

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

class _EmptyFavorites extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppTheme.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star_border,
              color: AppTheme.mutedText, size: 32),
          const SizedBox(height: 12),
          const Text(
            'No saved W\'s yet.',
            style: TextStyle(
              color: AppTheme.cardFg,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap ⭐ on a message to save it here.',
            style: TextStyle(
              color: AppTheme.mutedText,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
