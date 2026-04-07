import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';
import '../services/message_service.dart';
import '../theme/app_theme.dart';
import '../widgets/slot_badge.dart';

Future<void> showHistorySheet(
  BuildContext context, {
  required bool isPremium,
  required VoidCallback onUpgradeTap,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HistorySheet(
      isPremium: isPremium,
      onUpgradeTap: onUpgradeTap,
    ),
  );
}

class _HistorySheet extends StatefulWidget {
  final bool isPremium;
  final VoidCallback onUpgradeTap;

  const _HistorySheet({required this.isPremium, required this.onUpgradeTap});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  final _messageService = MessageService();
  List<DailyWMessage>? _messages;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final msgs = await _messageService.getHistory(
        days: widget.isPremium ? 365 : 3,
      );
      if (mounted) setState(() { _messages = msgs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _messages = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.70,
      minChildSize: 0.40,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.mutedText.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 18, color: AppTheme.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'History',
                    style: TextStyle(
                      color: AppTheme.cardFg,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  if (!widget.isPremium)
                    _UpgradeChip(onTap: () {
                      Navigator.pop(context);
                      widget.onUpgradeTap();
                    }),
                ],
              ),
            ),

            if (!widget.isPremium) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Showing last 3 days  •  Upgrade for unlimited',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: AppTheme.mutedText.withValues(alpha: 0.12),
            ),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.accent, strokeWidth: 2),
                    )
                  : (_messages == null || _messages!.isEmpty)
                      ? const _EmptyHistory()
                      : ListView.separated(
                          controller: controller,
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 40),
                          itemCount: _messages!.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (_, i) =>
                              _HistoryItem(message: _messages![i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _UpgradeChip extends StatelessWidget {
  final VoidCallback onTap;
  const _UpgradeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE94560), Color(0xFFFF6B8A)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Upgrade',
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final DailyWMessage message;
  const _HistoryItem({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SlotBadge(timeSlot: message.slot),
              const Spacer(),
              Text(
                _relativeDate(message.scheduledDate),
                style: const TextStyle(
                  color: AppTheme.mutedText,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.text,
            style: const TextStyle(
              color: AppTheme.cardFg,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeDate(DateTime scheduledDate) {
    final date = scheduledDate.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '$diff days ago';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, color: AppTheme.mutedText, size: 36),
          SizedBox(height: 12),
          Text(
            'No history yet.',
            style: TextStyle(
              color: AppTheme.cardFg,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Come back tomorrow.',
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
