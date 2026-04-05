import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/time_slot_picker.dart';
import '../widgets/tone_picker.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  const SettingsScreen({super.key, required this.profile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  final _nicknameController = TextEditingController();

  late double _morningHour;
  late double _afternoonHour;
  late double _eveningHour;
  late String _tone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final times = widget.profile.notificationTimes;
    _morningHour = storageToHour(times['morning'] ?? '08:00');
    _afternoonHour = storageToHour(times['afternoon'] ?? '13:00');
    _eveningHour = storageToHour(times['evening'] ?? '20:00');
    _tone = widget.profile.tonePreference;
    _nicknameController.text = widget.profile.nickname ?? '';
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    final raw = _nicknameController.text.trim();
    final updatedProfile = widget.profile.copyWith(
      nickname: raw.isEmpty ? null : raw,
      tonePreference: _tone,
      notificationTimes: {
        'morning': hourToStorage(_morningHour),
        'afternoon': hourToStorage(_afternoonHour),
        'evening': hourToStorage(_eveningHour),
      },
    );

    try {
      await _userService.saveProfile(updatedProfile);
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (!mounted) return;
    // Return the updated profile so HomeScreen can refresh its state.
    Navigator.of(context).pop(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppTheme.cardFg, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.cardFg,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Notification times ──────────────────────────────────────
            _SectionHeader(
              icon: Icons.notifications_none_outlined,
              label: 'Notification Times',
            ),
            const SizedBox(height: 12),
            TimeSlotPicker(
              icon: Icons.wb_sunny_outlined,
              label: 'Morning W',
              hour: _morningHour,
              min: 6.0, max: 10.0, divisions: 8,
              onChanged: (v) => setState(() => _morningHour = v),
            ),
            const SizedBox(height: 12),
            TimeSlotPicker(
              icon: Icons.bolt_outlined,
              label: 'Afternoon W',
              hour: _afternoonHour,
              min: 12.0, max: 15.0, divisions: 6,
              onChanged: (v) => setState(() => _afternoonHour = v),
            ),
            const SizedBox(height: 12),
            TimeSlotPicker(
              icon: Icons.nightlight_outlined,
              label: 'Evening W',
              hour: _eveningHour,
              min: 19.0, max: 22.0, divisions: 6,
              onChanged: (v) => setState(() => _eveningHour = v),
            ),

            const SizedBox(height: 32),

            // ── Tone preference ─────────────────────────────────────────
            _SectionHeader(
              icon: Icons.tune_outlined,
              label: 'Your Vibe',
            ),
            const SizedBox(height: 12),
            TonePicker(
              selected: _tone,
              onSelected: (t) => setState(() => _tone = t),
            ),

            const SizedBox(height: 32),

            // ── Nickname ────────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.person_outline,
              label: 'Nickname',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nicknameController,
              maxLength: 24,
              style: const TextStyle(color: AppTheme.cardFg, fontSize: 16),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Enter a nickname...',
                hintStyle: const TextStyle(color: AppTheme.mutedText),
                filled: true,
                fillColor: AppTheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: AppTheme.accent.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppTheme.accent, width: 1.5),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ── Save ────────────────────────────────────────────────────
            GradientButton(
              label: 'Save Changes',
              onTap: _save,
              trailingIcon: Icons.check,
              fullWidth: true,
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedText),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
