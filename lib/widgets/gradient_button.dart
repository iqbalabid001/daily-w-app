import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Full-width (or intrinsic-width) gradient action button used across
/// onboarding, settings, and any future screens.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? trailingIcon;
  final bool fullWidth;
  final bool isLoading;

  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.trailingIcon = Icons.arrow_forward,
    this.fullWidth = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFFFF6B8A)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisSize:
                    fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: fullWidth
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(trailingIcon, color: Colors.white, size: 16),
                  ],
                ],
              ),
      ),
    );
  }
}
