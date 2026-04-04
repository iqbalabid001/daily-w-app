import 'package:flutter/material.dart';

/// Minimal onboarding: notification time + optional tone + optional nickname.
/// Max 3 steps, then immediately shows the first Daily W.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Onboarding — coming soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
