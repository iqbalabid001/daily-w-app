import 'package:flutter/material.dart';
import '../models/daily_w_message.dart';
import '../models/user_profile.dart';
import '../services/message_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
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

  // Step 1 — notification times (stored as hours, e.g. 8.0 = 8:00)
  double _morningHour = 8.0;    // range 6–10
  double _afternoonHour = 13.0; // range 12–15
  double _eveningHour = 20.0;   // range 19–22

  // Step 2 — tone
  String _tone = 'sarcastic';

  // Pre-fetched message (starts loading when user reaches step 3)
  Future<DailyWMessage?>? _messageFuture;

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep == 1) {
      // Start fetching message in background as user enters step 3
      _messageFuture = MessageService()
          .getTodaysMessage(MessageService.getCurrentSlot())
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
    final nickname =
        skip ? null : _nicknameController.text.trim().isEmpty
            ? null
            : _nicknameController.text.trim();

    // Build updated profile with all onboarding answers
    final updatedProfile = widget.profile.copyWith(
      nickname: nickname,
      tonePreference: _tone,
      onboardingComplete: true,
      notificationTimes: {
        'morning': _hourToStorage(_morningHour),
        'afternoon': _hourToStorage(_afternoonHour),
        'evening': _hourToStorage(_eveningHour),
      },
    );

    // Save to Firestore (fire and forget — don't block navigation)
    _userService.saveProfile(updatedProfile);

    // Await the pre-fetched message (likely already done by now)
    final message = await (_messageFuture ??
        MessageService().getTodaysMessage(MessageService.getCurrentSlot()));

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
                  _StepNotificationTimes(
                    morningHour: _morningHour,
                    afternoonHour: _afternoonHour,
                    eveningHour: _eveningHour,
                    onMorningChanged: (v) => setState(() => _morningHour = v),
                    onAfternoonChanged: (v) =>
                        setState(() => _afternoonHour = v),
                    onEveningChanged: (v) => setState(() => _eveningHour = v),
                    onNext: _goNext,
                  ),
                  _StepToneSelection(
                    selected: _tone,
                    onSelected: (t) => setState(() => _tone = t),
                    onBack: _goBack,
                    onNext: _goNext,
                  ),
                  _StepNickname(
                    controller: _nicknameController,
                    onBack: _goBack,
                    onFinish: () => _finish(),
                    onSkip: () => _finish(skip: true),
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
            color: active ? AppTheme.accent : AppTheme.mutedText.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── Step 1 — Notification times ───────────────────────────────────────────────

class _StepNotificationTimes extends StatelessWidget {
  final double morningHour, afternoonHour, eveningHour;
  final ValueChanged<double> onMorningChanged, onAfternoonChanged,
      onEveningChanged;
  final VoidCallback onNext;

  const _StepNotificationTimes({
    required this.morningHour,
    required this.afternoonHour,
    required this.eveningHour,
    required this.onMorningChanged,
    required this.onAfternoonChanged,
    required this.onEveningChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      headline: 'When do you want\nyour W?',
      subhead: "We'll remind you. You'll probably ignore it.\nWe'll both know.",
      onNext: onNext,
      nextLabel: 'Next',
      child: Column(
        children: [
          _TimeSlider(
            icon: Icons.wb_sunny_outlined,
            label: 'Morning W',
            hour: morningHour,
            min: 6.0,
            max: 10.0,
            divisions: 8,
            onChanged: onMorningChanged,
          ),
          const SizedBox(height: 20),
          _TimeSlider(
            icon: Icons.bolt_outlined,
            label: 'Afternoon W',
            hour: afternoonHour,
            min: 12.0,
            max: 15.0,
            divisions: 6,
            onChanged: onAfternoonChanged,
          ),
          const SizedBox(height: 20),
          _TimeSlider(
            icon: Icons.nightlight_outlined,
            label: 'Evening W',
            hour: eveningHour,
            min: 19.0,
            max: 22.0,
            divisions: 6,
            onChanged: onEveningChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final double hour, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _TimeSlider({
    required this.icon,
    required this.label,
    required this.hour,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.accent),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: AppTheme.cardFg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                _hourToDisplay(hour),
                style: const TextStyle(
                  color: AppTheme.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.accent,
              inactiveTrackColor: AppTheme.accent.withValues(alpha: 0.18),
              thumbColor: AppTheme.accent,
              overlayColor: AppTheme.accent.withValues(alpha: 0.12),
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: hour,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2 — Tone selection ───────────────────────────────────────────────────

class _StepToneSelection extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onBack, onNext;

  const _StepToneSelection({
    required this.selected,
    required this.onSelected,
    required this.onBack,
    required this.onNext,
  });

  static const _tones = [
    (
      value: 'sarcastic',
      label: 'Sarcastic & Witty',
      description: 'Dry humor, reverse psychology,\nplayful jabs',
      icon: Icons.sentiment_very_satisfied_outlined,
    ),
    (
      value: 'tough_love',
      label: 'Tough Love',
      description: 'Direct, no-nonsense,\nchallenges your excuses',
      icon: Icons.fitness_center_outlined,
    ),
    (
      value: 'chill',
      label: 'Chill & Calm',
      description: 'Gentle nudges, quiet confidence,\nlow pressure',
      icon: Icons.self_improvement_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      headline: 'Pick your vibe.',
      subhead: "We'll match your energy. Mostly.",
      onNext: onNext,
      onBack: onBack,
      nextLabel: 'Next',
      child: Column(
        children: _tones.map((t) {
          final isSelected = t.value == selected;
          return GestureDetector(
            onTap: () => onSelected(t.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.accent.withValues(alpha: 0.15)
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accent
                      : AppTheme.accent.withValues(alpha: 0.15),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(t.icon,
                      color:
                          isSelected ? AppTheme.accent : AppTheme.mutedText,
                      size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.label,
                          style: TextStyle(
                            color: isSelected
                                ? AppTheme.cardFg
                                : AppTheme.cardFg,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.description,
                          style: const TextStyle(
                            color: AppTheme.mutedText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle,
                        color: AppTheme.accent, size: 20),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Step 3 — Nickname ─────────────────────────────────────────────────────────

class _StepNickname extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onBack, onFinish, onSkip;

  const _StepNickname({
    required this.controller,
    required this.onBack,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      headline: 'What should we\ncall you?',
      subhead: "Totally optional. We'll call you 'champ' otherwise.",
      onNext: onFinish,
      onBack: onBack,
      nextLabel: 'Start my Daily W',
      extraAction: TextButton(
        onPressed: onSkip,
        child: const Text(
          'Skip',
          style: TextStyle(color: AppTheme.mutedText, fontSize: 15),
        ),
      ),
      child: TextField(
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
            borderSide:
                const BorderSide(color: AppTheme.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── Shared shell ──────────────────────────────────────────────────────────────

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
          // Bottom action row
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
              _NextButton(label: nextLabel, onTap: onNext),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NextButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Time helpers (shared) ─────────────────────────────────────────────────────

String _hourToDisplay(double hour) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  final period = h < 12 ? 'AM' : 'PM';
  final displayH = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$displayH:${m.toString().padLeft(2, '0')} $period';
}

String _hourToStorage(double hour) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}
