import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/daily_w_message.dart';
import 'models/user_profile.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/message_service.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final userService = UserService();
  final messageService = MessageService();

  // Auth + profile load happens before runApp — native splash covers this.
  final profile = await userService.signInAndLoad();

  // Pre-fetch today's message for returning users so HomeScreen shows instantly.
  DailyWMessage? message;
  if (profile.onboardingComplete) {
    message = await messageService
        .getTodaysMessage(MessageService.getCurrentSlot())
        .catchError((_) => null);
  }

  runApp(DailyWApp(profile: profile, initialMessage: message));
}

class DailyWApp extends StatelessWidget {
  final UserProfile profile;
  final DailyWMessage? initialMessage;

  const DailyWApp({
    super.key,
    required this.profile,
    this.initialMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily W',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: profile.onboardingComplete
          ? HomeScreen(initialProfile: profile, preloadedMessage: initialMessage)
          : OnboardingScreen(profile: profile),
    );
  }
}
