import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

/// RevenueCat Android public API key (production).
const kRevenueCatAndroidKey = 'goog_xhOrvsERwocvXcXwVezdRuSuXGf';

/// Entitlement identifier — must match the one created in the RevenueCat dashboard.
const kPremiumEntitlement = 'Daily W Pro';

// ── Service ───────────────────────────────────────────────────────────────────

class PurchaseService {
  static bool _initialized = false;

  // ── Initialization ──────────────────────────────────────────────────────────

  /// Call once in main(), after Firebase.initializeApp().
  /// Passing the Firebase Auth UID ties RevenueCat purchases to the account,
  /// so purchases persist across re-installs and device switches.
  static Future<void> initialize(String userId) async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.error);
    final config = PurchasesConfiguration(kRevenueCatAndroidKey)
      ..appUserID = userId;
    await Purchases.configure(config);
    _initialized = true;
  }

  // ── Paywall ─────────────────────────────────────────────────────────────────

  /// Presents the RevenueCat Paywall (configured in the dashboard) as a
  /// native full-screen activity on Android.
  /// Returns true if the user completed a purchase or restore; false otherwise.
  Future<bool> presentPaywall({Offering? offering}) async {
    try {
      final result = await RevenueCatUI.presentPaywall(
        offering: offering,
        displayCloseButton: true,
      );
      return result == PaywallResult.purchased ||
          result == PaywallResult.restored;
    } catch (_) {
      return false;
    }
  }

  /// Presents the paywall only if the user does NOT already have the premium
  /// entitlement. Returns true if a purchase/restore happened.
  Future<bool> presentPaywallIfNeeded() async {
    try {
      final result = await RevenueCatUI.presentPaywallIfNeeded(
        kPremiumEntitlement,
        displayCloseButton: true,
      );
      return result == PaywallResult.purchased ||
          result == PaywallResult.restored;
    } catch (_) {
      return false;
    }
  }

  // ── Customer Center ─────────────────────────────────────────────────────────

  /// Presents the RevenueCat Customer Center — lets users manage, cancel, or
  /// troubleshoot their subscriptions without leaving the app.
  Future<void> presentCustomerCenter() async {
    try {
      await RevenueCatUI.presentCustomerCenter();
    } catch (_) {
      // Customer Center is non-critical — swallow errors silently.
    }
  }

  // ── Entitlement checks ──────────────────────────────────────────────────────

  /// Returns true if the "Daily W Pro" entitlement is currently active.
  Future<bool> checkPremiumStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return _isPremiumActive(info);
    } catch (_) {
      return false;
    }
  }

  /// Returns the full CustomerInfo object, or null on error.
  Future<CustomerInfo?> getCustomerInfo() async {
    try {
      return await Purchases.getCustomerInfo();
    } catch (_) {
      return null;
    }
  }

  // ── Offerings ───────────────────────────────────────────────────────────────

  /// Returns the current RevenueCat offerings, or null on network/config error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  // ── Low-level purchase / restore ────────────────────────────────────────────

  /// Purchases a specific [package] directly (without the paywall UI).
  /// Returns true if the premium entitlement is now active.
  /// Returns false if the user cancelled.
  /// Throws [PurchasesError] for unexpected failures.
  Future<bool> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return _isPremiumActive(info);
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Restores previous purchases (user re-installed or switched devices).
  /// Returns true if the premium entitlement was restored.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return _isPremiumActive(info);
    } catch (_) {
      return false;
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  bool _isPremiumActive(CustomerInfo info) =>
      info.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
}
