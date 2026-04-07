import 'package:purchases_flutter/purchases_flutter.dart';

/// Replace this with your actual RevenueCat Android public API key.
/// Find it in the RevenueCat dashboard → Project Settings → API Keys.
const _kRevenueCatAndroidKey = 'YOUR_REVENUECAT_ANDROID_API_KEY';

/// Firestore entitlement ID — must match what you create in RevenueCat dashboard.
const kPremiumEntitlement = 'premium';

class PurchaseService {
  static bool _initialized = false;

  /// Call once in main(), after Firebase.initializeApp().
  /// Pass the Firebase Auth UID so RevenueCat ties purchases to the account.
  static Future<void> initialize(String userId) async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.error);
    final config = PurchasesConfiguration(_kRevenueCatAndroidKey)
      ..appUserID = userId;
    await Purchases.configure(config);
    _initialized = true;
  }

  /// Returns the current RevenueCat offerings, or null on error.
  Future<Offerings?> getOfferings() async {
    try {
      return await Purchases.getOfferings();
    } catch (_) {
      return null;
    }
  }

  /// Attempts to purchase [package].
  /// Returns true if the premium entitlement is now active, false on cancel.
  /// Throws on unexpected errors so the UI can show an error message.
  Future<bool> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      return info.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  /// Restores previous purchases.
  /// Returns true if the premium entitlement is now active.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Checks the current customer's premium status without making a purchase.
  Future<bool> checkPremiumStatus() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[kPremiumEntitlement]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }
}
