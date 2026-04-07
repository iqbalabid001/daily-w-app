import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../models/user_profile.dart';
import '../services/purchase_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

/// Full-screen paywall powered by the RevenueCat Paywall UI.
///
/// The visual design, pricing tiers ($2.99/mo · $19.99/yr · $49.99 lifetime),
/// and feature copy are configured in the RevenueCat dashboard under Paywalls.
/// This screen is the Flutter host that handles the purchase lifecycle.
///
/// Returns an updated [UserProfile] (isPremium = true) via [Navigator.pop]
/// on successful purchase or restore. Returns null on dismiss.
class PremiumScreen extends StatefulWidget {
  final UserProfile profile;
  const PremiumScreen({super.key, required this.profile});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _userService = UserService();
  bool _processing = false;

  /// Called after a successful purchase or restore from the paywall.
  /// Verifies the entitlement is active, writes isPremium to Firestore,
  /// then pops with the updated profile so HomeScreen updates instantly.
  Future<void> _handleSuccess(CustomerInfo customerInfo) async {
    final isActive =
        customerInfo.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
    if (!isActive || !mounted) return;

    setState(() => _processing = true);
    try {
      final updated = await _userService.setPremium(widget.profile, true);
      if (mounted) Navigator.of(context).pop(updated);
    } catch (_) {
      // Firestore write failed — purchase still succeeded. Show guidance.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      // PaywallView renders the RevenueCat-configured paywall UI natively.
      // Sizing, pricing, and copy are all managed from the RevenueCat dashboard.
      body: Stack(
        children: [
          PaywallView(
            displayCloseButton: true,
            onPurchaseCompleted: (customerInfo, transaction) =>
                _handleSuccess(customerInfo),
            onRestoreCompleted: (customerInfo) =>
                _handleSuccess(customerInfo),
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
                SnackBar(
                  content: Text('Restore failed: ${error.message}'),
                ),
              );
            },
          ),
          // Processing overlay — shown while writing isPremium to Firestore.
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
}
