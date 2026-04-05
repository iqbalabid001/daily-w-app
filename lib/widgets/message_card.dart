import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_w_message.dart';
import '../theme/app_theme.dart';

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

  // Track per-session reactions (no repeat taps)
  bool _liked = false;
  bool _disliked = false;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _pop() {
    _popController.forward().then((_) => _popController.reverse());
  }

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
      '"${widget.message.text}"\n\n— Daily W',
      subject: 'Your Daily W',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 24),
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
            // Message text
            Text(
              widget.message.text,
              style: Theme.of(context).textTheme.displayMedium,
            ),

            const SizedBox(height: 8),

            // Archetype label
            Text(
              _archetypeLabel(widget.message.archetype),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.accent.withValues(alpha: 0.7),
                    letterSpacing: 1.1,
                    fontSize: 11,
                  ),
            ),

            const SizedBox(height: 28),

            // Action row
            Row(
              children: [
                _ActionButton(
                  icon: _liked ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: _liked ? AppTheme.accent : AppTheme.mutedText,
                  onTap: _onLike,
                  tooltip: 'Like',
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: _disliked
                      ? Icons.thumb_down
                      : Icons.thumb_down_outlined,
                  color: _disliked ? AppTheme.mutedText : AppTheme.mutedText,
                  onTap: _onDislike,
                  tooltip: 'Not for me',
                ),
                const Spacer(),
                _ActionButton(
                  icon: widget.isFavorited ? Icons.star : Icons.star_border,
                  color: widget.isFavorited
                      ? const Color(0xFFFFC107)
                      : AppTheme.mutedText,
                  onTap: widget.onFavoriteToggle,
                  tooltip: widget.isFavorited ? 'Unfavorite' : 'Save',
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.ios_share_outlined,
                  color: AppTheme.mutedText,
                  onTap: _onShare,
                  tooltip: 'Share',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _archetypeLabel(String raw) {
    return raw.replaceAll('_', ' ').toUpperCase();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
