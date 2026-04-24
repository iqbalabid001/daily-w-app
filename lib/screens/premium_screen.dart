import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/user_profile.dart';
import '../services/purchase_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Paywall screen — presents the RevenueCat paywall as a native Android Activity
/// via RevenueCatUI.presentPaywall(), avoiding the PlatformView/Compose context
/// crash that PaywallView (embedded widget) causes on Flutter.
///
/// Flow:
///   1. Show spinner while fetching offerings.
///   2. If offering found → launch native paywall activity, handle result.
///   3. If no offering / error → show fallback UI.
///
/// Returns an updated [UserProfile] (isPremium = true) on successful
/// purchase/restore, or null on dismiss.
class PremiumScreen extends StatefulWidget {
  final UserProfile profile;
  const PremiumScreen({super.key, required this.profile});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _userService = UserService();

  bool _loading = true;
  bool _processing = false;
  bool _restoring = false;
  String? _error; // set when offerings load fails or paywall errors

  @override
  void initState() {
    super.initState();
    _loadAndPresent();
  }

  Future<void> _loadAndPresent() async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.current;

      if (!mounted) return;

      if (offering == null) {
        // No offering configured in dashboard yet — show fallback.
        setState(() => _loading = false);
        return;
      }

      // Present the paywall as a native Android Activity — no PlatformView.
      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );

      if (!mounted) return;

      if (result == PaywallResult.purchased || result == PaywallResult.restored) {
        await _verifyAndPop();
      } else {
        // Cancelled or not presented — just close.
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('[PremiumScreen] error: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _verifyAndPop() async {
    setState(() => _processing = true);
    try {
      final info = await Purchases.getCustomerInfo();
      final isActive =
          info.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
      if (!isActive || !mounted) return;

      final updated = await _userService.setPremium(widget.profile, true);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Purchase succeeded! Restart the app if features haven\'t unlocked.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    try {
      final info = await Purchases.restorePurchases();
      await _verifyAndPop();
      if (mounted && _restoring) {
        // verifyAndPop didn't find the entitlement
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchase found.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 2),
        ),
      );
    }

    // Processing overlay (writing to Firestore after purchase).
    if (_processing) {
      return const Scaffold(
        backgroundColor: AppTheme.primary,
        body: Center(
          child: CircularProgressIndicator(
              color: AppTheme.accent, strokeWidth: 2),
        ),
      );
    }

    // Fallback — no offering configured or error loading.
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: AppTheme.cardFg),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.workspace_premium,
                          color: Color(0xFFFFC107), size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Daily W Pro',
                      style: TextStyle(
                        color: AppTheme.cardFg,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get more Ws, every single day.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.cardFg.withValues(alpha: 0.65),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _featureRow(Icons.wb_sunny_rounded,
                        'Afternoon W', 'A midday boost to keep you going'),
                    _featureRow(Icons.nightlight_round,
                        'Evening W', 'End the day on a high note'),
                    _featureRow(Icons.favorite_rounded,
                        'Unlimited Favorites', 'Save as many Ws as you want'),
                    _featureRow(Icons.history_rounded,
                        'Full History', 'Every W you\'ve ever received'),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.rocket_launch_rounded,
                              color: Color(0xFFFFC107), size: 28),
                          const SizedBox(height: 10),
                          const Text(
                            'Subscriptions launching soon',
                            style: TextStyle(
                              color: AppTheme.cardFg,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _error != null
                                ? 'Could not connect to the store.\nCheck your connection and try again.'
                                : 'Pricing isn\'t set up yet — check back soon\nor restore a previous purchase below.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.cardFg.withValues(alpha: 0.60),
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _restoring ? null : _restore,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppTheme.cardFg.withValues(alpha: 0.25)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _restoring
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    color: AppTheme.accent, strokeWidth: 2),
                              )
                            : Text(
                                'Restore Purchase',
                                style: TextStyle(
                                    color:
                                        AppTheme.cardFg.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppTheme.cardFg,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: AppTheme.cardFg.withValues(alpha: 0.55),
                        fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: Color(0xFFFFC107), size: 18),
        ],
      ),
    );
  }
}
