import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../models/user_profile.dart';
import '../services/purchase_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class PremiumScreen extends StatefulWidget {
  final UserProfile profile;
  const PremiumScreen({super.key, required this.profile});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  final _purchaseService = PurchaseService();
  final _userService = UserService();

  Offerings? _offerings;
  Package? _selectedPackage;
  bool _loadingOfferings = true;
  bool _purchasing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await _purchaseService.getOfferings();
    if (!mounted) return;
    setState(() {
      _offerings = offerings;
      _loadingOfferings = false;
      // Default to annual (best value)
      _selectedPackage = _annualPackage ?? _monthlyPackage;
    });
  }

  Package? get _monthlyPackage {
    if (_offerings?.current == null) return null;
    return _offerings!.current!.availablePackages.firstWhere(
      (p) => p.packageType == PackageType.monthly,
      orElse: () => _offerings!.current!.availablePackages.first,
    );
  }

  Package? get _annualPackage {
    if (_offerings?.current == null) return null;
    try {
      return _offerings!.current!.availablePackages.firstWhere(
        (p) => p.packageType == PackageType.annual,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _subscribe() async {
    if (_selectedPackage == null || _purchasing) return;
    setState(() { _purchasing = true; _error = null; });

    try {
      final isPremium =
          await _purchaseService.purchasePackage(_selectedPackage!);
      if (!mounted) return;

      if (isPremium) {
        final updated =
            await _userService.setPremium(widget.profile, true);
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        // User cancelled — no error shown, just close loading state
        setState(() => _purchasing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = 'Something went wrong. Please try again.';
        });
      }
    }
  }

  Future<void> _restore() async {
    setState(() { _purchasing = true; _error = null; });
    try {
      final isPremium = await _purchaseService.restorePurchases();
      if (!mounted) return;
      if (isPremium) {
        final updated =
            await _userService.setPremium(widget.profile, true);
        if (mounted) Navigator.of(context).pop(updated);
      } else {
        setState(() {
          _purchasing = false;
          _error = 'No previous purchase found.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _purchasing = false;
          _error = 'Restore failed. Check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.cardFg, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Hero ────────────────────────────────────────────────────
              const _HeroSection(),
              const SizedBox(height: 32),

              // ── Feature comparison ──────────────────────────────────────
              const _FeatureTable(),
              const SizedBox(height: 32),

              // ── Pricing options ─────────────────────────────────────────
              if (_loadingOfferings)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(
                        color: AppTheme.accent, strokeWidth: 2),
                  ),
                )
              else if (_offerings?.current == null)
                const _OfflineNotice()
              else ...[
                if (_annualPackage != null)
                  _PriceOption(
                    package: _annualPackage!,
                    isSelected: _selectedPackage == _annualPackage,
                    isBestValue: true,
                    onTap: () =>
                        setState(() => _selectedPackage = _annualPackage),
                  ),
                const SizedBox(height: 10),
                if (_monthlyPackage != null)
                  _PriceOption(
                    package: _monthlyPackage!,
                    isSelected: _selectedPackage == _monthlyPackage,
                    isBestValue: false,
                    onTap: () =>
                        setState(() => _selectedPackage = _monthlyPackage),
                  ),
              ],

              const SizedBox(height: 24),

              // ── Error ────────────────────────────────────────────────────
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFFF6B8A), fontSize: 13),
                  ),
                ),

              // ── CTA ──────────────────────────────────────────────────────
              _SubscribeButton(
                loading: _purchasing,
                enabled: _selectedPackage != null && !_purchasing,
                onTap: _subscribe,
              ),

              const SizedBox(height: 16),

              // ── Restore ───────────────────────────────────────────────────
              TextButton(
                onPressed: _purchasing ? null : _restore,
                child: Text(
                  'Restore Purchases',
                  style: TextStyle(
                    color: AppTheme.mutedText,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // ── Legal ─────────────────────────────────────────────────────
              const _LegalNote(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE94560), Color(0xFFFF6B8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('⚡', style: TextStyle(fontSize: 36)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Daily W Premium',
          style: TextStyle(
            color: AppTheme.cardFg,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Level up your daily W.',
          style: TextStyle(color: AppTheme.mutedText, fontSize: 15),
        ),
      ],
    );
  }
}

class _FeatureTable extends StatelessWidget {
  const _FeatureTable();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.accent.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: const [
          _FeatureRow(
            label: 'Morning W',
            freeValue: '✓',
            premiumValue: '✓',
          ),
          _FeatureDivider(),
          _FeatureRow(
            label: 'Afternoon + Evening W',
            freeValue: '–',
            premiumValue: '✓',
          ),
          _FeatureDivider(),
          _FeatureRow(
            label: 'History',
            freeValue: '3 days',
            premiumValue: 'Unlimited',
          ),
          _FeatureDivider(),
          _FeatureRow(
            label: 'Saved W\'s',
            freeValue: 'Limited',
            premiumValue: 'Unlimited',
          ),
          _FeatureDivider(),
          _FeatureRow(
            label: 'Humor Packs',
            freeValue: '–',
            premiumValue: 'Coming soon',
          ),
          _FeatureDivider(),
          _FeatureRow(
            label: 'Streak Gamification',
            freeValue: '–',
            premiumValue: '✓',
          ),
        ],
      ),
    );
  }
}

