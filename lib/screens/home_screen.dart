import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';
import '../models/user_profile.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/message_card.dart';
import '../widgets/slot_badge.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  /// Pre-loaded from main() (returning users) or onboarding (new users).
  /// When provided, the screen renders immediately without any loading state.
  final UserProfile? initialProfile;
  final DailyWMessage? preloadedMessage;

  const HomeScreen({
    super.key,
    this.initialProfile,
    this.preloadedMessage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _userService = UserService();
  final _messageService = MessageService();

  UserProfile? _profile;
  DailyWMessage? _message;
  bool _loading = true;
  String? _error;

  String get _currentSlot => MessageService.getCurrentSlot();

  @override
  void initState() {
    super.initState();
    if (widget.initialProfile != null) {
      // Data was pre-loaded — skip all async work and render instantly.
      _profile = widget.initialProfile;
      _message = widget.preloadedMessage;
      _loading = false;
    } else {
      _initialize();
    }
  }

  Future<void> _initialize() async {
    try {
      final profile = await _userService.signInAndLoad();
      final message = await _messageService.getTodaysMessage(_currentSlot);
      if (mounted) {
        setState(() {
          _profile = profile;
          _message = message;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = e.toString(); });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_profile == null || _message == null) return;
    final updated = await _userService.toggleFavorite(
      _profile!.uid,
      _message!.id,
      _profile!.favoriteMessageIds,
    );
    setState(() {
      _profile = _profile!.copyWith(favoriteMessageIds: updated);
    });
  }

  void _onLike() {
    if (_message == null) return;
    _messageService.recordReaction(_message!.id, true);
  }

  void _onDislike() {
    if (_message == null) return;
    _messageService.recordReaction(_message!.id, false);
  }

  bool get _isFavorited =>
      _profile?.favoriteMessageIds.contains(_message?.id) ?? false;

  Future<void> _openSettings() async {
    if (_profile == null) return;
    final updated = await Navigator.push<UserProfile>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(profile: _profile!),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _profile = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _TopBar(isPremium: _profile?.isPremium ?? false),
              const SizedBox(height: 40),
              _body(),
              const SizedBox(height: 40),
              _BottomBar(
                profile: _profile,
                onSettingsTap: _openSettings,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Expanded(child: _LoadingCard());
    if (_error != null) return Expanded(child: _ErrorCard(error: _error!));
    if (_message == null) return const Expanded(child: _EmptyCard());

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SlotBadge(timeSlot: _currentSlot),
          const SizedBox(height: 20),
          MessageCard(
            message: _message!,
            isFavorited: _isFavorited,
            onFavoriteToggle: _toggleFavorite,
            onLike: _onLike,
            onDislike: _onDislike,
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final bool isPremium;
  const _TopBar({required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Daily W',
          style: TextStyle(
            color: AppTheme.cardFg,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const Spacer(),
        if (!isPremium)
          _PremiumButton()
        else
          const Icon(Icons.workspace_premium,
              color: Color(0xFFFFC107), size: 22),
      ],
    );
  }
}

class _PremiumButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium coming soon!')),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE94560), Color(0xFFFF6B8A)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Get Premium',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Bottom bar ────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback onSettingsTap;
  const _BottomBar({required this.profile, required this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _NavIcon(
          icon: Icons.settings_outlined,
          label: 'Settings',
          onTap: onSettingsTap,
        ),
        const Spacer(),
        _NavIcon(
          icon: Icons.person_outline,
          label: 'Profile',
          onTap: () {
            // TODO: open profile / favorites / streaks
          },
        ),
      ],
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppTheme.mutedText, size: 24),
        ),
      ),
    );
  }
}

// ── State cards ───────────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'Loading your W...',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.mutedText),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.15),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_outlined,
                color: AppTheme.mutedText, size: 36),
            const SizedBox(height: 16),
            Text(
              'No W yet for this slot.',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontSize: 18,
                    color: AppTheme.mutedText,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Come back soon.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                color: AppTheme.mutedText, size: 36),
            const SizedBox(height: 16),
            Text(
              'Something went wrong.',
              style: Theme.of(context)
                  .textTheme
                  .displayMedium
                  ?.copyWith(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
