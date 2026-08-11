import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return AtmosphericBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Account section
            Text('ACCOUNT', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.person_outline,
                    title: 'Username',
                    subtitle: user?.username ?? 'Explorer',
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsRow(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: user?.email ?? '',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Gameplay settings
            Text('GAMEPLAY', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _SettingsSwitchRow(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrations during roulette and answers',
                    value: true,
                    onChanged: (val) {},
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsSwitchRow(
                    icon: Icons.volume_up_outlined,
                    title: 'Sound Effects',
                    subtitle: 'Play audio cues for correct/wrong answers',
                    value: true,
                    onChanged: (val) {},
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsRow(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    subtitle: 'English (en)',
                    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // About & Credits
            Text('ABOUT', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 12),
            GlassCard(
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.info_outline,
                    title: 'Version',
                    subtitle: '1.0.0 (Build 1)',
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsRow(
                    icon: Icons.menu_book_outlined,
                    title: 'Content Source',
                    subtitle: 'Wikipedia & Wikimedia Foundation (CC BY-SA 4.0)',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: AppColors.error,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text('LOG OUT', style: AppTextStyles.button(color: AppColors.error)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium()),
                Text(subtitle, style: AppTextStyles.metadata()),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium()),
                Text(subtitle, style: AppTextStyles.metadata()),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