class _FeatureDivider extends StatelessWidget {
  const _FeatureDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 24,
      color: AppTheme.mutedText.withValues(alpha: 0.1),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String label;
  final String freeValue;
  final String premiumValue;

  const _FeatureRow({
    required this.label,
    required this.freeValue,
    required this.premiumValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.cardFg,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            freeValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: freeValue == '–'
                  ? AppTheme.mutedText
                  : AppTheme.mutedText,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            premiumValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: premiumValue == '–' || premiumValue == 'Coming soon'
                  ? AppTheme.mutedText
                  : AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PriceOption extends StatelessWidget {
  final Package package;
  final bool isSelected;
  final bool isBestValue;
  final VoidCallback onTap;

  const _PriceOption({
    required this.package,
    required this.isSelected,
    required this.isBestValue,
    required this.onTap,
  });

  String get _title =>
      package.packageType == PackageType.annual ? 'Annual' : 'Monthly';

  String get _price => package.storeProduct.priceString;

  String get _perMonth {
    if (package.packageType == PackageType.annual) {
      final yearly = package.storeProduct.price;
      final perMonth = yearly / 12;
      return '${_currencySymbol(package.storeProduct.currencyCode)}${perMonth.toStringAsFixed(2)}/mo';
    }
    return '${package.storeProduct.priceString}/mo';
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD': return r'$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      default: return '$code ';
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.accent
        : AppTheme.mutedText.withValues(alpha: 0.2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accent.withValues(alpha: 0.08)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.8 : 1),
        ),
        child: Row(
          children: [
            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.accent : AppTheme.mutedText,
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _title,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.cardFg
                              : AppTheme.mutedText,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (isBestValue) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: const Color(0xFFFFC107)
                                    .withValues(alpha: 0.4)),
                          ),
                          child: const Text(
                            'BEST VALUE',
                            style: TextStyle(
                              color: Color(0xFFFFC107),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _perMonth,
                    style: TextStyle(
                      color: AppTheme.mutedText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _price,
              style: TextStyle(
                color: isSelected ? AppTheme.accent : AppTheme.cardFg,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  final bool loading;
  final bool enabled;
  final VoidCallback onTap;

  const _SubscribeButton({
    required this.loading,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFE94560), Color(0xFFFF6B8A)],
                )
              : null,
          color: enabled ? null : AppTheme.mutedText.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Text(
                  'Subscribe',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_outlined,
              color: AppTheme.mutedText, size: 32),
          const SizedBox(height: 8),
          Text(
            'Could not load pricing.\nCheck your connection and try again.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LegalNote extends StatelessWidget {
  const _LegalNote();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Payment will be charged to your Google Play account. '
      'Subscription auto-renews unless cancelled at least 24 hours before the end of the current period.',
      textAlign: TextAlign.center,
      style: TextStyle(color: AppTheme.mutedText, fontSize: 11, height: 1.5),
    );
  }
}
