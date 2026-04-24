import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/user_profile.dart';
import '../services/purchase_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Full-screen paywall powered by RevenueCat Paywall UI.
///
/// Fetches offerings on load. If an offering is configured in the RevenueCat
/// dashboard, renders PaywallView. If not (common pre-launch), shows a
/// fallback UI so the screen is never blank or crashed.
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

  // null  = still loading
  // Offering = ready to show PaywallView
  // _noOffering sentinel = no offering available → show fallback
  Offering? _offering;
  bool _loadingOfferings = true;
  String? _offeringError;
  bool _processing = false;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _loadOffering();
  }

  Future<void> _loadOffering() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (!mounted) return;
      setState(() {
        _offering = offerings.current; // null if none configured
        _loadingOfferings = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingOfferings = false;
        _offeringError = e.toString();
      });
    }
  }

  Future<void> _handleSuccess(CustomerInfo customerInfo) async {
    final isActive =
        customerInfo.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
    if (!isActive || !mounted) return;

    setState(() => _processing = true);
    try {
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
      await _handleSuccess(info);
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
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Stack(
        children: [
          if (_loadingOfferings)
            _buildLoading()
          else if (_offering != null)
            _buildPaywall(_offering!)
          else
            _buildFallback(),

          if (_processing)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(
                child: CircularProgressIndicator(
                    color: AppTheme.accent, strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
    );
  }

  Widget _buildPaywall(Offering offering) {
    return PaywallView(
      offering: offering,
      displayCloseButton: true,
      onPurchaseCompleted: (customerInfo, transaction) =>
          _handleSuccess(customerInfo),
      onRestoreCompleted: (customerInfo) => _handleSuccess(customerInfo),
      onDismiss: () => Navigator.of(context).pop(),
      onPurchaseError: (PurchasesError error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      },
      onRestoreError: (PurchasesError error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${error.message}')),
        );
      },
    );
  }

  Widget _buildFallback() {
    return SafeArea(
      child: Column(
        children: [
          // Close button
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
                  // Icon
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
                  // Pricing coming soon notice
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
                          _offeringError != null
                              ? 'Could not connect to the store.\nCheck your connection and try again.'
                              : 'Pricing isn\'t set up yet. Check back soon\nor restore a previous purchase below.',
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
                  // Restore button
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
                                  color: AppTheme.cardFg.withValues(alpha: 0.75),
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
