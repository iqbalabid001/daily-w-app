import 'package:flutter/material.dart';

/// The single main screen of the app.
/// Shows the current Daily W message card and nav icons.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Daily W — coming soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
