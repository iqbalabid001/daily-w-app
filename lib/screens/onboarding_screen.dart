import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';
import '../models/user_profile.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/time_slot_picker.dart';
import '../widgets/tone_picker.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final UserProfile profile;
  const OnboardingScreen({super.key, required this.profile});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _userService = UserService();
  final _nicknameController = TextEditingController();

  int _currentStep = 0;

  double _morningHour = 8.0;    // 6–10
  double _afternoonHour = 13.0; // 12–15
  double _eveningHour = 20.0;   // 19–22
  String _tone = 'sarcastic';

  Future<DailyWMessage?>? _messageFuture;

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep == 1) {
      // Start fetching message in background so step 3 has it ready.
      _messageFuture = MessageService()
          .getOrAssignTodaysMessage(MessageService.getCurrentSlot(), widget.profile.uid)
          .catchError((_) => null);
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep++);
  }

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
    setState(() => _currentStep--);
  }

  Future<void> _finish({bool skip = false}) async {
    final raw = _nicknameController.text.trim();
    final nickname = (skip || raw.isEmpty) ? null : raw;

    final updatedProfile = widget.profile.copyWith(
      nickname: nickname,
      tonePreference: _tone,
      onboardingComplete: true,
      notificationTimes: {
        'morning': hourToStorage(_morningHour),
        'afternoon': hourToStorage(_afternoonHour),
        'evening': hourToStorage(_eveningHour),
      },
    );

    _userService.saveProfile(updatedProfile); // fire-and-forget

    final message = await (_messageFuture ??
        MessageService().getOrAssignTodaysMessage(MessageService.getCurrentSlot(), widget.profile.uid));

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(
          initialProfile: updatedProfile,
          preloadedMessage: message,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _StepIndicator(currentStep: _currentStep),
            const SizedBox(height: 8),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _StepShell(
                    headline: 'When do you want\nyour W?',
                    subhead:
                        "We'll remind you. You'll probably ignore it.\nWe'll both know.",
                    onNext: _goNext,
                    nextLabel: 'Next',
                    child: Column(
                      children: [
                        TimeSlotPicker(
                          icon: Icons.wb_sunny_outlined,
                          label: 'Morning W',
                          hour: _morningHour,
                          min: 6.0, max: 10.0, divisions: 8,
                          onChanged: (v) =>
                              setState(() => _morningHour = v),
                        ),
                        const SizedBox(height: 20),
                        TimeSlotPicker(
                          icon: Icons.bolt_outlined,
                          label: 'Afternoon W',
                          hour: _afternoonHour,
                          min: 12.0, max: 15.0, divisions: 6,
                          onChanged: (v) =>
                              setState(() => _afternoonHour = v),
                        ),
                        const SizedBox(height: 20),
                        TimeSlotPicker(
                          icon: Icons.nightlight_outlined,
                          label: 'Evening W',
                          hour: _eveningHour,
                          min: 19.0, max: 22.0, divisions: 6,
                          onChanged: (v) =>
                              setState(() => _eveningHour = v),
                        ),
                      ],
                    ),
                  ),
                  _StepShell(
                    headline: 'Pick your vibe.',
                    subhead: "We'll match your energy. Mostly.",
                    onNext: _goNext,
                    onBack: _goBack,
                    nextLabel: 'Next',
                    child: TonePicker(
                      selected: _tone,
                      onSelected: (t) => setState(() => _tone = t),
                    ),
                  ),
                  _StepShell(
                    headline: 'What should we\ncall you?',
                    subhead:
                        "Totally optional. We'll call you 'champ' otherwise.",
                    onNext: () => _finish(),
                    onBack: _goBack,
                    nextLabel: 'Start my Daily W',
                    extraAction: TextButton(
                      onPressed: () => _finish(skip: true),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                            color: AppTheme.mutedText, fontSize: 15),
                      ),
                    ),
                    child: _NicknameField(controller: _nicknameController),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final active = i == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.accent
                : AppTheme.mutedText.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Nickname field ────────────────────────────────────────────────────────────

class _NicknameField extends StatelessWidget {
  final TextEditingController controller;
  const _NicknameField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      maxLength: 24,
      style: const TextStyle(color: AppTheme.cardFg, fontSize: 16),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter a nickname...',
        hintStyle: const TextStyle(color: AppTheme.mutedText),
        filled: true,
        fillColor: AppTheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.accent.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppTheme.accent.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}

// ── Shared step shell ─────────────────────────────────────────────────────────

class _StepShell extends StatelessWidget {
  final String headline;
  final String subhead;
  final Widget child;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final String nextLabel;
  final Widget? extraAction;

  const _StepShell({
    required this.headline,
    required this.subhead,
    required this.child,
    required this.onNext,
    required this.nextLabel,
    this.onBack,
    this.extraAction,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            headline,
            style: const TextStyle(
              color: AppTheme.cardFg,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subhead,
            style: const TextStyle(
              color: AppTheme.mutedText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          child,
          const SizedBox(height: 40),
          Row(
            children: [
              if (onBack != null) ...[
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new,
                      color: AppTheme.mutedText, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    padding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (extraAction != null) ...[
                extraAction!,
                const Spacer(),
              ] else
                const Spacer(),
              GradientButton(label: nextLabel, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}
