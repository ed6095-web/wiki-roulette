import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).profile;
    _nameCtrl = TextEditingController(text: profile.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _editNameDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: const Text(
          'Change Explorer Name',
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: _nameCtrl,
          autofocus: true,
          style: AppTextStyles.bodyMedium(),
          decoration: const InputDecoration(labelText: 'Your Name / Handle'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (_nameCtrl.text.trim().isNotEmpty) {
                final current = ref.read(profileProvider).profile;
                ref.read(profileProvider.notifier).setProfile(
                      name: _nameCtrl.text.trim(),
                      interests: current.interests,
                    );
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(profileProvider).profile;

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
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Profile Section
            Text('PROFILE', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _editNameDialog(context),
                    child: _SettingsRow(
                      icon: Icons.person_outline_rounded,
                      title: 'Explorer Name',
                      subtitle: user.name,
                      trailing: const Icon(Icons.edit_outlined,
                          color: AppColors.secondaryAccent, size: 18),
                    ),
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsRow(
                    icon: Icons.interests_outlined,
                    title: 'Favorite Topics',
                    subtitle: user.interests.join(', '),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Gameplay Settings
            Text('GAMEPLAY & FEEDBACK', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  _SettingsSwitchRow(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrations during roulette spins & answers',
                    value: true,
                    onChanged: (val) {},
                  ),
                  const Divider(color: AppColors.glassBorder),
                  _SettingsSwitchRow(
                    icon: Icons.volume_up_outlined,
                    title: 'Sound Cues',
                    subtitle: 'Audio effects for answers & unlocks',
                    value: true,
                    onChanged: (val) {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // About & Credits
            Text('ABOUT', style: AppTextStyles.overline(color: AppColors.accent)),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  const _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Wiki Roulette Version',
                    subtitle: '1.2.0 — Production Cloud Edition',
                  ),
                  const Divider(color: AppColors.glassBorder),
                  const _SettingsRow(
                    icon: Icons.menu_book_rounded,
                    title: 'Knowledge Provider',
                    subtitle: 'Wikipedia & Wikimedia Foundation (CC BY-SA 4.0)',
                  ),
                  const Divider(color: AppColors.glassBorder),
                  const _SettingsRow(
                    icon: Icons.cloud_done_outlined,
                    title: 'Backend Server',
                    subtitle: 'Live on Render Cloud & Supabase PostgreSQL',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Reset profile CTA
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.surfaceElevated,
                      title: const Text(
                        'Edit Topics & Name?',
                        style: TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary),
                      ),
                      content: const Text(
                        'You will be taken to the onboarding setup screen.',
                        style: TextStyle(
                            fontFamily: 'Poppins', color: AppColors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('CANCEL'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.go('/onboarding');
                          },
                          child: const Text('RECONFIGURE'),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accent, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  foregroundColor: AppColors.accent,
                ),
                child: const Text('RECONFIGURE PROFILE & TOPICS'),
              ),
            ),

            const SizedBox(height: 24),
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
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium()),
                Text(
                  subtitle,
                  style: AppTextStyles.metadata(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
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
