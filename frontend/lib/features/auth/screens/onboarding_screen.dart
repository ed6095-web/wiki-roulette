import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/core_widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nameCtrl = TextEditingController(text: 'Explorer');
  final Set<String> _selectedInterests = {'History', 'Science', 'Technology'};

  static const List<(String, IconData)> _availableTopics = [
    ('History', Icons.history_edu_rounded),
    ('Science', Icons.biotech_rounded),
    ('Technology', Icons.memory_rounded),
    ('Space', Icons.rocket_launch_rounded),
    ('Geography', Icons.public_rounded),
    ('Arts & Culture', Icons.palette_rounded),
    ('Animals', Icons.pets_rounded),
    ('Architecture', Icons.apartment_rounded),
    ('Medicine', Icons.healing_rounded),
    ('Sports', Icons.sports_volleyball_rounded),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _onStart() {
    final name = _nameCtrl.text.trim().isEmpty ? 'Explorer' : _nameCtrl.text.trim();
    ref.read(profileProvider.notifier).setProfile(
          name: name,
          interests: _selectedInterests.toList(),
        );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AtmosphericBackground(
      glowColor: AppColors.accentGlow,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Brand Badge
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                                ),
                                child: const Icon(
                                  Icons.casino_rounded,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text('WIKI ROULETTE',
                                  style: AppTextStyles.overline(color: AppColors.accent)),
                            ],
                          ).animate().fadeIn(duration: 400.ms),

                          const SizedBox(height: 24),

                          // Hero text
                          Text('Welcome to\nWiki Roulette.', style: AppTextStyles.hero())
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 500.ms)
                              .slideY(begin: 0.1),

                          const SizedBox(height: 8),
                          Text(
                            "You don't choose what you learn. The internet does.",
                            style: AppTextStyles.body(color: AppColors.textSecondary),
                          ).animate().fadeIn(delay: 200.ms),

                          const SizedBox(height: 32),

                          // Name Input
                          Text('WHAT SHOULD WE CALL YOU?',
                              style: AppTextStyles.overline(color: AppColors.textMuted)),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameCtrl,
                            style: AppTextStyles.bodyMedium(),
                            decoration: InputDecoration(
                              hintText: 'Enter your name or handle',
                              prefixIcon:
                                  const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                            ),
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 32),

                          // Topics of interest
                          Text('PICK YOUR FAVORITE TOPICS',
                              style: AppTextStyles.overline(color: AppColors.textMuted)),
                          const SizedBox(height: 12),

                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _availableTopics.map((topic) {
                              final isSelected = _selectedInterests.contains(topic.$1);
                              return FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      topic.$2,
                                      size: 16,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(topic.$1),
                                  ],
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedInterests.add(topic.$1);
                                    } else {
                                      if (_selectedInterests.length > 1) {
                                        _selectedInterests.remove(topic.$1);
                                      }
                                    }
                                  });
                                },
                                backgroundColor: AppColors.cardSurface,
                                selectedColor: AppColors.accent,
                                labelStyle: AppTextStyles.label(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.accent : AppColors.glassBorder,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              );
                            }).toList(),
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _onStart,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('START EXPLORING', style: AppTextStyles.button()),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
