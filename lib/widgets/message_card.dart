import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_w_message.dart';
import '../theme/app_theme.dart';

// ── Archetype badge config ────────────────────────────────────────────────────
// Each entry: (emoji, label, color)
const _archetypeMap = <String, (String, String, Color)>{
  'reverse_psychology': ('🧢', 'No cap', Color(0xFF7C3AED)),
  'fake_permission':    ('✅', 'Permission granted', Color(0xFF10B981)),
  'drill_sergeant':     ('💪', 'No excuses', Color(0xFFEF4444)),
  'chill_friend':       ('🌊', 'Chill vibes', Color(0xFF3B82F6)),
  'absurdist':          ('😤', 'Unhinged fr', Color(0xFFF59E0B)),
  'honest_friend':      ('💯', 'Real talk', Color(0xFFEC4899)),
  'hype_coach':         ('🔥', 'Slay', Color(0xFFE94560)),
  'deadpan':            ('💀', 'Facts', Color(0xFF8892A4)),
  'chaotic_good':       ('⚡', 'Main character', Color(0xFFF97316)),
  'tough_love':         ('😤', 'Tough love', Color(0xFFEF4444)),
  'sarcastic':          ('🙃', 'Lowkey tho', Color(0xFF7C3AED)),
  'motivational':       ('🚀', 'Let\'s go', Color(0xFF10B981)),
};

(String, String, Color) _badgeFor(String archetype) =>
    _archetypeMap[archetype] ??
    _archetypeMap[archetype.toLowerCase()] ??
    ('✨', archetype.replaceAll('_', ' '), AppTheme.accent);

// ── Widget ───────────────────────────────────────────────────────────────────

class MessageCard extends StatefulWidget {
  final DailyWMessage message;
  final bool isFavorited;
  final VoidCallback onFavoriteToggle;
  final VoidCallback? onLike;
  final VoidCallback? onDislike;

  const MessageCard({
    super.key,
    required this.message,
    required this.isFavorited,
    required this.onFavoriteToggle,
    this.onLike,
    this.onDislike,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnim;

  bool _liked = false;
  bool _disliked = false;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _pop() =>
      _popController.forward().then((_) => _popController.reverse());

  void _onLike() {
    if (_liked || _disliked) return;
    setState(() => _liked = true);
    _pop();
    widget.onLike?.call();
  }

  void _onDislike() {
    if (_liked || _disliked) return;
    setState(() => _disliked = true);
    widget.onDislike?.call();
  }

  void _onShare() {
    Share.share(
      '💬 ${widget.message.text}\n\n— Daily W',
      subject: 'Your Daily W',
    );
  }

  @override
  Widget build(BuildContext context) {
    final (badgeEmoji, badgeLabel, badgeColor) =
        _badgeFor(widget.message.archetype);

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.18),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Archetype badge ─────────────────────────────────────────
            _ArchetypeBadge(
              emoji: badgeEmoji,
              label: badgeLabel,
              color: badgeColor,
            ),

            const SizedBox(height: 18),

            // ── Message text (emoji-aware) ───────────────────────────────
            Text(
              widget.message.text,
              style: Theme.of(context).textTheme.displayMedium,
            ),

            const SizedBox(height: 26),

            // ── Action row ───────────────────────────────────────────────
            Row(
              children: [
                // W! button
                _ReactionButton(
                  emoji: '🤍',
                  label: 'W!',
                  activeEmoji: '❤️',
                  activeLabel: 'W!',
                  isActive: _liked,
                  isDisabled: _disliked,
                  activeColor: AppTheme.accent,
                  onTap: _onLike,
                ),
                const SizedBox(width: 8),
                // Nah button
                _ReactionButton(
                  emoji: '👎',
                  label: 'Nah',
                  activeEmoji: '👎',
                  activeLabel: 'Nah',
                  isActive: _disliked,
                  isDisabled: _liked,
                  activeColor: AppTheme.mutedText,
                  onTap: _onDislike,
                ),
                const Spacer(),
                // Save
                _IconAction(
                  icon: widget.isFavorited
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: widget.isFavorited
                      ? const Color(0xFFFFC107)
                      : AppTheme.mutedText,
                  tooltip: widget.isFavorited ? 'Saved' : 'Save',
                  onTap: widget.onFavoriteToggle,
                ),
                const SizedBox(width: 4),
                // Share
                _IconAction(
                  icon: Icons.ios_share_outlined,
                  color: AppTheme.mutedText,
                  tooltip: 'Share',
                  onTap: _onShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _ArchetypeBadge extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;

  const _ArchetypeBadge({
    required this.emoji,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final String activeEmoji;
  final String activeLabel;
  final bool isActive;
  final bool isDisabled;
  final Color activeColor;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.label,
    required this.activeEmoji,
    required this.activeLabel,
    required this.isActive,
    required this.isDisabled,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        isActive ? activeColor : AppTheme.mutedText.withValues(alpha: 0.7);
    final bgColor = isActive
        ? activeColor.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.04);
    final borderColor = isActive
        ? activeColor.withValues(alpha: 0.4)
        : AppTheme.mutedText.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: (isActive || isDisabled) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isActive ? activeEmoji : emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 6),
            Text(
              isActive ? activeLabel : label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
